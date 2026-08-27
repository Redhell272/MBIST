module full_model
  #(
    parameter int parallel_mems = 2, //GOTO: /memory_model
    parameter int mem_sections = 8,  //GOTO: /memory_model
    parameter int fault_count = 64,  //GOTO: /faults_database
    parameter int disturb_count = 4, //GOTO: /faults_database/fault_model
    parameter int couple_count = 16, //GOTO: /faults_database/fault_model
    parameter int watch_depth = 8,   //GOTO: /faults_database/fault_model
    parameter int addrW = 13,
    parameter int dataW = 64
  ) (
    input  integer log_fd,
    input  logic clk,
    input  logic nres,
    //MEM1 Memory Port
    input  logic             mem1_cs_n,
    input  logic [addrW-1:0] mem1_addr,
    input  logic             mem1_we_n,
    input  logic [dataW-1:0] mem1_bwe_n,
    input  logic [dataW-1:0] mem1_din,
    input  logic             mem1_re_n,
    output logic [dataW-1:0] mem1_dout,
    //MEM2 Memory Port
    input  logic             mem2_cs_n,
    input  logic [addrW-1:0] mem2_addr,
    input  logic             mem2_we_n,
    input  logic [dataW-1:0] mem2_bwe_n,
    input  logic [dataW-1:0] mem2_din,
    input  logic             mem2_re_n,
    output logic [dataW-1:0] mem2_dout,
    //MEM1 MBIST Interface
    input  logic             mem1_mbist_en,
    output logic             mem1_mbist_fault,
    output logic       [4:0] mem1_mbist_fault_state,
    output logic [addrW-1:0] mem1_mbist_fault_addr,
    output logic [dataW-1:0] mem1_mbist_fault_data,
    output logic [dataW-1:0] mem1_mbist_fault_dout,
    output logic [dataW-1:0] mem1_mbist_fault_expc,
    //MEM2 MBIST Interface
    input  logic             mem2_mbist_en,
    output logic             mem2_mbist_fault,
    output logic       [4:0] mem2_mbist_fault_state,
    output logic [addrW-1:0] mem2_mbist_fault_addr,
    output logic [dataW-1:0] mem2_mbist_fault_data,
    output logic [dataW-1:0] mem2_mbist_fault_dout,
    output logic [dataW-1:0] mem2_mbist_fault_expc
  );

    memory_model #(
      .base_index(0),
      .mem_len(fault_count),
      .parallel_mems(parallel_mems),
      .mem_sections(mem_sections),
      .fault_count(fault_count/2),
      .disturb_count(disturb_count),
      .couple_count(couple_count),
      .watch_depth(watch_depth),
      .addrW(addrW),
      .dataW(dataW)
    ) MEM1 (
      .log_fd(log_fd),
      .clk(clk),
      .nres(nres),
      //Memory Port
      .cs_n(mem1_cs_n),
      .addr(mem1_addr),
      // Write
      .we_n(mem1_we_n),
      .bwe_n(mem1_bwe_n),
      .din(mem1_din),
      // Read
      .re_n(mem1_re_n),
      .dout(mem1_dout),
      //MBIST Interface
      .mbist_en(mem1_mbist_en),
      .mbist_fault(mem1_mbist_fault),
      .mbist_fault_state(mem1_mbist_fault_state),
      .mbist_fault_addr(mem1_mbist_fault_addr),
      .mbist_fault_data(mem1_mbist_fault_data),
      .mbist_fault_dout(mem1_mbist_fault_dout),
      .mbist_fault_expc(mem1_mbist_fault_expc)
    );

    memory_model #(
      .base_index(parallel_mems*mem_sections),
      .mem_len(fault_count),
      .parallel_mems(parallel_mems),
      .mem_sections(mem_sections),
      .fault_count(fault_count/2),
      .disturb_count(disturb_count),
      .couple_count(couple_count),
      .watch_depth(watch_depth),
      .addrW(addrW),
      .dataW(dataW)
    ) MEM2 (
      .log_fd(log_fd),
      .clk(clk),
      .nres(nres),
      //Memory Port
      .cs_n(mem2_cs_n),
      .addr(mem2_addr),
      // Write
      .we_n(mem2_we_n),
      .bwe_n(mem2_bwe_n),
      .din(mem2_din),
      // Read
      .re_n(mem2_re_n),
      .dout(mem2_dout),
      //MBIST Interface
      .mbist_en(mem2_mbist_en),
      .mbist_fault(mem2_mbist_fault),
      .mbist_fault_state(mem2_mbist_fault_state),
      .mbist_fault_addr(mem2_mbist_fault_addr),
      .mbist_fault_data(mem2_mbist_fault_data),
      .mbist_fault_dout(mem2_mbist_fault_dout),
      .mbist_fault_expc(mem2_mbist_fault_expc)
    );

endmodule