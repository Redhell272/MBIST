`timescale 1ns/1ps
//Test Logic Switch
module testbench;

  localparam int fault_count = 16;
  localparam int random_seed = 42;
  localparam int disturb_count = 4;
  localparam int static_count = 16;
  localparam int watch_depth = 8;
  localparam int addrW = 8;
  localparam int dataW = 32;

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
  wire [addrW-1:0] mbist_fault_addr;
  wire [dataW-1:0] mbist_fault_data;
  wire [dataW-1:0] mbist_fault_dout;
  wire [dataW-1:0] mbist_fault_expc;
  
  // Instantiate Units Under Test
  memory_model #(
      .fault_count(fault_count),
      .random_seed(random_seed),
      .disturb_count(disturb_count),
      .static_count(static_count),
      .watch_depth(watch_depth),
      .addrW(addrW),
      .dataW(dataW)
    ) DUT (
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
    .mbist_fault_addr(mbist_fault_addr),
    .mbist_fault_data(mbist_fault_data),
    .mbist_fault_dout(mbist_fault_dout),
    .mbist_fault_expc(mbist_fault_expc)
  );
  
  
  
  initial begin
    // Dump variables for editing
    $dumpfile("testbench.vcd");
    $dumpvars();
    
    //Testbench Inputs
    #20 nres=1;

    #20 cs_n=0;
    #10 addr=8'h00; we_n=0; bwe_n=32'h00000000; din=32'h00000000;
    #10 addr=8'h01; we_n=0; bwe_n=32'h00000000; din=32'h01010101;
    #10 addr=8'h02; we_n=0; bwe_n=32'h00000000; din=32'h02020202;
    #10 addr=8'h03; we_n=0; bwe_n=32'h00000000; din=32'h03030303;
    #10 addr=8'h00; we_n=1; bwe_n=32'hFFFFFFFF; din=32'h00000000;
    #10 addr=8'h00; re_n=0;
    #10 addr=8'h01; re_n=0;
    #10 addr=8'h02; re_n=0;
    #10 addr=8'h03; re_n=0;
    #10 addr=8'h00; re_n=1;
    #20 cs_n=1;

    #20 mbist_en=1;
    #0820000 mbist_en=0;

  end

  initial begin
    @(posedge nres);
    $display("================================================================");
    $display("[Fault Injection] %0d Faults Injected:", fault_count);
    for (int i = 0; i < fault_count; i++) begin
      $display("  [%02d] addr=0x%02h bit=0x%02h primitive=0x%0h",
        i,
        DUT.MEM.FaultDB.fault_addr_list[i][addrW-1:0],
        DUT.MEM.FaultDB.fault_addr_list[i] >> addrW,
        DUT.MEM.FaultDB.fault_primitive_list[i]);
    end
    $display("================================================================");
    $display("Starting Simulation...");
    $display("================================================================");
  end
  
  always @(posedge mbist_fault)
    #5 $display("[MBIST] Fault at addr=0x%02h data=0x%08h dout=0x%08h expec=0x%08h", mbist_fault_addr, mbist_fault_data, mbist_fault_dout, mbist_fault_expc);

  //Clocks
  always
    #5 clk = ~clk;   // 100 Mhz clock
  
  //Simulation Runtime
  initial begin
    #1000000;
    $display("================================================================");
    $display("Simulation Finished.");
    $display("================================================================");
    $finish;
  end
  
endmodule
