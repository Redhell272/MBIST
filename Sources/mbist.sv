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
    output logic             cs_n,
    output logic [addrW-1:0] addr,
    output logic             we_n,
    output logic [dataW-1:0] bwe_n,
    output logic [dataW-1:0] din,
    output logic             re_n,
    input  logic [dataW-1:0] dout
  );

    //Registers

    //Wires

    //Assigns

    //Instances

    // Processes
  //------------------------------- Sequential ------------------------------

  //------------------------------ Combinational ----------------------------

endmodule