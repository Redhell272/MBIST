module memory_model
  #(
    parameter int base_index = 0,    //Base index for labelling and offsets
    parameter int mem_len = 64,      //Length of .mem files
    parameter int parallel_mems = 2, //Number of parallel memories per section
    parameter int mem_sections = 8,  //Number of memory sections
    parameter int fault_count = 64,  //GOTO: /faults_database
    parameter int disturb_count = 4, //GOTO: /faults_database/fault_model
    parameter int couple_count = 16, //GOTO: /faults_database/fault_model
    parameter int watch_depth = 8,   //GOTO: /faults_database/fault_model
    parameter int addrW = 13,
    parameter int dataW = 64
  ) (
    `ifndef SYNTHESIS
    input  integer log_fd,
    `endif
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
    input  logic                                    [3:0] mbist_mode,
    input  logic                       [mem_sections-1:0] mbist_en,
    output logic       [(mem_sections*parallel_mems)-1:0] mbist_fault,
    output logic     [(mem_sections*parallel_mems*8)-1:0] mbist_fault_state,
    output logic [(mem_sections*parallel_mems*addrW)-1:0] mbist_fault_addr,
    output logic               [(mem_sections*dataW)-1:0] mbist_fault_data,
    output logic               [(mem_sections*dataW)-1:0] mbist_fault_dout,
    output logic                       [mem_sections-1:0] mbist_done
  );

    localparam int mem_fault_count = fault_count/(parallel_mems*mem_sections);
    localparam int mem_sectW = $clog2(mem_sections);
    localparam int mem_addrW = addrW - mem_sectW;
    localparam int mem_dataW = dataW/parallel_mems;

    logic cs_n_array [mem_sections-1:0];
    logic [dataW-1:0] dout_array [mem_sections-1:0];
    logic [dataW-1:0] sect_dout;

    assign dout = sect_dout;

    // Memory Sections
    genvar x,y;
    generate
      for (x = 0; x < mem_sections; x = x + 1) begin : mem_sect
        // Chip Select Decoder
        assign cs_n_array[x] = (addr[addrW-1:mem_addrW] == x) ? cs_n : 1'b1;
    
        logic                 mem_cs_n;
        logic [mem_addrW-1:0] mem_addr;
        logic                 mem_we_n;
        logic     [dataW-1:0] mem_bwe_n;
        logic     [dataW-1:0] mem_din;
        logic                 mem_re_n;
        logic     [dataW-1:0] mem_dout;

        logic                 mbist_cs_n;
        logic [mem_addrW-1:0] mbist_addr;
        logic                 mbist_we_n;
        logic     [dataW-1:0] mbist_bwe_n;
        logic     [dataW-1:0] mbist_din;
        logic                 mbist_re_n;
        logic     [dataW-1:0] mbist_dout;

        logic                 mbist_sel;

        assign mem_cs_n   = mbist_sel ? mbist_cs_n   : cs_n_array[x];
        assign mem_addr   = mbist_sel ? mbist_addr   : addr[mem_addrW-1:0];
        assign mem_we_n   = mbist_sel ? mbist_we_n   : we_n;
        assign mem_bwe_n  = mbist_sel ? mbist_bwe_n  : bwe_n;
        assign mem_din    = mbist_sel ? mbist_din    : din;
        assign mem_re_n   = mbist_sel ? mbist_re_n   : re_n;

        assign mbist_dout = mbist_sel ? mem_dout : '0;

        assign dout_array[x] = mbist_sel ? '0 : mem_dout;

        mbist #(
          .base_index(base_index+parallel_mems*x),
          .parallel_mems(parallel_mems),
          .mem_addrW(mem_addrW),
          .mem_dataW(mem_dataW),
          .addrW(addrW),
          .dataW(dataW)
        ) MBIST (
          .clk(clk),
          .nres(nres),
          //MBIST Interface
          .mbist_mode(mbist_mode),
          .mbist_en(mbist_en[x]),
          .mbist_sel(mbist_sel),
          .mbist_fault(mbist_fault[                (parallel_mems*(x+1))-1:(parallel_mems*x)]),
          .mbist_fault_state(mbist_fault_state[  (parallel_mems*8*(x+1))-1:(parallel_mems*8*x)]),
          .mbist_fault_addr(mbist_fault_addr[(parallel_mems*addrW*(x+1))-1:(parallel_mems*addrW*x)]),
          .mbist_fault_data(mbist_fault_data[              (dataW*(x+1))-1:(dataW*x)]),
          .mbist_fault_dout(mbist_fault_dout[              (dataW*(x+1))-1:(dataW*x)]),
          .mbist_done(mbist_done[x]),
          //Memory Port
          .cs_n(mbist_cs_n),
          .addr(mbist_addr),
          .we_n(mbist_we_n),
          .bwe_n(mbist_bwe_n),
          .din(mbist_din),
          .re_n(mbist_re_n),
          .dout(mbist_dout)
        );

        // Parallel Memories with individual MBIST
        for (y = 0; y < parallel_mems; y = y + 1) begin : mem_inst

          fault_injection_wrapper #(
            .base_index(base_index+parallel_mems*x+y),
            .mem_len(mem_len),
            .parallel_mems(parallel_mems),
            .fault_count(mem_fault_count),
            .disturb_count(disturb_count),
            .couple_count(couple_count),
            .watch_depth(watch_depth),
            .addrW(mem_addrW),
            .dataW(mem_dataW)
          ) MEM (
            `ifndef SYNTHESIS
            .log_fd(log_fd),
            `endif
            .clk(clk),
            .nres(nres),
            //Memory Port
            .cs_n(mem_cs_n),
            .addr(mem_addr),
            // Write
            .we_n(mem_we_n),
            .bwe_n(mem_bwe_n[(mem_dataW*(y+1))-1:(mem_dataW*y)]),
            .din(mem_din[(mem_dataW*(y+1))-1:(mem_dataW*y)]),
            // Read
            .re_n(mem_re_n),
            .dout(mem_dout[(mem_dataW*(y+1))-1:(mem_dataW*y)])
          );
        end
      end
    endgenerate

    // Memory Section Output Mux
    always @(*) begin
      sect_dout = '0;
      for (int i = 0; i < mem_sections; i++) begin
        if (addr[addrW-1:mem_addrW] == i)
          sect_dout = dout_array[i];
      end
    end

endmodule