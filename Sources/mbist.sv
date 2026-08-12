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
    output logic [addrW-1:0] mbist_fault_addr,
    output logic [dataW-1:0] mbist_fault_data,
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
    reg             mbist_cs_n;
    reg             mbist_we_n;
    reg             mbist_re_n;
    reg [addrW-1:0] mbist_addr;
    reg [dataW-1:0] mbist_bwe_n;

    reg       [2:0] mbist_state;

    //Wires
    logic             data_in;
    logic       [1:0] bwe_shift;
    logic       [1:0] bwe_ends;
    logic       [1:0] addr_cnt;

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

    assign mbist_din = data_in ? '1 : '0;
    assign bwe_ends = {mbist_bwe_n[dataW-1], mbist_bwe_n[0]};

    assign mbist_sel = mbist_state != 3'b000;

    //Instances

    // Processes
  //------------------------------- Sequential ------------------------------
    // bWE Shift Register with selectable direction
    always @(negedge clk or negedge nres)
    begin
      if (nres == 0) begin
        mbist_bwe_n[0] <= 1'b1;
        mbist_bwe_n[dataW-1:1] <= '0;
      end else begin
        if (bwe_shift[0] == 1'b1) begin
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
        if (addr_cnt[0] == 1'b1) begin
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
        mbist_state <= 3'b000;
      end else begin
        case (mbist_state)

          3'b000: begin // Idle
            if (mbist_en == 1'b1) begin
              mbist_state <= 3'b001;
            end
          end

          default: begin
            mbist_state <= 3'b000;
          end
        endcase
      end
    end

  //------------------------------ Combinational ----------------------------

endmodule