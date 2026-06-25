module write_path
  import axi_crossbar_pkg::*;

(

  input logic   clk,
  input logic   rst_n,

  //Master 0
  //AW
  input  logic [ID_WIDTH-1:0]   m0_awid,
  input  logic [ADDR_WIDTH-1:0] m0_awaddr,
  input  logic [LEN_WIDTH-1:0]  m0_awlen,
  input  logic [SIZE_WIDTH-1:0] m0_awsize,
  input  logic [1:0]            m0_awburst,
  input  logic                  m0_awvalid,
  output logic                  m0_awready,
  // W
  input  logic [DATA_WIDTH-1:0] m0_wdata,
  input  logic [STRB_WIDTH-1:0] m0_wstrb,
  input  logic                  m0_wlast,
  input  logic                  m0_wvalid,
  output logic                  m0_wready,
  // B
  output logic [ID_WIDTH-1:0]   m0_bid,
  output logic [1:0]            m0_bresp,
  output logic                  m0_bvalid,
  input  logic                  m0_bready,
 

  //Master 1
  //AW
  input  logic [ID_WIDTH-1:0]   m1_awid,
  input  logic [ADDR_WIDTH-1:0] m1_awaddr,
  input  logic [LEN_WIDTH-1:0]  m1_awlen,
  input  logic [SIZE_WIDTH-1:0] m1_awsize,
  input  logic [1:0]            m1_awburst,
  input  logic                  m1_awvalid,
  output logic                  m1_awready,
  // W
  input  logic [DATA_WIDTH-1:0] m1_wdata,
  input  logic [STRB_WIDTH-1:0] m1_wstrb,
  input  logic                  m1_wlast,
  input  logic                  m1_wvalid,
  output logic                  m1_wready,
  // B
  output logic [ID_WIDTH-1:0]   m1_bid,
  output logic [1:0]            m1_bresp,
  output logic                  m1_bvalid,
  input  logic                  m1_bready,



  //Slave 0
  // AW
  output logic [ID_WIDTH_S-1:0] s0_awid,
  output logic [ADDR_WIDTH-1:0] s0_awaddr,
  output logic [LEN_WIDTH-1:0]  s0_awlen,
  output logic [SIZE_WIDTH-1:0] s0_awsize,
  output logic [1:0]            s0_awburst,
  output logic                  s0_awvalid,
  input  logic                  s0_awready,
  // W
  output logic [DATA_WIDTH-1:0] s0_wdata,
  output logic [STRB_WIDTH-1:0] s0_wstrb,
  output logic                  s0_wlast,
  output logic                  s0_wvalid,
  input  logic                  s0_wready,
  // B
  input  logic [ID_WIDTH_S-1:0] s0_bid,
  input  logic [1:0]            s0_bresp,
  input  logic                  s0_bvalid,
  output logic                  s0_bready,
 
  //Slave 1
  // AW
  output logic [ID_WIDTH_S-1:0] s1_awid,
  output logic [ADDR_WIDTH-1:0] s1_awaddr,
  output logic [LEN_WIDTH-1:0]  s1_awlen,
  output logic [SIZE_WIDTH-1:0] s1_awsize,
  output logic [1:0]            s1_awburst,
  output logic                  s1_awvalid,
  input  logic                  s1_awready,
  // W
  output logic [DATA_WIDTH-1:0] s1_wdata,
  output logic [STRB_WIDTH-1:0] s1_wstrb,
  output logic                  s1_wlast,
  output logic                  s1_wvalid,
  input  logic                  s1_wready,
  // B
  input  logic [ID_WIDTH_S-1:0] s1_bid,
  input  logic [1:0]            s1_bresp,
  input  logic                  s1_bvalid,
  output logic                  s1_bready
  );
 
  // Internal wires between submodules
 
  // AW channel to  W channel (order tracker)
  logic [10:0] m0_worder_data, m1_worder_data;
  logic        m0_worder_valid, m1_worder_valid;
  logic        m0_worder_ready, m1_worder_ready;
 


  //dummy slave AW port
  logic [ID_WIDTH_S-1:0] dm_awid;
  logic [ADDR_WIDTH-1:0] dm_awaddr;
  logic [LEN_WIDTH-1:0]  dm_awlen;
  logic [SIZE_WIDTH-1:0] dm_awsize;
  logic [1:0]            dm_awburst;
  logic                  dm_awvalid;
  logic                  dm_awready;
 
  // Dummy slave W port
  logic [DATA_WIDTH-1:0] dm_wdata;
  logic [STRB_WIDTH-1:0] dm_wstrb;
  logic                  dm_wlast;
  logic                  dm_wvalid;
  logic                  dm_wready;
 
  //Dummy slave B channel
  logic [ID_WIDTH_S-1:0] dm_bid;
  logic [1:0]            dm_bresp;
  logic                  dm_bvalid;
  logic                  dm_bready;

  
  // AW channel instance
  aw_channel u_aw_channel (
        .clk             (clk),
        .rst_n           (rst_n),
        // M0
        .m0_awid         (m0_awid),
        .m0_awaddr       (m0_awaddr),
        .m0_awlen        (m0_awlen),
        .m0_awsize       (m0_awsize),
        .m0_awburst      (m0_awburst),
        .m0_awvalid      (m0_awvalid),
        .m0_awready      (m0_awready),
        // M1
        .m1_awid         (m1_awid),
        .m1_awaddr       (m1_awaddr),
        .m1_awlen        (m1_awlen),
        .m1_awsize       (m1_awsize),
        .m1_awburst      (m1_awburst),
        .m1_awvalid      (m1_awvalid),
        .m1_awready      (m1_awready),
        // S0
        .s0_awid         (s0_awid),
        .s0_awaddr       (s0_awaddr),
        .s0_awlen        (s0_awlen),
        .s0_awsize       (s0_awsize),
        .s0_awburst      (s0_awburst),
        .s0_awvalid      (s0_awvalid),
        .s0_awready      (s0_awready),
        // S1
        .s1_awid         (s1_awid),
        .s1_awaddr       (s1_awaddr),
        .s1_awlen        (s1_awlen),
        .s1_awsize       (s1_awsize),
        .s1_awburst      (s1_awburst),
        .s1_awvalid      (s1_awvalid),
        .s1_awready      (s1_awready),
        // Dummy slave AW
        .dm_awid         (dm_awid),
        .dm_awaddr       (dm_awaddr),
        .dm_awlen        (dm_awlen),
        .dm_awsize       (dm_awsize),
        .dm_awburst      (dm_awburst),
        .dm_awvalid      (dm_awvalid),
        .dm_awready      (dm_awready),
        // W order tracker
        .m0_worder_data  (m0_worder_data),
        .m0_worder_valid (m0_worder_valid),
        .m0_worder_ready (m0_worder_ready),
        .m1_worder_data  (m1_worder_data),
        .m1_worder_valid (m1_worder_valid),
        .m1_worder_ready (m1_worder_ready)
  );

  // W channel instance
  w_channel u_w_channel (
        .clk             (clk),
        .rst_n           (rst_n),
        // M0
        .m0_wdata        (m0_wdata),
        .m0_wstrb        (m0_wstrb),
        .m0_wlast        (m0_wlast),
        .m0_wvalid       (m0_wvalid),
        .m0_wready       (m0_wready),
        // M1
        .m1_wdata        (m1_wdata),
        .m1_wstrb        (m1_wstrb),
        .m1_wlast        (m1_wlast),
        .m1_wvalid       (m1_wvalid),
        .m1_wready       (m1_wready),
        // Order tracker from AW channel
        .m0_worder_data  (m0_worder_data),
        .m0_worder_valid (m0_worder_valid),
        .m0_worder_ready (m0_worder_ready),
        .m1_worder_data  (m1_worder_data),
        .m1_worder_valid (m1_worder_valid),
        .m1_worder_ready (m1_worder_ready),
        // S0
        .s0_wdata        (s0_wdata),
        .s0_wstrb        (s0_wstrb),
        .s0_wlast        (s0_wlast),
        .s0_wvalid       (s0_wvalid),
        .s0_wready       (s0_wready),
        // S1
        .s1_wdata        (s1_wdata),
        .s1_wstrb        (s1_wstrb),
        .s1_wlast        (s1_wlast),
        .s1_wvalid       (s1_wvalid),
        .s1_wready       (s1_wready),
        // Dummy slave W
        .dm_wdata        (dm_wdata),
        .dm_wstrb        (dm_wstrb),
        .dm_wlast        (dm_wlast),
        .dm_wvalid       (dm_wvalid),
        .dm_wready       (dm_wready)
  );


  // Dummy slave instance
  // Handles DECERR: drains W beats, returns BRESP=DECERR
  
  aw_dummy_slave u_dummy_slave (
        .clk        (clk),
        .rst_n      (rst_n),
        // AW from aw_channel
        .s_awid     (dm_awid),
        .s_awaddr   (dm_awaddr),
        .s_awlen    (dm_awlen),
        .s_awsize   (dm_awsize),
        .s_awburst  (dm_awburst),
        .s_awvalid  (dm_awvalid),
        .s_awready  (dm_awready),
        // W from w_channel
        .s_wdata    (dm_wdata),
        .s_wstrb    (dm_wstrb),
        .s_wlast    (dm_wlast),
        .s_wvalid   (dm_wvalid),
        .s_wready   (dm_wready),
        // B to b_channel
        .s_bid      (dm_bid),
        .s_bresp    (dm_bresp),
        .s_bvalid   (dm_bvalid),
        .s_bready   (dm_bready)
  );


  // B channel instance
  // Routes B responses from S0, S1, Dummy back to correct master
  b_channel u_b_channel (
        .clk        (clk),
        .rst_n      (rst_n),
        // S0 B
        .s0_bid     (s0_bid),
        .s0_bresp   (s0_bresp),
        .s0_bvalid  (s0_bvalid),
        .s0_bready  (s0_bready),
        // S1 B
        .s1_bid     (s1_bid),
        .s1_bresp   (s1_bresp),
        .s1_bvalid  (s1_bvalid),
        .s1_bready  (s1_bready),
        // Dummy B
        .dm_bid     (dm_bid),
        .dm_bresp   (dm_bresp),
        .dm_bvalid  (dm_bvalid),
        .dm_bready  (dm_bready),
        // M0 B
        .m0_bid     (m0_bid),
        .m0_bresp   (m0_bresp),
        .m0_bvalid  (m0_bvalid),
        .m0_bready  (m0_bready),
        // M1 B
        .m1_bid     (m1_bid),
        .m1_bresp   (m1_bresp),
        .m1_bvalid  (m1_bvalid),
        .m1_bready  (m1_bready)
  );

endmodule








































