`timescale 1ns/1ns
//Test Logic Switch
module testbench;

  localparam int random_seed = 42;
  localparam int parallel_mems = 2;
  localparam int mem_sections = 8;
  localparam int fault_count = 64;
  localparam int disturb_count = 2;
  localparam int couple_count = 4;
  localparam int watch_depth = 3;
  localparam int addrW = 10;
  localparam int dataW = 64;

  localparam int mem_addrW = addrW - $clog2(mem_sections);

  reg clk=1'b0;
  reg nres=1'b0;
  reg cs_n=1'b1;
  reg [addrW-1:0] addr='0;
  reg we_n=1'b1;
  reg [dataW-1:0] bwe_n='1;
  reg [dataW-1:0] din='0;
  reg re_n=1'b1;
  wire [dataW-1:0] dout;
  reg mbist_en=1'b0;
  wire mbist_fault;
  wire       [4:0] mbist_fault_state;
  wire [addrW-1:0] mbist_fault_addr;
  wire [dataW-1:0] mbist_fault_data;
  wire [dataW-1:0] mbist_fault_dout;
  wire [dataW-1:0] mbist_fault_expc;
  integer log_fd;
  
  // Instantiate Units Under Test
  memory_model #(
      .base_index(0),
      .parallel_mems(parallel_mems),
      .mem_sections(mem_sections),
      .fault_count(fault_count),
      .disturb_count(disturb_count),
      .couple_count(couple_count),
      .watch_depth(watch_depth),
      .addrW(addrW),
      .dataW(dataW)
    ) MEM0 (
    .log_fd(log_fd),
    .clk(clk),
    .nres(nres),
    //Memory Port
    .cs_n(cs_n),
    .addr(addr),
    // Write
    .we_n(we_n),
    .bwe_n(bwe_n),
    .din(din),
    // Read
    .re_n(re_n),
    .dout(dout),
    //MBIST Interface
    .mbist_en(mbist_en),
    .mbist_fault(mbist_fault),
    .mbist_fault_state(mbist_fault_state),
    .mbist_fault_addr(mbist_fault_addr),
    .mbist_fault_data(mbist_fault_data),
    .mbist_fault_dout(mbist_fault_dout),
    .mbist_fault_expc(mbist_fault_expc)
  );
  
  
  
  initial begin
    // Dump variables for editing
    $dumpfile("testbench.vcd");
    $dumpvars(6); //6 for just the baseline until FaultDB, 8 to include fault models, 0 for everything
    log_fd = $fopen("testbench.log");
    
    //Testbench Inputs
    #20 nres=1;

    #20 cs_n=0;
    #10 addr=0; we_n=0; bwe_n='0; din=64'h0000000000000000;
    #10 addr=1; we_n=0; bwe_n='0; din=64'h0101010101010101;
    #10 addr=2; we_n=0; bwe_n='0; din=64'h0202020202020202;
    #10 addr=3; we_n=0; bwe_n='0; din=64'h0303030303030303;
    #10 addr=0; we_n=1; bwe_n='1; din='0;
    #10 addr=0; re_n=0;
    #10 addr=1; re_n=0;
    #10 addr=2; re_n=0;
    #10 addr=3; re_n=0;
    #10 addr=0; re_n=1;
    #20 cs_n=1;

    #20 mbist_en=1;
    wait(MEM0.MBIST.mbist_state == 5'b00001); // wait for MBIST END state
    #20 mbist_en=0;

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

  always @(posedge mbist_fault) begin
    #5;
    if (mbist_fault == 1'b1) begin
      $fdisplay(log_fd | 32'h1, "[MBIST] t=%t | Fault at addr=0x%03h data=0x%08h state=0x%02h dout=0x%08h expc=0x%08h", $time, mbist_fault_addr, mbist_fault_data, mbist_fault_state, mbist_fault_dout, mbist_fault_expc);
      $fflush(log_fd);
    end
  end

  //Clock
  always
    #5 clk = ~clk;   // 100 Mhz clock
  
endmodule
