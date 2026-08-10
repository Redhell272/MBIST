module fault_model
  #(
    parameter int disturb_count = 4, //Number of disturb aggressor addresses to watch
    parameter int static_count = 16, //Number of static aggressor addresses to be tracked
    parameter int watch_depth = 8,   //Number of registered accesses per watched address
    parameter int dataAddrW = 13,    //Address width including the bits to specify a single bit in the data word (addrW + log2(dataW))
    parameter int addrW = 8,
    parameter int dataW = 32
  ) (
    input  logic clk,
    input  logic nres,
    //Memory Port
    input  logic             cs_n,
    input  logic [addrW-1:0] addr,
    input  logic             we_n,
    input  logic [dataW-1:0] bwe_n,
    input  logic [dataW-1:0] din,
    input  logic             re_n,
    //Fault Coding
    input  logic                 fault_primitive,
    input  logic [dataAddrW-1:0] fault_addr,
    //Fault Injection
    output logic [dataW-1:0] fault_w,
    output logic [dataW-1:0] fault_r
  );

    //Registers
    reg fault_reg;
    reg fault_read_d;

    //Wires
    logic fault_dataAddr;
    logic fault_bitmask;

    logic fault_din;
    logic fault_access;
    logic fault_write;
    logic fault_read;

    logic overwrite_w;
    logic overwrite_r;

    //Assigns
    assign fault_dataAddr = fault_addr[dataAddrW-1:addrW];
    assign fault_bitmask = 1 << fault_dataAddr;

    assign fault_din = din[fault_dataAddr];
    assign fault_access = (addr == fault_addr[addrW-1:0]) && !cs_n;
    assign fault_write = fault_access && !we_n && !bwe_n[fault_dataAddr];
    assign fault_read = fault_access && !re_n;

    assign overwrite_w = fault_write && (fault_din != fault_reg);
    assign overwrite_r = fault_read_d && (fault_reg != fault_primitive);

    assign fault_w = overwrite_w ? fault_bitmask : '0;
    assign fault_r = '0;

    //Instances

    // Processes
  //------------------------------- Sequential ------------------------------
    always @(negedge clk or negedge nres)
    begin
      if (nres == 0) begin
        fault_read_d <= 1'b0;
        fault_reg <= fault_primitive;
      end else begin
        fault_read_d <= fault_read;
        if (fault_write && !overwrite_w) begin
          fault_reg <= fault_din;
        end
      end
    end

  //------------------------------ Combinational ----------------------------

endmodule