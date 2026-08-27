`timescale 1ns/1ns
//Test Logic Switch
module testbench;

  localparam int random_seed = 42;
  localparam int parallel_mems = 2;
  localparam int mem_sections = 8;
  localparam int fault_count = 128;
  localparam int disturb_count = 2;
  localparam int couple_count = 4;
  localparam int watch_depth = 3;
  localparam int addrW = 10;
  localparam int dataW = 64;

  localparam int mem_addrW = addrW - $clog2(mem_sections);

  integer          log_fd;
  reg              clk=1'b0;
  reg              nres=1'b0;

  reg              mem1_cs_n=1'b1;
  reg [addrW-1:0]  mem1_addr='0;
  reg              mem1_we_n=1'b1;
  reg [dataW-1:0]  mem1_bwe_n='1;
  reg [dataW-1:0]  mem1_din='0;
  reg              mem1_re_n=1'b1;
  wire [dataW-1:0] mem1_dout;

  reg              mem2_cs_n=1'b1;
  reg [addrW-1:0]  mem2_addr='0;
  reg              mem2_we_n=1'b1;
  reg [dataW-1:0]  mem2_bwe_n='1;
  reg [dataW-1:0]  mem2_din='0;
  reg              mem2_re_n=1'b1;
  wire [dataW-1:0] mem2_dout;

  reg              mem1_mbist_en=1'b0;
  wire             mem1_mbist_fault;
  wire       [4:0] mem1_mbist_fault_state;
  wire [addrW-1:0] mem1_mbist_fault_addr;
  wire [dataW-1:0] mem1_mbist_fault_data;
  wire [dataW-1:0] mem1_mbist_fault_dout;
  wire [dataW-1:0] mem1_mbist_fault_expc;

  reg              mem2_mbist_en=1'b0;
  wire             mem2_mbist_fault;
  wire       [4:0] mem2_mbist_fault_state;
  wire [addrW-1:0] mem2_mbist_fault_addr;
  wire [dataW-1:0] mem2_mbist_fault_data;
  wire [dataW-1:0] mem2_mbist_fault_dout;
  wire [dataW-1:0] mem2_mbist_fault_expc;
  
  // Instantiate Units Under Test
  top_model #(
      .parallel_mems(parallel_mems),
      .mem_sections(mem_sections),
      .fault_count(fault_count),
      .disturb_count(disturb_count),
      .couple_count(couple_count),
      .watch_depth(watch_depth),
      .addrW(addrW),
      .dataW(dataW)
    ) MEM (
    .log_fd(log_fd),
    .clk(clk),
    .nres(nres),
    //Mem1 Memory Port
    .mem1_cs_n(mem1_cs_n),
    .mem1_addr(mem1_addr),
    .mem1_we_n(mem1_we_n),
    .mem1_bwe_n(mem1_bwe_n),
    .mem1_din(mem1_din),
    .mem1_re_n(mem1_re_n),
    .mem1_dout(mem1_dout),
    //Mem2 Memory Port
    .mem2_cs_n(mem2_cs_n),
    .mem2_addr(mem2_addr),
    .mem2_we_n(mem2_we_n),
    .mem2_bwe_n(mem2_bwe_n),
    .mem2_din(mem2_din),
    .mem2_re_n(mem2_re_n),
    .mem2_dout(mem2_dout),
    //MEM1 MBIST Interface
    .mem1_mbist_en(mem1_mbist_en),
    .mem1_mbist_fault(mem1_mbist_fault),
    .mem1_mbist_fault_state(mem1_mbist_fault_state),
    .mem1_mbist_fault_addr(mem1_mbist_fault_addr),
    .mem1_mbist_fault_data(mem1_mbist_fault_data),
    .mem1_mbist_fault_dout(mem1_mbist_fault_dout),
    .mem1_mbist_fault_expc(mem1_mbist_fault_expc),
    //MEM1 MBIST Interface
    .mem2_mbist_en(mem2_mbist_en),
    .mem2_mbist_fault(mem2_mbist_fault),
    .mem2_mbist_fault_state(mem2_mbist_fault_state),
    .mem2_mbist_fault_addr(mem2_mbist_fault_addr),
    .mem2_mbist_fault_data(mem2_mbist_fault_data),
    .mem2_mbist_fault_dout(mem2_mbist_fault_dout),
    .mem2_mbist_fault_expc(mem2_mbist_fault_expc)
  );
  
  
  
  initial begin
    // Dump variables for editing
    $dumpfile("testbench.vcd");
    $dumpvars(7); //7 for just the baseline until FaultDB, 9 to include fault models, 0 for everything
    log_fd = $fopen("testbench.log");
    
    //Testbench Inputs
    #20 nres=1;

    #20 mem1_cs_n=0;
    #10 mem1_addr=0; mem1_we_n=0; mem1_bwe_n='0; mem1_din=64'h0000000000000000;
    #10 mem1_addr=1; mem1_we_n=0; mem1_bwe_n='0; mem1_din=64'h0101010101010101;
    #10 mem1_addr=2; mem1_we_n=0; mem1_bwe_n='0; mem1_din=64'h0202020202020202;
    #10 mem1_addr=3; mem1_we_n=0; mem1_bwe_n='0; mem1_din=64'h0303030303030303;
    #10 mem1_addr=0; mem1_we_n=1; mem1_bwe_n='1; mem1_din='0;
    #10 mem1_addr=0; mem1_re_n=0;
    #10 mem1_addr=1; mem1_re_n=0;
    #10 mem1_addr=2; mem1_re_n=0;
    #10 mem1_addr=3; mem1_re_n=0;
    #10 mem1_addr=0; mem1_re_n=1;
    #20 mem1_cs_n=1;

    #20 mem2_cs_n=0;
    #10 mem2_addr=0; mem2_we_n=0; mem2_bwe_n='0; mem2_din=64'h0000000000000000;
    #10 mem2_addr=1; mem2_we_n=0; mem2_bwe_n='0; mem2_din=64'h0101010101010101;
    #10 mem2_addr=2; mem2_we_n=0; mem2_bwe_n='0; mem2_din=64'h0202020202020202;
    #10 mem2_addr=3; mem2_we_n=0; mem2_bwe_n='0; mem2_din=64'h0303030303030303;
    #10 mem2_addr=0; mem2_we_n=1; mem2_bwe_n='1; mem2_din='0;
    #10 mem2_addr=0; mem2_re_n=0;
    #10 mem2_addr=1; mem2_re_n=0;
    #10 mem2_addr=2; mem2_re_n=0;
    #10 mem2_addr=3; mem2_re_n=0;
    #10 mem2_addr=0; mem2_re_n=1;
    #20 mem2_cs_n=1;

    #20 mem1_mbist_en=1; mem2_mbist_en=1;
    wait(MEM.MEM1.MBIST.mbist_state == 5'b00001); // wait for MBIST END state
    #20 mem1_mbist_en=0;
    wait(MEM.MEM2.MBIST.mbist_state == 5'b00001); // wait for MBIST END state
    #20 mem2_mbist_en=0;

    #10000;
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fdisplay(log_fd | 32'h1, "Simulation Finished.");
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fclose(log_fd);
    $finish;

  end

  initial begin
    @(posedge nres);
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fdisplay(log_fd | 32'h1, "[Fault Injection] %0d Faults Injected:", fault_count);
    @(posedge clk);
    @(negedge clk);
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fdisplay(log_fd | 32'h1, "Starting Simulation...");
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fflush(log_fd);
  end

  always @(posedge mem1_mbist_fault) begin
    #5;
    if (mem1_mbist_fault == 1'b1) begin
      $fdisplay(log_fd | 32'h1, "[MBIST1] t=%t | Fault at addr=0x%04h data=0x%08h state=0x%02h dout=0x%08h expc=0x%08h", $time, mem1_mbist_fault_addr + (0 << addrW), mem1_mbist_fault_data, mem1_mbist_fault_state, mem1_mbist_fault_dout, mem1_mbist_fault_expc);
      $fflush(log_fd);
    end
  end

  always @(posedge mem2_mbist_fault) begin
    #5;
    if (mem2_mbist_fault == 1'b1) begin
      $fdisplay(log_fd | 32'h1, "[MBIST2] t=%t | Fault at addr=0x%04h data=0x%08h state=0x%02h dout=0x%08h expc=0x%08h", $time, mem2_mbist_fault_addr + (1 << addrW), mem2_mbist_fault_data, mem2_mbist_fault_state, mem2_mbist_fault_dout, mem2_mbist_fault_expc);
      $fflush(log_fd);
    end
  end

  //Clock
  always
    #5 clk = ~clk;   // 100 Mhz clock
  
endmodule
