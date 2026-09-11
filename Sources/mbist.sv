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
    output logic                             mbist_sel,
    output logic         [parallel_mems-1:0] mbist_fault,
    output logic     [(parallel_mems*8)-1:0] mbist_fault_state,
    output logic [(parallel_mems*addrW)-1:0] mbist_fault_addr,
    output logic               [(dataW)-1:0] mbist_fault_data,
    output logic               [(dataW)-1:0] mbist_fault_dout,
    output logic               [(dataW)-1:0] mbist_fault_expc,
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

    //Registers
    reg [7:0] mbist_state;

    reg [mem_addrW-1:0] mbist_addr;
    reg [mem_dataW-1:0] mbist_bwe_n;

    reg                 comp_en_d;
    reg           [7:0] mbist_state_d;
    reg [mem_addrW-1:0] mbist_addr_d;
    reg [mem_dataW-1:0] mbist_bwe_d;
    reg     [dataW-1:0] mbist_din_d;


    //Wires
    logic [1:0] transition_state;
    logic [3:0] z_state;

    logic [1:0] bwe_shift;
    logic [3:0] bwe_ends;
    logic [1:0] addr_cnt;
    logic [3:0] addr_ends;
    logic       up_end;
    logic       down_end;
    logic       state_end;

    logic             mbist_cs_n;
    logic             mbist_we_n;
    logic             mbist_re_n;
    logic             data_in;
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

    assign bwe_ends = {!mbist_bwe_n[mem_dataW-1], !mbist_bwe_n[mem_dataW-2], !mbist_bwe_n[1], !mbist_bwe_n[0]};
    assign addr_ends = {mbist_addr == (2**mem_addrW-1), mbist_addr == (2**mem_addrW-2), mbist_addr == 1, mbist_addr == 0};
    assign up_end = addr_ends[3] == 1'b1 && bwe_ends[3] == 1'b1;
    assign down_end = addr_ends[0] == 1'b1 && bwe_ends[0] == 1'b1;
    assign state_end = mbist_state[2] ? down_end : up_end;

    assign mbist_sel = mbist_state[7] == 1'b1;
    assign mbist_done = mbist_state == 8'h01;

    assign mbist_cs_n = mbist_sel ? 1'b0 : 1'b1;
    assign mbist_we_n = mbist_sel ? !mbist_state[1] : 1'b1;
    assign mbist_re_n = mbist_sel ? mbist_state[1] : 1'b1;

    assign data_in = mbist_sel ? mbist_state[0] : 1'b0;
    assign mbist_din = data_in ? '1 : '0;

    genvar x;
    generate
      for (x = 0; x < parallel_mems; x = x + 1) begin : parallel_control
        assign bwe_n[(mem_dataW*(x+1))-1:(mem_dataW*x)] = mbist_en ? mbist_bwe_n : '1;
        assign mbist_sect[x] = (base_index + x) / parallel_mems;

        assign mbist_fault[x] = mbist_sel && comp_en_d && ((mbist_dout[(mem_dataW*(x+1))-1:(mem_dataW*x)] & ~mbist_bwe_d) != (mbist_din_d[(mem_dataW*(x+1))-1:(mem_dataW*x)] & ~mbist_bwe_d));
        assign mbist_fault_state[(8*(x+1))-1:(8*x)] = mbist_fault[x] ? mbist_state_d : '0;
        assign mbist_fault_addr[(addrW*(x+1))-1:(addrW*x)] = {mbist_sect[x], mbist_fault[x] ? mbist_addr_d : '0};
        assign mbist_fault_data[(mem_dataW*(x+1))-1:(mem_dataW*x)] = mbist_fault[x] ? ~mbist_bwe_d : '0;
        assign mbist_fault_dout[(mem_dataW*(x+1))-1:(mem_dataW*x)] = mbist_fault[x] ? mbist_dout[(mem_dataW*(x+1))-1:(mem_dataW*x)] : '0;
        assign mbist_fault_expc[(mem_dataW*(x+1))-1:(mem_dataW*x)] = mbist_fault[x] ? mbist_din_d[(mem_dataW*(x+1))-1:(mem_dataW*x)] : '0;
      end
    endgenerate

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
        mbist_bwe_n[mem_dataW-1:1] <= '1;
      end else begin
        if (bwe_shift == 2'b11) begin
          mbist_bwe_n[0] <= 1'b0;
          mbist_bwe_n[mem_dataW-1:1] <= '1;
        end else if (bwe_shift[0] == 1'b1) begin
          mbist_bwe_n <= {mbist_bwe_n[mem_dataW-2:0], mbist_bwe_n[mem_dataW-1]};
        end else if (bwe_shift[1] == 1'b1) begin
          mbist_bwe_n <= {mbist_bwe_n[0], mbist_bwe_n[mem_dataW-1:1]};
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
              mbist_state <= 8'h01;
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

endmodule