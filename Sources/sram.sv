module sram
  #(
    parameter int addrW = 8,
    parameter int dataW = 32
  ) (
    input  logic             clk,
    input  logic             cs_n,
    input  logic [addrW-1:0] addr,
    //Write
    input  logic             we_n,
    input  logic [dataW-1:0] bwe_n,
    input  logic [dataW-1:0] din,
    //Read
    input  logic             re_n,
    output logic [dataW-1:0] dout
  );

  `ifndef SYNTHESIS // simulation: SRAM model

    logic [dataW-1:0] mem [(2**addrW)-1:0]; 
    
    //Write
    genvar x;
    generate
      for (x = 0; x < dataW; x = x + 1) begin
        always @ (posedge clk) begin
          if (!cs_n && !we_n && !bwe_n[x])
            mem[addr][x] <= din[x];
        end
      end
    endgenerate

    //Read
    always @ (posedge clk)
    begin
        if (!cs_n && !re_n)
            dout <= mem[addr];
    end

  `else  // synthesis: SRAM macro

    logic macro_csb0;
    assign macro_csb0 = cs_n || (we_n && re_n);
    
    logic [31:0] unused_dout1;

    sky130_sram_4kbyte_1rw1r_32x1024_8 sram_macro (
        // Port 0 (Active - Fully mapped to wrapper pins)
        .clk0   (clk),
        .csb0   (macro_csb0),
        .web0   (we_n),
        .wmask0 (bwe_n), 
        .addr0  (addr),
        .din0   (din),
        .dout0  (dout),

        // Port 1 (Unused - Tied off safely to avoid floating gates)
        .clk1   (1'b0),
        .csb1   (1'b1),
        .addr1  (8'b00000000),
        .dout1  (unused_dout1)
    );

  `endif

endmodule