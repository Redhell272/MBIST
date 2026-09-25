`define SYNTHESIS
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

    `ifndef SYNTHESIS
    // ================================ SIMULATION TOP MODEL ================================

    //Simulation Logging
    input  integer log_fd,
    //MEM1 MBIST Interface
    input  logic                                    [4:0] mem1_mbist_mode,
    input  logic                       [mem_sections-1:0] mem1_mbist_en,
    output logic       [(mem_sections*parallel_mems)-1:0] mem1_mbist_fault,
    output logic     [(mem_sections*parallel_mems*8)-1:0] mem1_mbist_fault_state,
    output logic [(mem_sections*parallel_mems*addrW)-1:0] mem1_mbist_fault_addr,
    output logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_data,
    output logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_dout,
    output logic                       [mem_sections-1:0] mem1_mbist_done,
    //MEM2 MBIST Interface
    input  logic                                    [4:0] mem2_mbist_mode,
    input  logic                       [mem_sections-1:0] mem2_mbist_en,
    output logic       [(mem_sections*parallel_mems)-1:0] mem2_mbist_fault,
    output logic     [(mem_sections*parallel_mems*8)-1:0] mem2_mbist_fault_state,
    output logic [(mem_sections*parallel_mems*addrW)-1:0] mem2_mbist_fault_addr,
    output logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_data,
    output logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_dout,
    output logic                       [mem_sections-1:0] mem2_mbist_done
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
      .mbist_done(mem2_mbist_done)
    );

    `else
    // ================================ SYNTHESIS TOP MODEL ================================

    //Synthesis Power Pins
    inout  VPWR,
    inout  VGND,
    //MEM1 MBIST Interface
    input  logic                       [4:0] mem1_mbist_mode,
    input  logic                             mem1_mbist_en_C1,
    input  logic                             mem1_mbist_en_C2,
    input  logic                             mem1_mbist_en_C3,
    input  logic                             mem1_mbist_en_C4,
    input  logic                             mem1_mbist_en_C5,
    input  logic                             mem1_mbist_en_C6,
    input  logic                             mem1_mbist_en_C7,
    input  logic                             mem1_mbist_en_C8,
    output logic         [parallel_mems-1:0] mem1_mbist_fault_C1,
    output logic         [parallel_mems-1:0] mem1_mbist_fault_C2,
    output logic         [parallel_mems-1:0] mem1_mbist_fault_C3,
    output logic         [parallel_mems-1:0] mem1_mbist_fault_C4,
    output logic         [parallel_mems-1:0] mem1_mbist_fault_C5,
    output logic         [parallel_mems-1:0] mem1_mbist_fault_C6,
    output logic         [parallel_mems-1:0] mem1_mbist_fault_C7,
    output logic         [parallel_mems-1:0] mem1_mbist_fault_C8,
    output logic     [(parallel_mems*8)-1:0] mem1_mbist_fault_state_C1,
    output logic     [(parallel_mems*8)-1:0] mem1_mbist_fault_state_C2,
    output logic     [(parallel_mems*8)-1:0] mem1_mbist_fault_state_C3,
    output logic     [(parallel_mems*8)-1:0] mem1_mbist_fault_state_C4,
    output logic     [(parallel_mems*8)-1:0] mem1_mbist_fault_state_C5,
    output logic     [(parallel_mems*8)-1:0] mem1_mbist_fault_state_C6,
    output logic     [(parallel_mems*8)-1:0] mem1_mbist_fault_state_C7,
    output logic     [(parallel_mems*8)-1:0] mem1_mbist_fault_state_C8,
    output logic [(parallel_mems*addrW)-1:0] mem1_mbist_fault_addr_C1,
    output logic [(parallel_mems*addrW)-1:0] mem1_mbist_fault_addr_C2,
    output logic [(parallel_mems*addrW)-1:0] mem1_mbist_fault_addr_C3,
    output logic [(parallel_mems*addrW)-1:0] mem1_mbist_fault_addr_C4,
    output logic [(parallel_mems*addrW)-1:0] mem1_mbist_fault_addr_C5,
    output logic [(parallel_mems*addrW)-1:0] mem1_mbist_fault_addr_C6,
    output logic [(parallel_mems*addrW)-1:0] mem1_mbist_fault_addr_C7,
    output logic [(parallel_mems*addrW)-1:0] mem1_mbist_fault_addr_C8,
    output logic               [(dataW)-1:0] mem1_mbist_fault_data_C1,
    output logic               [(dataW)-1:0] mem1_mbist_fault_data_C2,
    output logic               [(dataW)-1:0] mem1_mbist_fault_data_C3,
    output logic               [(dataW)-1:0] mem1_mbist_fault_data_C4,
    output logic               [(dataW)-1:0] mem1_mbist_fault_data_C5,
    output logic               [(dataW)-1:0] mem1_mbist_fault_data_C6,
    output logic               [(dataW)-1:0] mem1_mbist_fault_data_C7,
    output logic               [(dataW)-1:0] mem1_mbist_fault_data_C8,
    output logic               [(dataW)-1:0] mem1_mbist_fault_dout_C1,
    output logic               [(dataW)-1:0] mem1_mbist_fault_dout_C2,
    output logic               [(dataW)-1:0] mem1_mbist_fault_dout_C3,
    output logic               [(dataW)-1:0] mem1_mbist_fault_dout_C4,
    output logic               [(dataW)-1:0] mem1_mbist_fault_dout_C5,
    output logic               [(dataW)-1:0] mem1_mbist_fault_dout_C6,
    output logic               [(dataW)-1:0] mem1_mbist_fault_dout_C7,
    output logic               [(dataW)-1:0] mem1_mbist_fault_dout_C8,
    output logic                             mem1_mbist_done_C1,
    output logic                             mem1_mbist_done_C2,
    output logic                             mem1_mbist_done_C3,
    output logic                             mem1_mbist_done_C4,
    output logic                             mem1_mbist_done_C5,
    output logic                             mem1_mbist_done_C6,
    output logic                             mem1_mbist_done_C7,
    output logic                             mem1_mbist_done_C8,
    //MEM2 MBIST Interface
    input  logic                       [4:0] mem2_mbist_mode,
    input  logic                             mem2_mbist_en_C1,
    input  logic                             mem2_mbist_en_C2,
    input  logic                             mem2_mbist_en_C3,
    input  logic                             mem2_mbist_en_C4,
    input  logic                             mem2_mbist_en_C5,
    input  logic                             mem2_mbist_en_C6,
    input  logic                             mem2_mbist_en_C7,
    input  logic                             mem2_mbist_en_C8,
    output logic         [parallel_mems-1:0] mem2_mbist_fault_C1,
    output logic         [parallel_mems-1:0] mem2_mbist_fault_C2,
    output logic         [parallel_mems-1:0] mem2_mbist_fault_C3,
    output logic         [parallel_mems-1:0] mem2_mbist_fault_C4,
    output logic         [parallel_mems-1:0] mem2_mbist_fault_C5,
    output logic         [parallel_mems-1:0] mem2_mbist_fault_C6,
    output logic         [parallel_mems-1:0] mem2_mbist_fault_C7,
    output logic         [parallel_mems-1:0] mem2_mbist_fault_C8,
    output logic     [(parallel_mems*8)-1:0] mem2_mbist_fault_state_C1,
    output logic     [(parallel_mems*8)-1:0] mem2_mbist_fault_state_C2,
    output logic     [(parallel_mems*8)-1:0] mem2_mbist_fault_state_C3,
    output logic     [(parallel_mems*8)-1:0] mem2_mbist_fault_state_C4,
    output logic     [(parallel_mems*8)-1:0] mem2_mbist_fault_state_C5,
    output logic     [(parallel_mems*8)-1:0] mem2_mbist_fault_state_C6,
    output logic     [(parallel_mems*8)-1:0] mem2_mbist_fault_state_C7,
    output logic     [(parallel_mems*8)-1:0] mem2_mbist_fault_state_C8,
    output logic [(parallel_mems*addrW)-1:0] mem2_mbist_fault_addr_C1,
    output logic [(parallel_mems*addrW)-1:0] mem2_mbist_fault_addr_C2,
    output logic [(parallel_mems*addrW)-1:0] mem2_mbist_fault_addr_C3,
    output logic [(parallel_mems*addrW)-1:0] mem2_mbist_fault_addr_C4,
    output logic [(parallel_mems*addrW)-1:0] mem2_mbist_fault_addr_C5,
    output logic [(parallel_mems*addrW)-1:0] mem2_mbist_fault_addr_C6,
    output logic [(parallel_mems*addrW)-1:0] mem2_mbist_fault_addr_C7,
    output logic [(parallel_mems*addrW)-1:0] mem2_mbist_fault_addr_C8,
    output logic               [(dataW)-1:0] mem2_mbist_fault_data_C1,
    output logic               [(dataW)-1:0] mem2_mbist_fault_data_C2,
    output logic               [(dataW)-1:0] mem2_mbist_fault_data_C3,
    output logic               [(dataW)-1:0] mem2_mbist_fault_data_C4,
    output logic               [(dataW)-1:0] mem2_mbist_fault_data_C5,
    output logic               [(dataW)-1:0] mem2_mbist_fault_data_C6,
    output logic               [(dataW)-1:0] mem2_mbist_fault_data_C7,
    output logic               [(dataW)-1:0] mem2_mbist_fault_data_C8,
    output logic               [(dataW)-1:0] mem2_mbist_fault_dout_C1,
    output logic               [(dataW)-1:0] mem2_mbist_fault_dout_C2,
    output logic               [(dataW)-1:0] mem2_mbist_fault_dout_C3,
    output logic               [(dataW)-1:0] mem2_mbist_fault_dout_C4,
    output logic               [(dataW)-1:0] mem2_mbist_fault_dout_C5,
    output logic               [(dataW)-1:0] mem2_mbist_fault_dout_C6,
    output logic               [(dataW)-1:0] mem2_mbist_fault_dout_C7,
    output logic               [(dataW)-1:0] mem2_mbist_fault_dout_C8,
    output logic                             mem2_mbist_done_C1,
    output logic                             mem2_mbist_done_C2,
    output logic                             mem2_mbist_done_C3,
    output logic                             mem2_mbist_done_C4,
    output logic                             mem2_mbist_done_C5,
    output logic                             mem2_mbist_done_C6,
    output logic                             mem2_mbist_done_C7,
    output logic                             mem2_mbist_done_C8
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
      .mbist_en({
        mem1_mbist_en_C1,
        mem1_mbist_en_C2,
        mem1_mbist_en_C3,
        mem1_mbist_en_C4,
        mem1_mbist_en_C5,
        mem1_mbist_en_C6,
        mem1_mbist_en_C7,
        mem1_mbist_en_C8
      }),
      .mbist_fault({
        mem1_mbist_fault_C1,
        mem1_mbist_fault_C2,
        mem1_mbist_fault_C3,
        mem1_mbist_fault_C4,
        mem1_mbist_fault_C5,
        mem1_mbist_fault_C6,
        mem1_mbist_fault_C7,
        mem1_mbist_fault_C8
      }),
      .mbist_fault_state({
        mem1_mbist_fault_state_C1,
        mem1_mbist_fault_state_C2,
        mem1_mbist_fault_state_C3,
        mem1_mbist_fault_state_C4,
        mem1_mbist_fault_state_C5,
        mem1_mbist_fault_state_C6,
        mem1_mbist_fault_state_C7,
        mem1_mbist_fault_state_C8
      }),
      .mbist_fault_addr({
        mem1_mbist_fault_addr_C1,
        mem1_mbist_fault_addr_C2,
        mem1_mbist_fault_addr_C3,
        mem1_mbist_fault_addr_C4,
        mem1_mbist_fault_addr_C5,
        mem1_mbist_fault_addr_C6,
        mem1_mbist_fault_addr_C7,
        mem1_mbist_fault_addr_C8
      }),
      .mbist_fault_data({
        mem1_mbist_fault_data_C1,
        mem1_mbist_fault_data_C2,
        mem1_mbist_fault_data_C3,
        mem1_mbist_fault_data_C4,
        mem1_mbist_fault_data_C5,
        mem1_mbist_fault_data_C6,
        mem1_mbist_fault_data_C7,
        mem1_mbist_fault_data_C8
      }),
      .mbist_fault_dout({
        mem1_mbist_fault_dout_C1,
        mem1_mbist_fault_dout_C2,
        mem1_mbist_fault_dout_C3,
        mem1_mbist_fault_dout_C4,
        mem1_mbist_fault_dout_C5,
        mem1_mbist_fault_dout_C6,
        mem1_mbist_fault_dout_C7,
        mem1_mbist_fault_dout_C8
      }),
      .mbist_done({
        mem1_mbist_done_C1,
        mem1_mbist_done_C2,
        mem1_mbist_done_C3,
        mem1_mbist_done_C4,
        mem1_mbist_done_C5,
        mem1_mbist_done_C6,
        mem1_mbist_done_C7,
        mem1_mbist_done_C8
      })
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
      .mbist_en({
        mem2_mbist_en_C1,
        mem2_mbist_en_C2,
        mem2_mbist_en_C3,
        mem2_mbist_en_C4,
        mem2_mbist_en_C5,
        mem2_mbist_en_C6,
        mem2_mbist_en_C7,
        mem2_mbist_en_C8
      }),
      .mbist_fault({
        mem2_mbist_fault_C1,
        mem2_mbist_fault_C2,
        mem2_mbist_fault_C3,
        mem2_mbist_fault_C4,
        mem2_mbist_fault_C5,
        mem2_mbist_fault_C6,
        mem2_mbist_fault_C7,
        mem2_mbist_fault_C8
      }),
      .mbist_fault_state({
        mem2_mbist_fault_state_C1,
        mem2_mbist_fault_state_C2,
        mem2_mbist_fault_state_C3,
        mem2_mbist_fault_state_C4,
        mem2_mbist_fault_state_C5,
        mem2_mbist_fault_state_C6,
        mem2_mbist_fault_state_C7,
        mem2_mbist_fault_state_C8
      }),
      .mbist_fault_addr({
        mem2_mbist_fault_addr_C1,
        mem2_mbist_fault_addr_C2,
        mem2_mbist_fault_addr_C3,
        mem2_mbist_fault_addr_C4,
        mem2_mbist_fault_addr_C5,
        mem2_mbist_fault_addr_C6,
        mem2_mbist_fault_addr_C7,
        mem2_mbist_fault_addr_C8
      }),
      .mbist_fault_data({
        mem2_mbist_fault_data_C1,
        mem2_mbist_fault_data_C2,
        mem2_mbist_fault_data_C3,
        mem2_mbist_fault_data_C4,
        mem2_mbist_fault_data_C5,
        mem2_mbist_fault_data_C6,
        mem2_mbist_fault_data_C7,
        mem2_mbist_fault_data_C8
      }),
      .mbist_fault_dout({
        mem2_mbist_fault_dout_C1,
        mem2_mbist_fault_dout_C2,
        mem2_mbist_fault_dout_C3,
        mem2_mbist_fault_dout_C4,
        mem2_mbist_fault_dout_C5,
        mem2_mbist_fault_dout_C6,
        mem2_mbist_fault_dout_C7,
        mem2_mbist_fault_dout_C8
      }),
      .mbist_done({
        mem2_mbist_done_C1,
        mem2_mbist_done_C2,
        mem2_mbist_done_C3,
        mem2_mbist_done_C4,
        mem2_mbist_done_C5,
        mem2_mbist_done_C6,
        mem2_mbist_done_C7,
        mem2_mbist_done_C8
      })
    );
    `endif

endmodule