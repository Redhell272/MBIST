module memory_model
  #(
    parameter int fault_count = 16,  //GOTO: /faults_database
    parameter int random_seed = 42,  //GOTO: /faults_database
    parameter int disturb_count = 4, //GOTO: /faults_database/fault_model
    parameter int static_count = 16, //GOTO: /faults_database/fault_model
    parameter int watch_depth = 8,   //GOTO: /faults_database/fault_model
    parameter int addrW = 8,
    parameter int dataW = 32
  ) (
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
    output logic [dataW-1:0] dout,
    //MBIST Interface
    input  logic             mbist_en,
    output logic             mbist_fault,
    output logic [addrW-1:0] mbist_fault_addr,
    output logic [dataW-1:0] mbist_fault_data
  );
    
    logic             mem_cs_n;
    logic [addrW-1:0] mem_addr;
    logic             mem_we_n;
    logic [dataW-1:0] mem_bwe_n;
    logic [dataW-1:0] mem_din;
    logic             mem_re_n;
    logic [dataW-1:0] mem_dout;

    logic             mbist_cs_n;
    logic [addrW-1:0] mbist_addr;
    logic             mbist_we_n;
    logic [dataW-1:0] mbist_bwe_n;
    logic [dataW-1:0] mbist_din;
    logic             mbist_re_n;
    logic [dataW-1:0] mbist_dout;

    logic             mbist_sel;

    assign mem_cs_n   = mbist_sel ? mbist_cs_n   : cs_n;
    assign mem_addr   = mbist_sel ? mbist_addr   : addr;
    assign mem_we_n   = mbist_sel ? mbist_we_n   : we_n;
    assign mem_bwe_n  = mbist_sel ? mbist_bwe_n  : bwe_n;
    assign mem_din    = mbist_sel ? mbist_din    : din;
    assign mem_re_n   = mbist_sel ? mbist_re_n   : re_n;

    assign mbist_dout = mbist_sel ? mem_dout : '0;
    assign dout       = mbist_sel ? '0 : mem_dout;

    mbist #(

    ) MBIST (

    );

    fault_injection_wrapper #(
      .fault_count(fault_count),
      .random_seed(random_seed),
      .disturb_count(disturb_count),
      .static_count(static_count),
      .watch_depth(watch_depth),
      .addrW(addrW),
      .dataW(dataW)
    ) MEM (
      .clk(clk),
      .nres(nres),
      //Memory Port
      .cs_n(mem_cs_n),
      .addr(mem_addr),
      // Write
      .we_n(mem_we_n),
      .bwe_n(mem_bwe_n),
      .din(mem_din),
      // Read
      .re_n(mem_re_n),
      .dout(mem_dout)
    );

endmodule