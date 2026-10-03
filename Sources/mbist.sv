
`define COUNTERS
`define WORDMBIST

module mbist
  #(
    parameter int base_index = 0,
    parameter int parallel_mems = 2,
    parameter int mem_addrW = 10,
    parameter int mem_dataW = 32,
    parameter int addrW = 13,
    parameter int dataW = 64
  ) (
    input  logic clk,
    input  logic nres,
    //MBIST Interface
    input  logic                             mbist_en,
    input  logic                       [4:0] mbist_mode,
    output logic                             mbist_sel,
    output logic         [parallel_mems-1:0] mbist_fault,
    output logic     [(parallel_mems*8)-1:0] mbist_fault_state,
    output logic [(parallel_mems*addrW)-1:0] mbist_fault_addr,
    output logic               [(dataW)-1:0] mbist_fault_data,
    output logic               [(dataW)-1:0] mbist_fault_dout,
    output logic                             mbist_done,
    //Memory Port
    output logic                 cs_n,
    output logic [mem_addrW-1:0] addr,
    output logic                 we_n,
    output logic     [dataW-1:0] bwe_n,
    output logic     [dataW-1:0] din,
    output logic                 re_n,
    input  logic     [dataW-1:0] dout
  );

    localparam int bweW = $clog2(mem_dataW);
    localparam int cntW = mem_addrW+bweW;

    //Registers
    reg [7:0] mbist_state;
    reg [cntW-1:0] mbist_addr_counter;

    reg                 comp_en_d;
    reg           [7:0] mbist_state_d;
    reg [mem_addrW-1:0] mbist_addr_d;
    reg [mem_dataW-1:0] mbist_bwe_d;
    reg     [dataW-1:0] mbist_din_d;


    //Wires
    logic [1:0] transition_state;
    logic [3:0] z_state;

    logic [cntW-1:0] mbist_addr_bwe;
    logic [mem_addrW-1:0] mbist_addr;
    logic [bweW-1:0] mbist_bwe;
    logic [mem_dataW-1:0] mbist_bwe_n;
    logic [1:0] addr_cnt;
    logic [cntW-1:0] addr_cnt_inc;
    logic       up_end;
    logic       down_end;
    logic       state_end;
    logic       mbist_end;

    logic             mbist_cs_n;
    logic             mbist_we_n;
    logic             mbist_re_n;
    logic             data_in;
    logic [dataW-1:0] mbist_din_0;
    logic [dataW-1:0] mbist_din_1;
    logic [dataW-1:0] mbist_din;
    logic [dataW-1:0] mbist_dout;
    
    logic [(addrW - mem_addrW)-1:0] mbist_sect [parallel_mems-1:0];

    

    //Assigns
    assign cs_n = mbist_en ? mbist_cs_n : 1'b1;
    assign addr = mbist_en ? mbist_addr : '0;
    assign we_n = mbist_en ? mbist_we_n : 1'b1;
    assign din = mbist_en ? mbist_din : '0;
    assign re_n = mbist_en ? mbist_re_n : 1'b1;
    assign mbist_dout = mbist_en ? dout : '0;

    assign mbist_bwe = mbist_addr_bwe[bweW-1:0];
    assign mbist_addr = mbist_addr_bwe[cntW-1:bweW];

    assign mbist_sel = mbist_state[7] == 1'b1;
    assign mbist_done = mbist_state == 8'h01;

    assign mbist_cs_n = mbist_sel ? 1'b0 : 1'b1;
    assign mbist_we_n = mbist_sel ? !mbist_state[1] : 1'b1;
    assign mbist_re_n = mbist_sel ? mbist_state[1] : 1'b1;

    assign data_in = mbist_sel ? mbist_state[0] : 1'b0;
    assign mbist_din = data_in ? mbist_din_1 : mbist_din_0;

    genvar x;
    generate
      for (x = 0; x < parallel_mems; x = x + 1) begin : parallel_control
        assign bwe_n[(mem_dataW*(x+1))-1:(mem_dataW*x)] = mbist_en ? mbist_bwe_n : '1;
        assign mbist_sect[x] = (base_index + x) / parallel_mems;

        assign mbist_fault[x] = mbist_sel && comp_en_d && ((mbist_dout[(mem_dataW*(x+1))-1:(mem_dataW*x)] & ~mbist_bwe_d) != (mbist_din_d[(mem_dataW*(x+1))-1:(mem_dataW*x)] & ~mbist_bwe_d));
        assign mbist_fault_state[(8*(x+1))-1:(8*x)] = mbist_fault[x] ? mbist_state_d : '0;
        assign mbist_fault_addr[(addrW*(x+1))-1:(addrW*x)] = {mbist_sect[x], mbist_fault[x] ? mbist_addr_d : '0};
        assign mbist_fault_data[(mem_dataW*(x+1))-1:(mem_dataW*x)] = mbist_fault[x] ? (mbist_din_d[(mem_dataW*(x+1))-1:(mem_dataW*x)] & ~mbist_bwe_d) : '0;
        assign mbist_fault_dout[(mem_dataW*(x+1))-1:(mem_dataW*x)] = mbist_fault[x] ? (mbist_dout[(mem_dataW*(x+1))-1:(mem_dataW*x)] & ~mbist_bwe_d) : '0;
      end
    endgenerate



    //Instances
    `ifndef COUNTERS
      assign mbist_addr_bwe = mbist_addr_counter;
    `else
      `ifndef WORDMBIST
        count_transformer #(
          .cntW(cntW),
          .tab1(15),
          .tab2(7),
          .tab3(4),
          .tab4(1)
        ) CNT_TF (
          .clk(clk),
          .nres(nres),
          .counter(mbist_addr_counter),
          .lfsr_dir(addr_cnt),
          .sel(mbist_mode[3:0]),
          .addr_bwe(mbist_addr_bwe)
        );
      `else
        count_transformer #(
          .cntW(mem_addrW),
          .tab1(10),
          .tab2(9),
          .tab3(4),
          .tab4(1)
        ) CNT_TF (
          .clk(clk),
          .nres(nres),
          .counter(mbist_addr_counter[cntW-1:bweW]),
          .lfsr_dir(addr_cnt),
          .sel(mbist_mode[3:0]),
          .addr_bwe(mbist_addr_bwe[cntW-1:bweW])
        );
        assign mbist_addr_bwe[bweW-1:0] = mbist_addr_counter[bweW-1:0];
      `endif
    `endif

    `ifndef WORDMBIST
      assign addr_cnt_inc = 2'b01;
      assign up_end = mbist_addr_counter == (2**cntW-1);
      assign down_end = mbist_addr_counter == 0;
      assign state_end = mbist_state[2] ? down_end : up_end;

      genvar y;
      generate
        for (x = 0; x < mem_dataW; x = x + 1) begin : mbist_bwe_logic
          assign mbist_bwe_n[x] = (mbist_bwe == x) ? 1'b0 : 1'b1;
        end
      endgenerate

      assign mbist_end = 1'b1;
      assign mbist_din_0 = '0;
      assign mbist_din_1 = '1;
    `else
      assign addr_cnt_inc = 1'b1 << bweW;
      assign up_end = mbist_addr_counter == (2**mem_addrW-1) << bweW;
      assign down_end = mbist_addr_counter == 0;
      assign state_end = mbist_state[2] ? down_end : up_end;

      assign mbist_bwe_n = '0;

      db_generator #(
        .dataW(dataW),
        .end_state(8'b10001000),
        .car_state(8'b10000000)
      ) DB_GEN (
        .clk(clk),
        .nres(nres),
        .mbist_state(mbist_state),
        .state_end(state_end),
        .mbist_addr0(mbist_addr[0]),
        .alt_mode(mbist_mode[4]),
        .mbist_din_0(mbist_din_0),
        .mbist_din_1(mbist_din_1),
        .mbist_end(mbist_end)
      );
    `endif



    // Processes
  //------------------------------- Sequential ------------------------------
    // MBIST Inputs Delay Registers for Comparison
    always @(posedge clk or negedge nres)
    begin
      if (nres == 0) begin
        comp_en_d <= 1'b0;
        mbist_state_d <= '0;
        mbist_addr_d <= '0;
        mbist_bwe_d <= '1;
        mbist_din_d <= '0;
      end else begin
        comp_en_d <= mbist_sel && !mbist_re_n;
        mbist_state_d <= mbist_state;
        mbist_addr_d <= mbist_addr;
        mbist_bwe_d <= mbist_bwe_n;
        mbist_din_d <= mbist_din;
      end
    end

    // Address Counter with selectable direction
    always @(posedge clk or negedge nres) begin
      if (nres == 0) begin
        mbist_addr_counter <= '0;
      end else begin
        if (addr_cnt == 2'b11) begin
          mbist_addr_counter <= '0;
        end else if (addr_cnt[0] == 1'b1) begin
          mbist_addr_counter <= mbist_addr_counter + addr_cnt_inc;
        end else if (addr_cnt[1] == 1'b1) begin
          mbist_addr_counter <= mbist_addr_counter - addr_cnt_inc;
        end
      end
    end

    // MBIST State Machine
    always @(posedge clk or negedge nres) begin
      if (nres == 0) begin
        mbist_state <= 8'h00;
      end else begin
        case (mbist_state)

        // Bits: {dont / do sel, 3x identifier bits, dont / do count, up / down count, r / w operation, 0 / 1 bit}

          8'h00: begin // Idle
            if (mbist_en == 1'b1) mbist_state <= 8'b10001010;
          end

          8'b10001010: begin // M0.1 - up w0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else if (state_end == 1'b1) begin
              mbist_state <= 8'b10000000;
            end
          end

          8'b10000000: begin // M1.1 - up r0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10000011;
            end
          end

          8'b10000011: begin // M1.2 - up w1
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10010011;
            end
          end

          8'b10010011: begin // M1.3 - up w1
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10001001;
            end
          end

          8'b10001001: begin // M1.4 - up r1
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else if (state_end == 1'b1) begin
              mbist_state <= 8'b10000101;
            end else begin
              mbist_state <= 8'b10000000;
            end
          end

          8'b10000101: begin // M2.1 - down r1
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10000110;
            end
          end

          8'b10000110: begin // M2.2 - down w0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10010110;
            end
          end

          8'b10010110: begin // M2.3 - down w0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10001100;
            end
          end

          8'b10001100: begin // M2.4 - down r0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else if (state_end == 1'b1) begin
              mbist_state <= 8'b10000100;
            end else begin
              mbist_state <= 8'b10000101;
            end
          end

          8'b10000100: begin // M3.1 - down r0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10100110;
            end
          end

          8'b10100110: begin // M3.2 - down w0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10000111;
            end
          end

          8'b10000111: begin // M3.3 - down w1
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10001101;
            end
          end

          8'b10001101: begin // M3.4 - down r1
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else if (state_end == 1'b1) begin
              mbist_state <= 8'b10000001;
            end else begin
              mbist_state <= 8'b10000100;
            end
          end

          8'b10000001: begin // M4.1 - up r1
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10100011;
            end
          end

          8'b10100011: begin // M4.2 - up w1
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10000010;
            end
          end

          8'b10000010: begin // M4.3 - up w0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10010000;
            end
          end

          8'b10010000: begin // M4.4 - up r0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else begin
              mbist_state <= 8'b10001000;
            end
          end

          8'b10001000: begin // M4.5 - up r0
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
            else if (state_end == 1'b1) begin
              if (mbist_end == 1'b1)
                mbist_state <= 8'h01;
              else
                mbist_state <= 8'b10000000;
            end else begin
              mbist_state <= 8'b10000001;
            end
          end

          8'h01: begin // END
            if (mbist_en == 1'b0) mbist_state <= 8'h00;
          end

          default: begin
            mbist_state <= 8'h01;
          end
        endcase
      end
    end

  //------------------------------ Combinational ----------------------------

    always_comb begin
      case (mbist_state)
        8'b10001001: transition_state = 2'b01;
        8'b10001101: transition_state = 2'b10;
        default:     transition_state = 2'b00;
      endcase
    end

    always_comb begin
      case (mbist_state)
        8'h00:       z_state = 4'h0;
        8'b10001010: z_state = 4'h1;
        8'b10000000: z_state = 4'h2;
        8'b10000011: z_state = 4'h2;
        8'b10010011: z_state = 4'h2;
        8'b10001001: z_state = 4'h2;
        8'b10000101: z_state = 4'h3;
        8'b10000110: z_state = 4'h3;
        8'b10010110: z_state = 4'h3;
        8'b10001100: z_state = 4'h3;
        8'b10000100: z_state = 4'h4;
        8'b10100110: z_state = 4'h4;
        8'b10000111: z_state = 4'h4;
        8'b10001101: z_state = 4'h4;
        8'b10000001: z_state = 4'h5;
        8'b10100011: z_state = 4'h5;
        8'b10000010: z_state = 4'h5;
        8'b10010000: z_state = 4'h5;
        8'b10001000: z_state = 4'h5;
        8'h01:       z_state = 4'h6;
        default:     z_state = 4'hF;
      endcase
    end

    always @(*) begin
      if (mbist_sel) begin
          if ((transition_state[0] && up_end) || (transition_state[1] && down_end)) begin
            addr_cnt  = 2'b00;
          end else begin
            addr_cnt = { mbist_state[3] && mbist_state[2], 
                          mbist_state[3] && !mbist_state[2]};
          end
      end else begin
          addr_cnt  = 2'b11;
      end
    end

endmodule



`ifdef COUNTERS
module count_transformer
  #(
    parameter int cntW = 8,
    parameter int tab1 = 15,
    parameter int tab2 = 7,
    parameter int tab3 = 4,
    parameter int tab4 = 1
  ) (
    input  logic            clk,
    input  logic            nres,
    input  logic [cntW-1:0] counter,
    input  logic      [1:0] lfsr_dir,
    input  logic      [3:0] sel,
    output logic [cntW-1:0] addr_bwe
  );

  reg [cntW-1:0] lfsr;
  logic fb_up;
  logic fb_down;
  assign fb_up =   (sel[3:0] == 4'hD) ? lfsr[tab1-1] ^ lfsr[tab2-1] ^ lfsr[tab3-1] ^ lfsr[tab4-1] ^ ~(|lfsr[cntW-2:0]) : 1'b0;
  assign fb_down = (sel[3:0] == 4'hD) ? lfsr[tab2] ^ lfsr[tab3] ^ lfsr[tab4] ^ lfsr[0] ^ ~(|lfsr[cntW-1:1]) : 1'b0;
  
  // Address LFSR matching address counter
  always @(posedge clk or negedge nres) begin
    if (nres == 0) begin
      lfsr <= '0;
    end else begin
      if (lfsr_dir == 2'b11) begin
        lfsr <= '0;
      end else if (lfsr_dir[0] == 1'b1) begin
        lfsr <= {lfsr[cntW-2:0], fb_up};
      end else if (lfsr_dir[1] == 1'b1) begin
        lfsr <= {fb_down, lfsr[cntW-1:1]};
      end
    end
  end

  genvar x;
  generate
    for (x = 0; x < cntW; x = x + 1) begin : gen_addr_bwe
      always @(*) begin
        if (sel < 4'hB) begin // CSx = Column Shift x = sel
          if (x+sel < cntW)
            addr_bwe[x] = counter[x+sel];
          else
            addr_bwe[x] = counter[x+sel-cntW];

        end else if (sel == 4'hB) begin // AC = Address Compliment
          if (x == cntW-1)
            addr_bwe[x] = counter[0];
          else
            addr_bwe[x] = counter[0] ^ counter[x+1];

        end else if (sel == 4'hC) begin // GC = Gray Code
          if (x == cntW-1)
            addr_bwe[x] = counter[x];
          else
            addr_bwe[x] = counter[x] ^ counter[x+1];

        end else if (sel == 4'hD) begin // LFSR
          addr_bwe[x] = lfsr[x];

        end else begin // L = Linear (Default)
          addr_bwe[x] = counter[x];
        end
      end
    end
  endgenerate

endmodule
`endif



`ifdef WORDMBIST

`define LONGDBS

module db_generator
  #(
    parameter int dataW = 32,
    parameter int end_state = 8'b10001000,
    parameter int car_state = 8'b10000000
  ) (
    input  logic             clk,
    input  logic             nres,
    input  logic       [7:0] mbist_state,
    input  logic             state_end,
    input  logic             mbist_addr0,
    input  logic             alt_mode,
    output logic [dataW-1:0] mbist_din_0,
    output logic [dataW-1:0] mbist_din_1,
    output logic             mbist_end
  );

  logic [dataW-1:0] db_base;
  `ifndef LONGDBS
  reg         [2:0] db_state;
  assign mbist_end = (db_state == 3'b111);

  always_comb begin
    case (db_state)
      3'b000:  db_base = 64'h5555555555555555; //01010101
      3'b001:  db_base = 64'h3333333333333333; //00110011
      3'b010:  db_base = 64'h9999999999999999; //10011001
      3'b011:  db_base = 64'h1111111111111111; //00010001
      3'b100:  db_base = 64'h2222222222222222; //00100010
      3'b101:  db_base = 64'h4444444444444444; //01000100
      3'b110:  db_base = 64'h8888888888888888; //10001000
      default: db_base = '0;                   //00000000
    endcase
  end
  `else
  reg         [3:0] db_state;
  assign mbist_end = (db_state == 4'b1111);

  always_comb begin
    case (db_state)
      4'b0000: db_base = 64'h3333333333333333; //00110011
      4'b0001: db_base = 64'h5555555555555555; //01010101
      4'b0010: db_base = 64'h9999999999999999; //10011001
      4'b0011: db_base = 64'h7878787878787878; //01111000
      4'b0100: db_base = 64'h2222222222222222; //00100010
      4'b0101: db_base = 64'hB4B4B4B4B4B4B4B4; //10110100
      4'b0110: db_base = 64'h1111111111111111; //00010001
      4'b0111: db_base = 64'h8888888888888888; //10001000
      4'b1000: db_base = 64'h6969696969696969; //01101001
      4'b1001: db_base = 64'h5A5A5A5A5A5A5A5A; //01011010
      4'b1010: db_base = 64'h3C3C3C3C3C3C3C3C; //00111100
      4'b1011: db_base = 64'h1E1E1E1E1E1E1E1E; //00011110
      4'b1100: db_base = 64'h4444444444444444; //01000100
      4'b1101: db_base = 64'h0F0F0F0F0F0F0F0F; //00001111
      4'b1110: db_base = 64'h2D2D2D2D2D2D2D2D; //00101101
      default: db_base = '0;                   //00000000
    endcase
  end
  `endif

  reg   [dataW-1:0] db_base_reg;
  reg   [dataW-1:0] db_base_reg_d;
  logic [dataW-1:0] din_0;
  logic [dataW-1:0] din_1;

  assign din_0 = (mbist_state == car_state) ? db_base_reg_d : db_base_reg;
  assign din_1 = (mbist_state == car_state) ? ~db_base_reg_d : ~db_base_reg;

  assign mbist_din_0 = (alt_mode & mbist_addr0) ? din_0 : din_1;
  assign mbist_din_1 = (alt_mode & mbist_addr0) ? din_1 : din_0;

  always @(posedge clk or negedge nres)
    begin
      if (nres == 0) begin
        db_state <= 0;
        db_base_reg <= '0;
        db_base_reg_d <= '0;
      end else begin
        if (mbist_state == 8'h00) begin
          db_state <= 0;
          db_base_reg <= '0;
          db_base_reg_d <= '0;
        end else if (mbist_state == end_state && state_end == 1'b1) begin
          db_state <= db_state + 1;
          db_base_reg <= db_base;
          db_base_reg_d <= db_base_reg;
        end
      end
    end

endmodule
`endif
