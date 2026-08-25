module fault_injection_wrapper
  #(
    parameter int base_index = 0,    //GOTO: /faults_database
    parameter int mem_len = 64,      //GOTO: /faults_database
    parameter int fault_count = 16,  //GOTO: /faults_database
    parameter int disturb_count = 4, //GOTO: /faults_database/fault_model
    parameter int couple_count = 16, //GOTO: /faults_database/fault_model
    parameter int watch_depth = 8,   //GOTO: /faults_database/fault_model
    parameter int addrW = 8,
    parameter int dataW = 32
  ) (
    input  integer log_fd,
    input  logic clk,
    input  logic nres,
    //Memory Port
    input  logic             cs_n,
    input  logic [addrW-1:0] addr,
    // Write
    input  logic             we_n,
    input  logic [dataW-1:0] bwe_n,
    input  logic [dataW-1:0] din,
    // Read
    input  logic             re_n,
    output logic [dataW-1:0] dout
  );

`ifndef SYNTHESIS
    logic [dataW-1:0] data_in;
    logic [dataW-1:0] data_out;

    logic [dataW-1:0] fault_w;
    logic [dataW-1:0] fault_r;

    faults_database #(
      .base_index(base_index),
      .mem_len(mem_len),
      .fault_count(fault_count),
      .disturb_count(disturb_count),
      .couple_count(couple_count),
      .watch_depth(watch_depth),
      .addrW(addrW),
      .dataW(dataW)
    ) FaultDB (
      .log_fd(log_fd),
      .clk(clk),
      .nres(nres),
      //Memory Port
      .cs_n(cs_n),
      .addr(addr),
      .we_n(we_n),
      .bwe_n(bwe_n),
      .din(din),
      .re_n(re_n),
      // Fault Injection
      .fault_w(fault_w),
      .fault_r(fault_r),
      // Fault Return
      .mem_din(data_in),
      .mem_dout(dout)
    );

    fault_insert #(
      .dataW(dataW)
    ) WriteInsert (
      .i(din),
      .f(fault_w),
      .o(data_in)
    );

    sram #(
      .addrW(addrW),
      .dataW(dataW)
    ) SRAM (
      .clk(clk),
      .cs_n(cs_n),
      .addr(addr),
      // Write
      .we_n(we_n),
      .bwe_n(bwe_n),
      .din(data_in),
      // Read
      .re_n(re_n),
      .dout(data_out)
    );

    fault_insert #(
      .dataW(dataW)
    ) ReadInsert (
      .i(data_out),
      .f(fault_r),
      .o(dout)
    );

`else  // synthesis: bare SRAM, no fault injection logic

    sram #(
      .addrW(addrW),
      .dataW(dataW)
    ) SRAM (
      .clk(clk),
      .cs_n(cs_n),
      .addr(addr),
      // Write
      .we_n(we_n),
      .bwe_n(bwe_n),
      .din(din),
      // Read
      .re_n(re_n),
      .dout(dout)
    );

`endif

endmodule



module fault_insert
  #(
    parameter int dataW = 32
  ) (
    input  logic [dataW-1:0] i,
    input  logic [dataW-1:0] f,
    output logic [dataW-1:0] o
  );

    // Apply fault injection by bitmask inversion (XOR)
    assign o = i ^ f;

endmodule