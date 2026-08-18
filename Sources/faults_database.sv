module faults_database
  #(
    parameter int fault_count = 16,  //Number of faults in database
    parameter int random_seed = 42,  //Seed for random number generation
    parameter int disturb_count = 4, //GOTO: fault_model
    parameter int couple_count = 16, //GOTO: fault_model
    parameter int watch_depth = 8,   //GOTO: address_watcher
    parameter int addrW = 8,
    parameter int dataW = 32
  ) (
    input  logic clk,
    input  logic nres,
    //Memory Port
    input  logic             cs_n,
    input  logic [addrW-1:0] addr,
    input  logic             we_n,
    input  logic [dataW-1:0] bwe_n,
    input  logic [dataW-1:0] din,
    input  logic             re_n,
    //Fault Injection
    output logic [dataW-1:0] fault_w,
    output logic [dataW-1:0] fault_r
  );

    // Additional Parameter Gen
    localparam int depthW = $clog2(watch_depth);         //GOTO: address_watcher
    localparam int primitiveW = 2*watch_depth+depthW+20; //GOTO: fault_model
    localparam int dataAddrW = addrW + $clog2(dataW);    //GOTO: fault_model
    localparam int disturbW = primitiveW-20+dataAddrW;   //GOTO: fault_model

    // Random Values for Fault Coding
    logic [primitiveW-1:0] do_advanced_faults[fault_count-1:0];
    logic [primitiveW-1:0] fault_primitive_list[fault_count-1:0];
    logic [dataAddrW-1:0] fault_addr_list[fault_count-1:0];
    logic [disturb_count*disturbW-1:0] disturb_primitives_list[fault_count-1:0];
    integer i,ii;
    integer seed;
    initial begin
        seed = random_seed;
        for (i = 0; i < fault_count; i = i + 1) begin
            do_advanced_faults[i] = {$random(seed), $random(seed)};

            for (ii = 0; ii < disturb_count; ii = ii + 1) begin
              if (do_advanced_faults[i][0] && do_advanced_faults[i][4] && do_advanced_faults[i][ii+5]) begin
                disturb_primitives_list[i][ii*disturbW +: disturbW] = {$random(seed), $random(seed)};
              end else begin
                disturb_primitives_list[i][ii*disturbW +: disturbW] = '0;
                do_advanced_faults[i][ii+6] = 1'b0;
              end
            end

            if (do_advanced_faults[i][0]) begin
              do_advanced_faults[i] = 28'h00FFFFF;
            end else if (do_advanced_faults[i][1]) begin
              do_advanced_faults[i] = 28'h1FFFFFF;
            end else if (do_advanced_faults[i][2]) begin
              do_advanced_faults[i] = 28'h7FFFFFF;
            end else begin
              do_advanced_faults[i] = '1;
            end
            fault_primitive_list[i] = {$random(seed), $random(seed)} & do_advanced_faults[i];
            fault_addr_list[i] = $random(seed);
        end
    end

    // Fault Model Instances
    logic     [dataW-1:0] fault_w_list[fault_count-1:0];
    logic     [dataW-1:0] fault_r_list[fault_count-1:0];
    genvar x;
    generate
        for (x = 0; x < fault_count; x = x + 1) begin
            fault_model #(
            .disturb_count(disturb_count),
            .couple_count(couple_count),
            .watch_depth(watch_depth),
            .depthW(depthW),
            .primitiveW(primitiveW),
            .dataAddrW(dataAddrW),
            .disturbW(disturbW),
            .addrW(addrW),
            .dataW(dataW)
            ) FM (
            .clk(clk),
            .nres(nres),
            //Memory Port
            .cs_n(cs_n),
            .addr(addr),
            .we_n(we_n),
            .bwe_n(bwe_n),
            .din(din),
            .re_n(re_n),
            //Fault Coding
            .fault_primitive(fault_primitive_list[x]),
            .fault_addr(fault_addr_list[x]),
            .disturb_primitives(disturb_primitives_list[x]),
            //Fault Injection
            .fault_w(fault_w_list[x]),
            .fault_r(fault_r_list[x])
            );
        end
    endgenerate

    // Fault Mapper (bitwise OR-sum)
    integer j;
    always @(*) begin
        fault_w = {dataW{1'b0}};
        fault_r = {dataW{1'b0}};
        for (j = 0; j < fault_count; j = j + 1) begin
            fault_w = fault_w | fault_w_list[j];
            fault_r = fault_r | fault_r_list[j];
        end
    end

endmodule



module fault_model
  #(
    parameter int disturb_count = 4, //Number of disturb aggressor addresses to watch
    parameter int couple_count = 16, //Number of static aggressor addresses to be tracked
    parameter int watch_depth = 8,   //GOTO:address_watcher
    parameter int depthW = 3,        //GOTO:address_watcher
    parameter int primitiveW = 39,   //Width of the fault primitive with all its arguments
    parameter int dataAddrW = 13,    //Address width including the bits to specify a single bit in the data word (addrW + log2(dataW))
    parameter int disturbW = 32,     //Width of the disturb primitives
    parameter int addrW = 8,
    parameter int dataW = 32
  ) (
    input  logic clk,
    input  logic nres,
    //Memory Port
    input  logic             cs_n,
    input  logic [addrW-1:0] addr,
    input  logic             we_n,
    input  logic [dataW-1:0] bwe_n,
    input  logic [dataW-1:0] din,
    input  logic             re_n,
    //Fault Coding
    input  logic [primitiveW-1:0] fault_primitive,
    input  logic [dataAddrW-1:0] fault_addr,
    input  logic [disturb_count*disturbW-1:0] disturb_primitives,
    //Fault Injection
    output logic [dataW-1:0] fault_w,
    output logic [dataW-1:0] fault_r
  );

    //Registers
    reg cell_reg;
    reg cell_flip;
    reg fault_read_d;
    reg [15:0] rand_cnt;
    reg [15:0] rand_shf;

    //Wires
    logic [(dataAddrW-addrW)-1:0] fault_dataAddr;
    logic [dataW-1:0] fault_bitmask;
    logic fault_din;

    logic fault_access;
    logic fault_write;
    logic fault_read;

    logic fault_init;
    logic [2:0] fault_action;
    logic fault_active;

    logic [15:0] fault_nonce;
    logic [depthW-1:0] fault_access_cnt;
    logic [2*watch_depth-1:0] fault_access_pattern;
    
    logic overwrite_w;
    logic overwrite_r;
    logic flip_on_read;
    logic do_rand_cnt;
    logic do_rand_shf;

    logic fault_watch_trigger;
    logic [disturb_count-1:0] disturb_watch_triggers;
    logic all_watch_trigger;

    //Assigns
    assign fault_dataAddr = fault_addr[dataAddrW-1:addrW];
    assign fault_bitmask = 1 << fault_dataAddr;
    assign fault_din = din[fault_dataAddr];
    
    assign fault_access = (addr == fault_addr[addrW-1:0]) && !cs_n && !bwe_n[fault_dataAddr]; //byte write feature used as bit select
    assign fault_write = fault_access && !we_n; // && !bwe_n[fault_dataAddr];
    assign fault_read = fault_access && !re_n;

    assign fault_init = fault_primitive[0];
    assign fault_action = fault_primitive[3:1];

    assign all_watch_trigger = fault_watch_trigger ? &disturb_watch_triggers : 1'b0;
    assign fault_active = (cell_reg == fault_primitive[4]) && all_watch_trigger;

    assign fault_nonce = (fault_primitive[19:4] < 16'h0002) ? 16'h0002 : fault_primitive[19:4];
    assign fault_access_cnt = fault_primitive[depthW+19:20];
    assign fault_access_pattern = fault_primitive[2*watch_depth+depthW+19:depthW+20];

    assign do_rand_cnt = fault_action == 3'b001;
    assign flip_on_read = (fault_action == 3'b100) || (fault_action == 3'b101);
    assign do_rand_shf = fault_action == 3'b111;

    assign fault_w = fault_write && overwrite_w ? fault_bitmask : '0;
    assign fault_r = fault_read_d && overwrite_r ? fault_bitmask : '0;

    //Instances
    address_watcher #(
      .watch_depth(watch_depth),
      .depthW(depthW),
      .dataAddrW(dataAddrW),
      .addrW(addrW),
      .dataW(dataW)
    ) FW (
      .clk(clk),
      .nres(nres),
      //Memory Port
      .cs_n(cs_n),
      .addr(addr),
      .we_n(we_n),
      .bwe_n(bwe_n),
      .din(din),
      .re_n(re_n),
      //Fault Coding
      .cell_addr(fault_addr),
      .access_cnt(fault_access_cnt),
      .pattern(fault_access_pattern),
      //Fault Injection
      .watch_trigger(fault_watch_trigger)
    );

    genvar x;
    generate
      for (x = 0; x < disturb_count; x = x + 1) begin
        address_watcher #(
          .watch_depth(watch_depth),
          .depthW(depthW),
          .dataAddrW(dataAddrW),
          .addrW(addrW),
          .dataW(dataW)
        ) FD (
          .clk(clk),
          .nres(nres),
          //Memory Port
          .cs_n(cs_n),
          .addr(addr),
          .we_n(we_n),
          .bwe_n(bwe_n),
          .din(din),
          .re_n(re_n),
          //Fault Coding
          .cell_addr(disturb_primitives[x*disturbW+dataAddrW-1:x*disturbW+0]),
          .access_cnt(disturb_primitives[x*disturbW+dataAddrW+depthW-1:x*disturbW+dataAddrW]),
          .pattern(disturb_primitives[(x+1)*disturbW-1:x*disturbW+dataAddrW+depthW]),
          //Fault Injection
          .watch_trigger(disturb_watch_triggers[x])
        );
      end
    endgenerate

    // Processes
  //------------------------------- Sequential ------------------------------
    // Registers for Fault Actions
    always @(posedge clk or negedge nres) begin
      if (nres == 0) begin
        fault_read_d <= 1'b0;
        cell_reg <= (fault_action == 3'b000) ? fault_primitive[4] : fault_init;
        cell_flip <= 1'b0;
        rand_cnt <= 16'h0000;
        rand_shf <= fault_nonce;
      end else begin
        fault_read_d <= fault_read;

        // Cell Register Updates
        if (fault_write) begin
          cell_reg <= overwrite_w ? ~fault_din : fault_din;
          cell_flip <= 1'b0;
        end else if (flip_on_read && fault_read_d && fault_active) begin
          cell_reg <= ~cell_reg;
          cell_flip <= 1'b1;
        end else if (do_rand_cnt && rand_cnt == 16'h0001) begin
          cell_reg <= ~cell_reg;
          cell_flip <= 1'b1;
        end

        // Random Counter for Retention Fault
        if (do_rand_cnt) begin
          if (fault_write && fault_active) begin
            rand_cnt <= fault_nonce;
          end else if (rand_cnt != 16'h0000) begin
            rand_cnt <= rand_cnt - 1;
          end
        end
        
        // Random Shift Register for Random Read Fault
        if (fault_access && do_rand_shf) begin
          rand_shf <= {rand_shf[14:0], rand_shf[15] ^ rand_shf[14]};
        end
      end
    end

  //------------------------------ Combinational ----------------------------

    // Fault Primitive Action Decoder
    always_comb begin
      case (fault_action)

        3'b000: begin // Stuck At Fault
          overwrite_w = (fault_din != cell_reg) && fault_active;
          overwrite_r = 1'b0;
        end

        3'b001: begin // Data Retention Fault
          overwrite_w = 1'b0;
          overwrite_r = cell_flip;
        end

        3'b010: begin // Transition Fault
          overwrite_w = (fault_din != cell_reg) && fault_active;
          overwrite_r = 1'b0;
        end

        3'b011: begin // Write Disturb Fault
          overwrite_w = (fault_din == cell_reg) && fault_active;
          overwrite_r = 1'b0;
        end

        3'b100: begin // Read Destructive Fault
          overwrite_w = 1'b0;
          overwrite_r = fault_active || cell_flip;
        end

        3'b101: begin // Deceptive Read Destructive Fault
          overwrite_w = 1'b0;
          overwrite_r = cell_flip;
        end

        3'b110: begin // Incorrect Read Fault
          overwrite_w = 1'b0;
          overwrite_r = fault_active;
        end

        3'b111: begin // Random Read Fault
          overwrite_w = 1'b0;
          overwrite_r = fault_active && rand_shf[0];
        end

      endcase
    end

endmodule



module address_watcher
  #(
    parameter int watch_depth = 8,   //Number of registered accesses per watched address
    parameter int depthW = 3,        //Width of the access counter (log2(watch_depth))
    parameter int dataAddrW = 13,
    parameter int addrW = 8,
    parameter int dataW = 32
  ) (
    input  logic clk,
    input  logic nres,
    //Memory Port
    input  logic             cs_n,
    input  logic [addrW-1:0] addr,
    input  logic             we_n,
    input  logic [dataW-1:0] bwe_n,
    input  logic [dataW-1:0] din,
    input  logic             re_n,
    //Fault Coding
    input  logic     [dataAddrW-1:0] cell_addr,
    input  logic        [depthW-1:0] access_cnt,
    input  logic [2*watch_depth-1:0] pattern,
    //Activation Output
    output logic watch_trigger
  );
  
    //Registers

    reg [2*watch_depth-1:0] cell_access_watch;
    reg [depthW-1:0] nres_access_cnt;

    //Wires
    logic [(dataAddrW-addrW)-1:0] cell_dataAddr;
    logic [dataW-1:0] cell_bitmask;
    logic cell_din;

    logic cell_access;
    logic cell_write;
    logic cell_read;
    logic [1:0] cell_access_code;
    logic [2*watch_depth-1:0] access_pattern;

    logic [2*watch_depth-1:0] access_bitmask;
    logic access_match;

    //Assigns
    assign cell_dataAddr = cell_addr[dataAddrW-1:addrW];
    assign cell_bitmask = 1 << cell_dataAddr;
    assign cell_din = din[cell_dataAddr];
    
    assign cell_access = (addr == cell_addr[addrW-1:0]) && !cs_n && !bwe_n[cell_dataAddr]; //byte write feature used as bit select
    assign cell_write = cell_access && !we_n; // && !bwe_n[cell_dataAddr];
    assign cell_read = cell_access && !re_n;
    assign cell_access_code = cell_write ? {1'b1, cell_din} : 2'b00;

    genvar x;
    generate
      for (x = 0; x < watch_depth; x = x + 1) begin
        assign access_pattern[x*2+1:x*2+0] = pattern[x*2+1] ? {1'b1, pattern[x*2+0]} : 2'b00;
      end
    endgenerate

    assign access_bitmask = ~('1 << (access_cnt*2));
    assign access_match = (nres_access_cnt == 0) ? (cell_access_watch & access_bitmask) == (pattern & access_bitmask) : 1'b0;
    assign watch_trigger = (access_cnt > 0) ? access_match : 1'b1;

    //Instances

    // Processes
  //------------------------------- Sequential ------------------------------

    // Register for Fault Access Watch, only active after the minimum number of accesses has been reached after reset
    always @(posedge clk or negedge nres) begin
      if (nres == 0) begin
        cell_access_watch <= '0;
        nres_access_cnt <= access_cnt;
      end else begin
        if (cell_access) begin
          cell_access_watch <= {cell_access_watch[2*watch_depth-3:0], cell_access_code};

          if (nres_access_cnt != 0) begin
            nres_access_cnt <= nres_access_cnt - 1;
          end
        end
      end
    end

  //------------------------------ Combinational ----------------------------

endmodule