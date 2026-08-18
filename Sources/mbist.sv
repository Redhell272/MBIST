module mbist
  #(
    parameter int addrW = 8,
    parameter int dataW = 32
  ) (
    input  logic clk,
    input  logic nres,
    //MBIST Interface
    input  logic             mbist_en,
    output logic             mbist_sel,
    output logic             mbist_fault,
    output logic       [4:0] mbist_fault_state,
    output logic [addrW-1:0] mbist_fault_addr,
    output logic [dataW-1:0] mbist_fault_data,
    output logic [dataW-1:0] mbist_fault_dout,
    output logic [dataW-1:0] mbist_fault_expc,
    //Memory Port
    output logic             cs_n,
    output logic [addrW-1:0] addr,
    output logic             we_n,
    output logic [dataW-1:0] bwe_n,
    output logic [dataW-1:0] din,
    output logic             re_n,
    input  logic [dataW-1:0] dout
  );

    //Registers
    reg       [4:0] mbist_state;

    reg [addrW-1:0] mbist_addr;
    reg [dataW-1:0] mbist_bwe_n;

    reg             comp_en_d;
    reg       [4:0] mbist_state_d;
    reg [addrW-1:0] mbist_addr_d;
    reg [dataW-1:0] mbist_bwe_d;
    reg [dataW-1:0] mbist_din_d;


    //Wires
    logic       [1:0] bwe_shift;
    logic       [3:0] bwe_ends;
    logic       [1:0] addr_cnt;
    logic       [3:0] addr_ends;

    logic             mbist_cs_n;
    logic             mbist_we_n;
    logic             mbist_re_n;
    logic             data_in;
    logic [dataW-1:0] mbist_din;
    logic [dataW-1:0] mbist_dout;

    logic       [3:0] z_state;
    

    //Assigns
    assign cs_n = mbist_en ? mbist_cs_n : 1'b1;
    assign addr = mbist_en ? mbist_addr : '0;
    assign we_n = mbist_en ? mbist_we_n : 1'b1;
    assign bwe_n = mbist_en ? mbist_bwe_n : '1;
    assign din = mbist_en ? mbist_din : '0;
    assign re_n = mbist_en ? mbist_re_n : 1'b1;
    assign mbist_dout = mbist_en ? dout : '0;

    assign bwe_ends = {!mbist_bwe_n[dataW-1], !mbist_bwe_n[dataW-2], !mbist_bwe_n[1], !mbist_bwe_n[0]};
    assign addr_ends = {mbist_addr == (2**addrW-1), mbist_addr == (2**addrW-2), mbist_addr == 1, mbist_addr == 0};

    assign mbist_sel = (mbist_state[4] == 1'b1) || ((mbist_state == 5'b01010) || (mbist_state == 5'b01100));

    assign mbist_cs_n = mbist_sel ? 1'b0 : 1'b1;
    assign mbist_we_n = mbist_sel ? !mbist_state[1] : 1'b1;
    assign mbist_re_n = mbist_sel ? mbist_state[1] : 1'b1;

    assign data_in = mbist_sel ? mbist_state[0] : 1'b0;
    assign mbist_din = data_in ? '1 : '0;

    assign mbist_fault = mbist_sel && comp_en_d && ((mbist_dout & ~mbist_bwe_d) != (mbist_din_d & ~mbist_bwe_d));
    assign mbist_fault_state = mbist_fault ? mbist_state_d : '0;
    assign mbist_fault_addr = mbist_fault ? mbist_addr_d : '0;
    assign mbist_fault_data = mbist_fault ? ~mbist_bwe_d : '0;
    assign mbist_fault_dout = mbist_fault ? mbist_dout : '0;
    assign mbist_fault_expc = mbist_fault ? mbist_din_d : '0;

    //Instances

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

    // bWE Shift Register with selectable direction
    always @(posedge clk or negedge nres)
    begin
      if (nres == 0) begin
        mbist_bwe_n[0] <= 1'b0;
        mbist_bwe_n[dataW-1:1] <= '1;
      end else begin
        if (bwe_shift == 2'b11) begin
          mbist_bwe_n[0] <= 1'b0;
          mbist_bwe_n[dataW-1:1] <= '1;
        end else if (bwe_shift[0] == 1'b1) begin
          mbist_bwe_n <= {mbist_bwe_n[dataW-2:0], mbist_bwe_n[dataW-1]};
        end else if (bwe_shift[1] == 1'b1) begin
          mbist_bwe_n <= {mbist_bwe_n[0], mbist_bwe_n[dataW-1:1]};
        end
      end
    end

    // Address Counter with selectable direction
    always @(posedge clk or negedge nres) begin
      if (nres == 0) begin
        mbist_addr <= '0;
      end else begin
        if (addr_cnt == 2'b11) begin
          mbist_addr <= '0;
        end else if (addr_cnt[0] == 1'b1) begin
          mbist_addr <= mbist_addr + 1'b1;
        end else if (addr_cnt[1] == 1'b1) begin
          mbist_addr <= mbist_addr - 1'b1;
        end
      end
    end

    // MBIST State Machine
    always @(posedge clk or negedge nres) begin
      if (nres == 0) begin
        mbist_state <= 5'b00000;
      end else begin
        case (mbist_state)

        // Bits: {outer / main body, dont / do count, up / down count, r / w operation, 0 / 1 bit}

          5'b00000: begin // Idle
            if (mbist_en == 1'b1) mbist_state <= 5'b01010;
          end

          5'b01010: begin // M0.1 - up w0
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else if (addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1) begin
              mbist_state <= 5'b10000;
            end
          end

          5'b10000: begin // M1.1 - up r0
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else begin
              mbist_state <= 5'b11011;
            end
          end

          5'b11011: begin // M1.2 - up w1
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else if (addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1) begin
              mbist_state <= 5'b10001;
            end else begin
              mbist_state <= 5'b10000;
            end
          end

          5'b10001: begin // M2.1 - up r1
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else begin
              mbist_state <= 5'b11010;
            end
          end

          5'b11010: begin // M2.2 - up w0
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else if (addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1) begin
              mbist_state <= 5'b10100;
            end else begin
              mbist_state <= 5'b10001;
            end
          end

          5'b10100: begin // M3.1 - down r0
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else begin
              mbist_state <= 5'b11111;
            end
          end

          5'b11111: begin // M3.2 - down w1
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else if (addr_ends[0] == 1'b1 && bwe_ends[0] == 1'b1) begin
              mbist_state <= 5'b10101;
            end else begin
              mbist_state <= 5'b10100;
            end
          end

          5'b10101: begin // M4.1 - down r1
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else begin
              mbist_state <= 5'b11110;
            end
          end

          5'b11110: begin // M4.2 - down w0
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else if (addr_ends[0] == 1'b1 && bwe_ends[0] == 1'b1) begin
              mbist_state <= 5'b01100;
            end else begin
              mbist_state <= 5'b10101;
            end
          end

          5'b01100: begin // M5.1 - down r0
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
            else if (addr_ends[0] == 1'b1 && bwe_ends[0] == 1'b1) begin
              mbist_state <= 5'b00001;
            end
          end

          5'b00001: begin // END
            if (mbist_en == 1'b0) mbist_state <= 5'b00000;
          end

          default: begin
            mbist_state <= 5'b00001;
          end
        endcase
      end
    end

  //------------------------------ Combinational ----------------------------
    always_comb begin
      if (mbist_sel) begin
          if (mbist_state == 5'b11010 && addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1) begin
            bwe_shift = 2'b00;
            addr_cnt  = 2'b00;
          end else begin
            bwe_shift = { mbist_state[3] && mbist_state[2], 
                          mbist_state[3] && !mbist_state[2]};
            addr_cnt  = { mbist_state[3] && mbist_state[2] && bwe_ends[0], 
                          mbist_state[3] && !mbist_state[2] && bwe_ends[3]};
          end
      end else begin
          bwe_shift = 2'b11;
          addr_cnt  = 2'b11;
      end
    end

    always_comb begin
      case (mbist_state)
        5'b00000: z_state = 4'h0;
        5'b01010: z_state = 4'h1;
        5'b10000: z_state = 4'h2;
        5'b11011: z_state = 4'h2;
        5'b10001: z_state = 4'h3;
        5'b11010: z_state = 4'h3;
        5'b10100: z_state = 4'h4;
        5'b11111: z_state = 4'h4;
        5'b10101: z_state = 4'h5;
        5'b11110: z_state = 4'h5;
        5'b01100: z_state = 4'h6;
        5'b00001: z_state = 4'h7;
        default:  z_state = 4'hF;
      endcase
    end

endmodule