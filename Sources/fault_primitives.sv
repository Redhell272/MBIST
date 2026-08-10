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
    input  logic                 cs_n,
    input  logic     [addrW-1:0] addr,
    input  logic                 we_n,
    input  logic [(dataW/8)-1:0] bwe_n,
    input  logic     [dataW-1:0] din,
    input  logic                 re_n,
    //Fault Coding
    input  logic                 fault_primitive,
    input  logic [dataAddrW-1:0] fault_addr,
    //Fault Injection
    output logic [dataW-1:0] fault_w,
    output logic [dataW-1:0] fault_r
  );

    //Registers

    //Wires

    //Assigns

    //Instances

    // Processes
  //------------------------------- Sequential ------------------------------

  //------------------------------ Combinational ----------------------------

endmodule