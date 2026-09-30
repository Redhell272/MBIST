`timescale 1ns/1ns

//Test top_model memory model
//iverilog -g2012 -o "testbench.out" "mbist\sources\fault_injection_wrapper.sv" "mbist\sources\faults_database.sv" "mbist\sources\sram.sv" "mbist\sources\mbist.sv" "mbist\sources\memory_model.sv" "mbist\sources\top_model.sv" "mbist\sources\tb_memory_model.sv"
//vvp "testbench.out" +mem_dir=MBIST/Sources -fst
//gtkwave .\testbench.fst

module testbench;

  localparam int mbist_mode = 5'b01101;

  localparam int fault_count = 2048;
  localparam int random_seed = 42;
  localparam int parallel_mems = 2;
  localparam int mem_sections = 8;
  localparam int disturb_count = 2;
  localparam int couple_count = 4;
  localparam int watch_depth = 3;
  localparam int addrW = 13;
  localparam int dataW = 64;

  localparam int mem_addrW = addrW - $clog2(mem_sections);
  localparam int mem_dataW = dataW/parallel_mems;

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

  reg                                     [4:0] mem1_mbist_mode=mbist_mode;
  reg                        [mem_sections-1:0] mem1_mbist_en='0;
  wire       [(mem_sections*parallel_mems)-1:0] mem1_mbist_fault;
  wire     [(mem_sections*parallel_mems*8)-1:0] mem1_mbist_fault_state;
  wire [(mem_sections*parallel_mems*addrW)-1:0] mem1_mbist_fault_addr;
  wire               [(mem_sections*dataW)-1:0] mem1_mbist_fault_data;
  wire               [(mem_sections*dataW)-1:0] mem1_mbist_fault_dout;
  wire                       [mem_sections-1:0] mem1_mbist_done;

  reg                                     [4:0] mem2_mbist_mode=mbist_mode;
  reg                        [mem_sections-1:0] mem2_mbist_en='0;
  wire       [(mem_sections*parallel_mems)-1:0] mem2_mbist_fault;
  wire     [(mem_sections*parallel_mems*8)-1:0] mem2_mbist_fault_state;
  wire [(mem_sections*parallel_mems*addrW)-1:0] mem2_mbist_fault_addr;
  wire               [(mem_sections*dataW)-1:0] mem2_mbist_fault_data;
  wire               [(mem_sections*dataW)-1:0] mem2_mbist_fault_dout;
  wire                       [mem_sections-1:0] mem2_mbist_done;
  
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
    .mem1_mbist_mode(mem1_mbist_mode),
    .mem1_mbist_en(mem1_mbist_en), 
    .mem1_mbist_fault(mem1_mbist_fault),
    .mem1_mbist_fault_state(mem1_mbist_fault_state),
    .mem1_mbist_fault_addr(mem1_mbist_fault_addr),
    .mem1_mbist_fault_data(mem1_mbist_fault_data),
    .mem1_mbist_fault_dout(mem1_mbist_fault_dout),
    .mem1_mbist_done(mem1_mbist_done),
    //MEM2 MBIST Interface
    .mem2_mbist_mode(mem2_mbist_mode),
    .mem2_mbist_en(mem2_mbist_en), 
    .mem2_mbist_fault(mem2_mbist_fault),
    .mem2_mbist_fault_state(mem2_mbist_fault_state),
    .mem2_mbist_fault_addr(mem2_mbist_fault_addr),
    .mem2_mbist_fault_data(mem2_mbist_fault_data),
    .mem2_mbist_fault_dout(mem2_mbist_fault_dout),
    .mem2_mbist_done(mem2_mbist_done)
  );
  
  
  
  initial begin
    // Dump variables for editing
    $dumpfile("testbench.fst");
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

    #20 mem1_mbist_en='1; mem2_mbist_en='1;
    wait(mem1_mbist_done == '1); // wait for MEM1 MBIST
    #20 mem1_mbist_en='0;
    wait(mem2_mbist_done == '1); // wait for MEM2 MBIST
    #20 mem2_mbist_en='0;

    #10000;
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fdisplay(log_fd | 32'h1, "Simulation Finished.");
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fclose(log_fd);
    $finish;

  end

  initial begin
    @(posedge nres);
    `ifndef SYNTHESIS
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fdisplay(log_fd | 32'h1, "[Fault Injection] %0d Faults Injected:", fault_count);
    @(posedge clk);
    @(negedge clk);
    `endif
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fdisplay(log_fd | 32'h1, "Starting Simulation...");
    $fdisplay(log_fd | 32'h1, "================================================================");
    $fflush(log_fd);
  end

  genvar x,y;
  generate
    for (x = 0; x < mem_sections*parallel_mems; x = x + 1) begin : fault_logging_mem1

      wire                 fault;
      wire           [7:0] fault_state;
      wire     [addrW-1:0] fault_addr;
      wire [mem_dataW-1:0] fault_data;
      wire [mem_dataW-1:0] fault_dout;

      assign fault = mem1_mbist_fault[x];
      assign fault_state = mem1_mbist_fault_state[(8*(x+1)-1):(8*x)];
      assign fault_addr  = mem1_mbist_fault_addr[(addrW*(x+1)-1):(addrW*x)];
      assign fault_data  = mem1_mbist_fault_data[(mem_dataW*(x+1)-1):(mem_dataW*x)];
      assign fault_dout  = mem1_mbist_fault_dout[(mem_dataW*(x+1)-1):(mem_dataW*x)];

      always @(posedge fault) begin
        #5;
        if (fault == 1'b1) begin
          $fdisplay(log_fd | 32'h1, "[MBIST1-%02d] t=%t | Fault at state=0x%02h addr=0x%08h data=0x%016h dout=0x%016h", x, $time, fault_state, fault_addr + (0 << addrW), fault_data, fault_dout);
          $fflush(log_fd);
        end
      end
    end

    for (y = 0; y < mem_sections*parallel_mems; y = y + 1) begin : fault_logging_mem2

      wire                 fault;
      wire           [7:0] fault_state;
      wire     [addrW-1:0] fault_addr;
      wire [mem_dataW-1:0] fault_data;
      wire [mem_dataW-1:0] fault_dout;

      assign fault = mem2_mbist_fault[y];
      assign fault_state = mem2_mbist_fault_state[(8*(y+1)-1):(8*y)];
      assign fault_addr  = mem2_mbist_fault_addr[(addrW*(y+1)-1):(addrW*y)];
      assign fault_data  = mem2_mbist_fault_data[(mem_dataW*(y+1)-1):(mem_dataW*y)];
      assign fault_dout  = mem2_mbist_fault_dout[(mem_dataW*(y+1)-1):(mem_dataW*y)];

      always @(posedge fault) begin
        #5;
        if (fault == 1'b1) begin
          $fdisplay(log_fd | 32'h1, "[MBIST2-%02d] t=%t | Fault at state=0x%02h addr=0x%08h data=0x%016h dout=0x%016h", y, $time, fault_state, fault_addr + (1 << addrW), fault_data, fault_dout);
          $fflush(log_fd);
        end
      end
    end
  endgenerate

  //Clock
  always
    #5 clk = ~clk;   // 100 Mhz clock
  
endmodule
