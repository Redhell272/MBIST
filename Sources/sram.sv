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
    input  logic                 re_n,
    output logic [dataW-1:0] dout
  );

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

endmodule