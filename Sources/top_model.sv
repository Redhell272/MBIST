module top_model
  #(
    parameter int parallel_mems = 2,    //GOTO: /memory_model
    parameter int mem_sections = 8,     //GOTO: /memory_model
    parameter int fault_count = 64,     //GOTO: /faults_database
    parameter int disturb_count = 4,    //GOTO: /faults_database/fault_model
    parameter int couple_count = 16,    //GOTO: /faults_database/fault_model
    parameter int watch_depth = 8,      //GOTO: /faults_database/fault_model
    parameter int addrW = 13,
    parameter int dataW = 64
  ) (
    `ifndef SYNTHESIS
    //Simulation Logging
    input  integer log_fd,
    `else
    //Power Synthesis
    input  logic VDD,
    input  logic GND,
    `endif
    input  logic clk,
    input  logic nres,
    //MEM1 Memory Port
    (* keep, dont_touch = "true" *) input  logic             mem1_cs_n,
    (* keep, dont_touch = "true" *) input  logic [addrW-1:0] mem1_addr,
    (* keep, dont_touch = "true" *) input  logic             mem1_we_n,
    (* keep, dont_touch = "true" *) input  logic [dataW-1:0] mem1_bwe_n,
    (* keep, dont_touch = "true" *) input  logic [dataW-1:0] mem1_din,
    (* keep, dont_touch = "true" *) input  logic             mem1_re_n,
    (* keep, dont_touch = "true" *) output logic [dataW-1:0] mem1_dout,
    //MEM2 Memory Port
    (* keep, dont_touch = "true" *) input  logic             mem2_cs_n,
    (* keep, dont_touch = "true" *) input  logic [addrW-1:0] mem2_addr,
    (* keep, dont_touch = "true" *) input  logic             mem2_we_n,
    (* keep, dont_touch = "true" *) input  logic [dataW-1:0] mem2_bwe_n,
    (* keep, dont_touch = "true" *) input  logic [dataW-1:0] mem2_din,
    (* keep, dont_touch = "true" *) input  logic             mem2_re_n,
    (* keep, dont_touch = "true" *) output logic [dataW-1:0] mem2_dout,
    //MEM1 MBIST Interface
    (* keep, dont_touch = "true" *) input  logic                                    [3:0] mem1_mbist_mode,
    (* keep, dont_touch = "true" *) input  logic                       [mem_sections-1:0] mem1_mbist_en,
    (* keep, dont_touch = "true" *) output logic       [(mem_sections*parallel_mems)-1:0] mem1_mbist_fault,
    (* keep, dont_touch = "true" *) output logic     [(mem_sections*parallel_mems*8)-1:0] mem1_mbist_fault_state,
    (* keep, dont_touch = "true" *) output logic [(mem_sections*parallel_mems*addrW)-1:0] mem1_mbist_fault_addr,
    (* keep, dont_touch = "true" *) output logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_data,
    (* keep, dont_touch = "true" *) output logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_dout,
    (* keep, dont_touch = "true" *) output logic       [(mem_sections*parallel_mems)-1:0] mem1_mbist_fault_expc,
    (* keep, dont_touch = "true" *) output logic                       [mem_sections-1:0] mem1_mbist_done,
    //MEM2 MBIST Interface
    (* keep, dont_touch = "true" *) input  logic                                    [3:0] mem2_mbist_mode,
    (* keep, dont_touch = "true" *) input  logic                       [mem_sections-1:0] mem2_mbist_en,
    (* keep, dont_touch = "true" *) output logic       [(mem_sections*parallel_mems)-1:0] mem2_mbist_fault,
    (* keep, dont_touch = "true" *) output logic     [(mem_sections*parallel_mems*8)-1:0] mem2_mbist_fault_state,
    (* keep, dont_touch = "true" *) output logic [(mem_sections*parallel_mems*addrW)-1:0] mem2_mbist_fault_addr,
    (* keep, dont_touch = "true" *) output logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_data,
    (* keep, dont_touch = "true" *) output logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_dout,
    (* keep, dont_touch = "true" *) output logic       [(mem_sections*parallel_mems)-1:0] mem2_mbist_fault_expc,
    (* keep, dont_touch = "true" *) output logic                       [mem_sections-1:0] mem2_mbist_done
  );

    //MEM1 Instance
    memory_model #(
      .base_index(parallel_mems*mem_sections*0),
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
      `ifndef SYNTHESIS
      .log_fd(log_fd),
      `endif
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
      .mbist_mode(mem1_mbist_mode),
      .mbist_en(mem1_mbist_en),
      .mbist_fault(mem1_mbist_fault),
      .mbist_fault_state(mem1_mbist_fault_state),
      .mbist_fault_addr(mem1_mbist_fault_addr),
      .mbist_fault_data(mem1_mbist_fault_data),
      .mbist_fault_dout(mem1_mbist_fault_dout),
      .mbist_fault_expc(mem1_mbist_fault_expc),
      .mbist_done(mem1_mbist_done)
    );

    //MEM2 Instance
    memory_model #(
      .base_index(parallel_mems*mem_sections*1),
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
      `ifndef SYNTHESIS
      .log_fd(log_fd),
      `endif
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
      .mbist_mode(mem2_mbist_mode),
      .mbist_en(mem2_mbist_en),
      .mbist_fault(mem2_mbist_fault),
      .mbist_fault_state(mem2_mbist_fault_state),
      .mbist_fault_addr(mem2_mbist_fault_addr),
      .mbist_fault_data(mem2_mbist_fault_data),
      .mbist_fault_dout(mem2_mbist_fault_dout),
      .mbist_fault_expc(mem2_mbist_fault_expc),
      .mbist_done(mem2_mbist_done)
    );

endmodule