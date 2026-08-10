module mbist
  #(
    parameter int addrW = 8,
    parameter int dataW = 32
  ) (
    input  logic clk,
    input  logic nres,
    //MBIST Interface
    input  logic             mbist_en,
    output logic [addrW-1:0] mbist_fault_addr,
    output logic [dataW-1:0] mbist_fault
    //Memory Port
    input  logic             cs_n,
    input  logic [addrW-1:0] addr,
    input  logic             we_n,
    input  logic [dataW-1:0] bwe_n,
    input  logic [dataW-1:0] din,
    input  logic             re_n,
    output logic [dataW-1:0] dout
  );

    //Registers

    //Wires

    //Assigns

    //Instances

    // Processes
  //------------------------------- Sequential ------------------------------

  //------------------------------ Combinational ----------------------------

endmodule