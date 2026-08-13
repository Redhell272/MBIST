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
    output logic       [3:0] mbist_fault_state,
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
    reg       [3:0] mbist_state;

    reg [addrW-1:0] mbist_addr;
    reg [dataW-1:0] mbist_bwe_n;

    reg             comp_en_d;
    reg       [3:0] mbist_state_d;
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

    assign mbist_sel = (mbist_state[3] == 1'b1) || ((mbist_state == 4'b0010) || (mbist_state == 4'b0100));

    assign bwe_shift = mbist_sel ? {mbist_state[2], !mbist_state[2]} : 2'b11;
    assign addr_cnt = mbist_sel ? {mbist_state[2] && bwe_ends[0], !mbist_state[2] && bwe_ends[3]} : 2'b11;

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
    always @(negedge clk or negedge nres)
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
    always @(negedge clk or negedge nres)
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
    always @(negedge clk or negedge nres)
    begin
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
    always @(negedge clk or negedge nres)
    begin
      if (nres == 0) begin
        mbist_state <= 4'b0000;
      end else begin
        case (mbist_state)

        // Bits: {outer / main body, up / down count, r / w operation, 0 / 1 bit}

          4'b0000: begin // Idle
            if (mbist_en == 1'b1) mbist_state <= 4'b0010;
          end

          4'b0010: begin // M0 - up w0
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1) begin
              mbist_state <= 4'b1000;
            end
          end

          4'b1000: begin // M1 - up r0
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1) begin
              mbist_state <= 4'b1011;
            end
          end

          4'b1011: begin // M1 - up w1
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1) begin
              mbist_state <= 4'b1001;
            end
          end

          4'b1001: begin // M2 - up r1
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1) begin
              mbist_state <= 4'b1010;
            end
          end

          4'b1010: begin // M2 - up w0
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1) begin
              mbist_state <= 4'b1100;
            end
          end

          4'b1100: begin // M3 - down r0
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[0] == 1'b1 && bwe_ends[0] == 1'b1) begin
              mbist_state <= 4'b1111;
            end
          end

          4'b1111: begin // M3 - down w1
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[0] == 1'b1 && bwe_ends[0] == 1'b1) begin
              mbist_state <= 4'b1101;
            end
          end

          4'b1101: begin // M4 - down r1
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[0] == 1'b1 && bwe_ends[0] == 1'b1) begin
              mbist_state <= 4'b1110;
            end
          end

          4'b1110: begin // M4 - down w0
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[0] == 1'b1 && bwe_ends[0] == 1'b1) begin
              mbist_state <= 4'b0100;
            end
          end

          4'b0100: begin // M5 - down r0
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
            else if (addr_ends[0] == 1'b1 && bwe_ends[0] == 1'b1) begin
              mbist_state <= 4'b0001;
            end
          end

          4'b0001: begin // END
            if (mbist_en == 1'b0) mbist_state <= 4'b0000;
          end

          default: begin
            mbist_state <= 4'b0001;
          end
        endcase
      end
    end

  //------------------------------ Combinational ----------------------------

endmodule