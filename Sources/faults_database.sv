module faults_database
  #(
    parameter int fault_count = 16,  //Number of faults in database
    parameter int random_seed = 42,  //Seed for random number generation
    parameter int disturb_count = 4, //GOTO: fault_model
    parameter int static_count = 16, //GOTO: fault_model
    parameter int watch_depth = 8,   //GOTO: fault_model
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
    localparam int dataAddrW = addrW + $clog2(dataW); //GOTO: fault_model

    // Random Values for Fault Coding
    logic           [0:0] fault_primitive_list[fault_count-1:0];
    logic [dataAddrW-1:0] fault_addr_list[fault_count-1:0];
    integer i;
    integer seed;
    initial begin
        seed = random_seed;
        for (i = 0; i < fault_count; i = i + 1) begin
            fault_primitive_list[i] = $random(seed);
            fault_addr_list[i]      = $random(seed);
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
            .static_count(static_count),
            .watch_depth(watch_depth),
            .dataAddrW(dataAddrW),
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
    parameter int static_count = 16, //Number of static aggressor addresses to be tracked
    parameter int watch_depth = 8,   //Number of registered accesses per watched address
    parameter int dataAddrW = 13,    //Address width including the bits to specify a single bit in the data word (addrW + log2(dataW))
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
    input  logic                 fault_primitive,
    input  logic [dataAddrW-1:0] fault_addr,
    //Fault Injection
    output logic [dataW-1:0] fault_w,
    output logic [dataW-1:0] fault_r
  );

    //Registers
    reg fault_reg;
    reg fault_read_d;

    //Wires
    logic fault_dataAddr;
    logic fault_bitmask;

    logic fault_din;
    logic fault_access;
    logic fault_write;
    logic fault_read;

    logic overwrite_w;
    logic overwrite_r;

    //Assigns
    assign fault_dataAddr = fault_addr[dataAddrW-1:addrW];
    assign fault_bitmask = 1 << fault_dataAddr;

    assign fault_din = din[fault_dataAddr];
    assign fault_access = (addr == fault_addr[addrW-1:0]) && !cs_n;
    assign fault_write = fault_access && !we_n && !bwe_n[fault_dataAddr];
    assign fault_read = fault_access && !re_n;

    assign overwrite_w = fault_write && (fault_din != fault_reg);
    assign overwrite_r = fault_read_d && (fault_reg != fault_primitive);

    assign fault_w = overwrite_w ? fault_bitmask : '0;
    assign fault_r = overwrite_r ? fault_bitmask : '0;

    //Instances

    // Processes
  //------------------------------- Sequential ------------------------------
    always @(negedge clk or negedge nres)
    begin
      if (nres == 0) begin
        fault_read_d <= 1'b0;
        fault_reg <= fault_primitive;
      end else begin
        fault_read_d <= fault_read;
        if (fault_write && !overwrite_w) begin
          fault_reg <= fault_din;
        end
      end
    end

  //------------------------------ Combinational ----------------------------

endmodule