module top_model
  #(
    parameter int pipeline_stages = 2,  //Number of pipeline stages in input/output signal paths, for decreased routing pressure
    parameter int parallel_mems = 2,    //GOTO: /memory_model
    parameter int mem_sections = 8,     //GOTO: /memory_model
    parameter int fault_count = 64,     //GOTO: /faults_database
    parameter int disturb_count = 4,    //GOTO: /faults_database/fault_model
    parameter int couple_count = 16,    //GOTO: /faults_database/fault_model
    parameter int watch_depth = 8,      //GOTO: /faults_database/fault_model
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
    input  logic                       [mem_sections-1:0] mem1_mbist_en,
    output logic       [(mem_sections*parallel_mems)-1:0] mem1_mbist_fault,
    output logic     [(mem_sections*parallel_mems*5)-1:0] mem1_mbist_fault_state,
    output logic [(mem_sections*parallel_mems*addrW)-1:0] mem1_mbist_fault_addr,
    output logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_data,
    output logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_dout,
    output logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_expc,
    output logic                       [mem_sections-1:0] mem1_mbist_done,
    //MEM2 MBIST Interface
    input  logic                       [mem_sections-1:0] mem2_mbist_en,
    output logic       [(mem_sections*parallel_mems)-1:0] mem2_mbist_fault,
    output logic     [(mem_sections*parallel_mems*5)-1:0] mem2_mbist_fault_state,
    output logic [(mem_sections*parallel_mems*addrW)-1:0] mem2_mbist_fault_addr,
    output logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_data,
    output logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_dout,
    output logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_expc,
    output logic                       [mem_sections-1:0] mem2_mbist_done
  );

    //MEM1 Memory Port
    logic             mem1_cs_n_d;
    logic [addrW-1:0] mem1_addr_d;
    logic             mem1_we_n_d;
    logic [dataW-1:0] mem1_bwe_n_d;
    logic [dataW-1:0] mem1_din_d;
    logic             mem1_re_n_d;
    logic [dataW-1:0] mem1_dout_d;
    //MEM2 Memory Port
    logic             mem2_cs_n_d;
    logic [addrW-1:0] mem2_addr_d;
    logic             mem2_we_n_d;
    logic [dataW-1:0] mem2_bwe_n_d;
    logic [dataW-1:0] mem2_din_d;
    logic             mem2_re_n_d;
    logic [dataW-1:0] mem2_dout_d;
    //MEM1 MBIST Interface
    logic                       [mem_sections-1:0] mem1_mbist_en_d;
    logic       [(mem_sections*parallel_mems)-1:0] mem1_mbist_fault_d;
    logic     [(mem_sections*parallel_mems*5)-1:0] mem1_mbist_fault_state_d;
    logic [(mem_sections*parallel_mems*addrW)-1:0] mem1_mbist_fault_addr_d;
    logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_data_d;
    logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_dout_d;
    logic               [(mem_sections*dataW)-1:0] mem1_mbist_fault_expc_d;
    logic                       [mem_sections-1:0] mem1_mbist_done_d;
    //MEM2 MBIST Interface
    logic                       [mem_sections-1:0] mem2_mbist_en_d;
    logic       [(mem_sections*parallel_mems)-1:0] mem2_mbist_fault_d;
    logic     [(mem_sections*parallel_mems*5)-1:0] mem2_mbist_fault_state_d;
    logic [(mem_sections*parallel_mems*addrW)-1:0] mem2_mbist_fault_addr_d;
    logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_data_d;
    logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_dout_d;
    logic               [(mem_sections*dataW)-1:0] mem2_mbist_fault_expc_d;
    logic                       [mem_sections-1:0] mem2_mbist_done_d;

    localparam int pl = pipeline_stages;
    //MEM1 Memory Port
    ppln #(.s(pl), .w(1))      mem1_cs_n_ppln  (.c(clk), .n(nres), .i(mem1_cs_n),  .o(mem1_cs_n_d),  .r('1));
    ppln #(.s(pl), .w(addrW))  mem1_addr_ppln  (.c(clk), .n(nres), .i(mem1_addr),  .o(mem1_addr_d),  .r('0));
    ppln #(.s(pl), .w(1))      mem1_we_n_ppln  (.c(clk), .n(nres), .i(mem1_we_n),  .o(mem1_we_n_d),  .r('1));
    ppln #(.s(pl), .w(dataW))  mem1_bwe_n_ppln (.c(clk), .n(nres), .i(mem1_bwe_n), .o(mem1_bwe_n_d), .r('1));
    ppln #(.s(pl), .w(dataW))  mem1_din_ppln   (.c(clk), .n(nres), .i(mem1_din),   .o(mem1_din_d),   .r('0));
    ppln #(.s(pl), .w(1))      mem1_re_n_ppln  (.c(clk), .n(nres), .i(mem1_re_n),  .o(mem1_re_n_d),  .r('1));
    ppln #(.s(pl), .w(dataW))  mem1_dout_ppln  (.c(clk), .n(nres), .i(mem1_dout_d),  .o(mem1_dout),  .r('0));
    //MEM2 Memory Port
    ppln #(.s(pl), .w(1))      mem2_cs_n_ppln  (.c(clk), .n(nres), .i(mem2_cs_n),  .o(mem2_cs_n_d),  .r('1));
    ppln #(.s(pl), .w(addrW))  mem2_addr_ppln  (.c(clk), .n(nres), .i(mem2_addr),  .o(mem2_addr_d),  .r('0));
    ppln #(.s(pl), .w(1))      mem2_we_n_ppln  (.c(clk), .n(nres), .i(mem2_we_n),  .o(mem2_we_n_d),  .r('1));
    ppln #(.s(pl), .w(dataW))  mem2_bwe_n_ppln (.c(clk), .n(nres), .i(mem2_bwe_n), .o(mem2_bwe_n_d), .r('1));
    ppln #(.s(pl), .w(dataW))  mem2_din_ppln   (.c(clk), .n(nres), .i(mem2_din),   .o(mem2_din_d),   .r('0));
    ppln #(.s(pl), .w(1))      mem2_re_n_ppln  (.c(clk), .n(nres), .i(mem2_re_n),  .o(mem2_re_n_d),  .r('1));
    ppln #(.s(pl), .w(dataW))  mem2_dout_ppln  (.c(clk), .n(nres), .i(mem2_dout_d),  .o(mem2_dout),  .r('0));
    //MEM1 MBIST Interface
    ppln #(.s(pl), .w(mem_sections))                      mem1_mbist_en_ppln          (.c(clk), .n(nres), .i(mem1_mbist_en),            .o(mem1_mbist_en_d),        .r('0));
    ppln #(.s(pl), .w(mem_sections*parallel_mems))        mem1_mbist_fault_ppln       (.c(clk), .n(nres), .i(mem1_mbist_fault_d),       .o(mem1_mbist_fault),       .r('0));
    ppln #(.s(pl), .w(mem_sections*parallel_mems*5))      mem1_mbist_fault_state_ppln (.c(clk), .n(nres), .i(mem1_mbist_fault_state_d), .o(mem1_mbist_fault_state), .r('0));
    ppln #(.s(pl), .w(mem_sections*parallel_mems*addrW))  mem1_mbist_fault_addr_ppln  (.c(clk), .n(nres), .i(mem1_mbist_fault_addr_d),  .o(mem1_mbist_fault_addr),  .r('0));
    ppln #(.s(pl), .w(mem_sections*dataW))                mem1_mbist_fault_data_ppln  (.c(clk), .n(nres), .i(mem1_mbist_fault_data_d),  .o(mem1_mbist_fault_data),  .r('0));
    ppln #(.s(pl), .w(mem_sections*dataW))                mem1_mbist_fault_dout_ppln  (.c(clk), .n(nres), .i(mem1_mbist_fault_dout_d),  .o(mem1_mbist_fault_dout),  .r('0));
    ppln #(.s(pl), .w(mem_sections*dataW))                mem1_mbist_fault_expc_ppln  (.c(clk), .n(nres), .i(mem1_mbist_fault_expc_d),  .o(mem1_mbist_fault_expc),  .r('0));
    ppln #(.s(pl), .w(mem_sections))                      mem1_mbist_done_ppln        (.c(clk), .n(nres), .i(mem1_mbist_done_d),        .o(mem1_mbist_done),        .r('0));
    //MEM2 MBIST Interface
    ppln #(.s(pl), .w(mem_sections))                      mem2_mbist_en_ppln          (.c(clk), .n(nres), .i(mem2_mbist_en),            .o(mem2_mbist_en_d),        .r('0));
    ppln #(.s(pl), .w(mem_sections*parallel_mems))        mem2_mbist_fault_ppln       (.c(clk), .n(nres), .i(mem2_mbist_fault_d),       .o(mem2_mbist_fault),       .r('0));
    ppln #(.s(pl), .w(mem_sections*parallel_mems*5))      mem2_mbist_fault_state_ppln (.c(clk), .n(nres), .i(mem2_mbist_fault_state_d), .o(mem2_mbist_fault_state), .r('0));
    ppln #(.s(pl), .w(mem_sections*parallel_mems*addrW))  mem2_mbist_fault_addr_ppln  (.c(clk), .n(nres), .i(mem2_mbist_fault_addr_d),  .o(mem2_mbist_fault_addr),  .r('0));
    ppln #(.s(pl), .w(mem_sections*dataW))                mem2_mbist_fault_data_ppln  (.c(clk), .n(nres), .i(mem2_mbist_fault_data_d),  .o(mem2_mbist_fault_data),  .r('0));
    ppln #(.s(pl), .w(mem_sections*dataW))                mem2_mbist_fault_dout_ppln  (.c(clk), .n(nres), .i(mem2_mbist_fault_dout_d),  .o(mem2_mbist_fault_dout),  .r('0));
    ppln #(.s(pl), .w(mem_sections*dataW))                mem2_mbist_fault_expc_ppln  (.c(clk), .n(nres), .i(mem2_mbist_fault_expc_d),  .o(mem2_mbist_fault_expc),  .r('0));
    ppln #(.s(pl), .w(mem_sections))                      mem2_mbist_done_ppln        (.c(clk), .n(nres), .i(mem2_mbist_done_d),        .o(mem2_mbist_done),        .r('0));

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
      .log_fd(log_fd),
      .clk(clk),
      .nres(nres),
      //Memory Port
      .cs_n(mem1_cs_n_d),
      .addr(mem1_addr_d),
      // Write
      .we_n(mem1_we_n_d),
      .bwe_n(mem1_bwe_n_d),
      .din(mem1_din_d),
      // Read
      .re_n(mem1_re_n_d),
      .dout(mem1_dout_d),
      //MBIST Interface
      .mbist_en(mem1_mbist_en_d),
      .mbist_fault(mem1_mbist_fault_d),
      .mbist_fault_state(mem1_mbist_fault_state_d),
      .mbist_fault_addr(mem1_mbist_fault_addr_d),
      .mbist_fault_data(mem1_mbist_fault_data_d),
      .mbist_fault_dout(mem1_mbist_fault_dout_d),
      .mbist_fault_expc(mem1_mbist_fault_expc_d),
      .mbist_done(mem1_mbist_done_d)
    );

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
      .log_fd(log_fd),
      .clk(clk),
      .nres(nres),
      //Memory Port
      .cs_n(mem2_cs_n_d),
      .addr(mem2_addr_d),
      // Write
      .we_n(mem2_we_n_d),
      .bwe_n(mem2_bwe_n_d),
      .din(mem2_din_d),
      // Read
      .re_n(mem2_re_n_d),
      .dout(mem2_dout_d),
      //MBIST Interface
      .mbist_en(mem2_mbist_en_d),
      .mbist_fault(mem2_mbist_fault_d),
      .mbist_fault_state(mem2_mbist_fault_state_d),
      .mbist_fault_addr(mem2_mbist_fault_addr_d),
      .mbist_fault_data(mem2_mbist_fault_data_d),
      .mbist_fault_dout(mem2_mbist_fault_dout_d),
      .mbist_fault_expc(mem2_mbist_fault_expc_d),
      .mbist_done(mem2_mbist_done_d)
    );

endmodule



module ppln
#(
  parameter int s = 4,    //Number of pipeline stages
  parameter int w = 32    //Line width of the data bus
) (
  input  logic c,         //clk
  input  logic n,         //nres
  input  logic [w-1:0] i, //Pipeline input
  output logic [w-1:0] o, //Pipeline output
  input  logic [w-1:0] r  //Reset value for pipeline stage registers
);

  generate
    if (s <= 0) begin
      assign o = i;

    end else begin

      reg [w-1:0] stage [s:0];

      assign stage[0] = i;
      assign o = stage[s];

      genvar x;
      for (x = 1; x <= s; x++) begin : stage_loop
        always_ff @(posedge c or negedge n) begin
          if (n == 0) begin
            stage[x] <= r;
          end else begin
            stage[x] <= stage[x-1];
          end
        end
      end
    end
  endgenerate
endmodule