interface axi_if(input logic clk, input logic rst_n);
  import axi_crossbar_pkg::*;

  logic [ID_WIDTH-1:0]   m0_awid, m1_awid;
  logic [ADDR_WIDTH-1:0] m0_awaddr, m1_awaddr;
  logic [LEN_WIDTH-1:0]  m0_awlen, m1_awlen;
  logic [SIZE_WIDTH-1:0] m0_awsize, m1_awsize;
  logic [1:0]            m0_awburst, m1_awburst;
  logic                  m0_awvalid, m1_awvalid, m0_awready, m1_awready;

  logic [DATA_WIDTH-1:0] m0_wdata, m1_wdata;
  logic [STRB_WIDTH-1:0] m0_wstrb, m1_wstrb;
  logic                  m0_wlast, m1_wlast, m0_wvalid, m1_wvalid, m0_wready, m1_wready;

  logic [ID_WIDTH-1:0]   m0_bid, m1_bid;
  logic [1:0]            m0_bresp, m1_bresp;
  logic                  m0_bvalid, m1_bvalid, m0_bready, m1_bready;

  logic [ID_WIDTH-1:0]   m0_arid, m1_arid;
  logic [ADDR_WIDTH-1:0] m0_araddr, m1_araddr;
  logic [LEN_WIDTH-1:0]  m0_arlen, m1_arlen;
  logic [SIZE_WIDTH-1:0] m0_arsize, m1_arsize;
  logic [1:0]            m0_arburst, m1_arburst;
  logic                  m0_arvalid, m1_arvalid, m0_arready, m1_arready;

  logic [ID_WIDTH-1:0]   m0_rid, m1_rid;
  logic [DATA_WIDTH-1:0] m0_rdata, m1_rdata;
  logic [1:0]            m0_rresp, m1_rresp;
  logic                  m0_rlast, m1_rlast, m0_rvalid, m1_rvalid, m0_rready, m1_rready;

  logic [ID_WIDTH_S-1:0] s0_awid, s1_awid;
  logic [ADDR_WIDTH-1:0] s0_awaddr, s1_awaddr;
  logic [LEN_WIDTH-1:0]  s0_awlen, s1_awlen;
  logic [SIZE_WIDTH-1:0] s0_awsize, s1_awsize;
  logic [1:0]            s0_awburst, s1_awburst;
  logic                  s0_awvalid, s1_awvalid, s0_awready, s1_awready;

  logic [DATA_WIDTH-1:0] s0_wdata, s1_wdata;
  logic [STRB_WIDTH-1:0] s0_wstrb, s1_wstrb;
  logic                  s0_wlast, s1_wlast, s0_wvalid, s1_wvalid, s0_wready, s1_wready;

  logic [ID_WIDTH_S-1:0] s0_bid, s1_bid;
  logic [1:0]            s0_bresp, s1_bresp;
  logic                  s0_bvalid, s1_bvalid, s0_bready, s1_bready;

  logic [ID_WIDTH_S-1:0] s0_arid, s1_arid;
  logic [ADDR_WIDTH-1:0] s0_araddr, s1_araddr;
  logic [LEN_WIDTH-1:0]  s0_arlen, s1_arlen;
  logic [SIZE_WIDTH-1:0] s0_arsize, s1_arsize;
  logic [1:0]            s0_arburst, s1_arburst;
  logic                  s0_arvalid, s1_arvalid, s0_arready, s1_arready;

  logic [ID_WIDTH_S-1:0] s0_rid, s1_rid;
  logic [DATA_WIDTH-1:0] s0_rdata, s1_rdata;
  logic [1:0]            s0_rresp, s1_rresp;
  logic                  s0_rlast, s1_rlast, s0_rvalid, s1_rvalid, s0_rready, s1_rready;

  // Testbench-controlled backpressure signals
  int s0_aw_stall_cycles, s0_w_stall_cycles, s0_ar_stall_cycles, s0_r_delay_cycles;
  int s1_aw_stall_cycles, s1_w_stall_cycles, s1_ar_stall_cycles, s1_r_delay_cycles;
  int m0_b_stall_cycles,  m1_b_stall_cycles,  m0_r_stall_cycles,  m1_r_stall_cycles;
endinterface

