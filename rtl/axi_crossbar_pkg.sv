package axi_crossbar_pkg;
  

  //Bus Widths
  localparam  int   ADDR_WIDTH = 32;
  localparam  int   DATA_WIDTH = 32;
  localparam  int   ID_WIDTH   = 4;
  localparam  int   ID_WIDTH_S = 5;
  localparam  int   LEN_WIDTH  = 8;         //AWLEN
  localparam  int   SIZE_WIDTH = 3;         //AWSIZE        
  localparam  int   STRB_WIDTH = DATA_WIDTH / 8;
  localparam  int   AWBURST    = 2;

  //FIFO DEPTH- Write path
  localparam  int   AW_FIFO_DEPTH  = 8;
  localparam  int   W_FIFO_DEPTH   = 16;
  localparam  int   ORD_FIFO_DEPTH = 8;
  localparam  int   B_FIFO_DEPTH   = 8;

  //FIFO DEPTH- Read path
  localparam  int AR_FIFO_DEPTH  = 8;
  localparam  int R_FIFO_DEPTH   = 16;
  localparam  int OSTND_DEPTH    = 16;


  //AW packet width packed into FIFO
  

  localparam  int   AW_PKT_WIDTH = ID_WIDTH + ADDR_WIDTH + LEN_WIDTH + SIZE_WIDTH + AWBURST;

  //slave facing AW packet

  localparam  int   AW_PKT_S_WIDTH = ID_WIDTH_S + ADDR_WIDTH + LEN_WIDTH + SIZE_WIDTH + AWBURST;

  //AR FIFO packet
  localparam int    AR_PKT_WIDTH = ID_WIDTH + ADDR_WIDTH + LEN_WIDTH + SIZE_WIDTH + 2;

  // R fifo packet
  localparam int    R_PKT_WIDTH = ID_WIDTH_S + DATA_WIDTH + 2 + 1;



  //target slave 

  typedef enum logic [1:0] {

    TARGET_S0     = 2'b00,
    TARGET_S1     = 2'b01,
    TARGET_DEC    = 2'b10
  } target_slave_e;

  //AXI RESPONSE CODE
  localparam  logic [1:0]   RESP_OKAY   = 2'b00;
  localparam  logic [1:0]   RESP_DECERR = 2'b11;


  //Adress map
  
  localparam  logic [ADDR_WIDTH-1:0] S0_BASE = 32'h0000_0000;
  localparam  logic [ADDR_WIDTH-1:0] S0_HIGH = 32'h0fff_ffff;
  localparam  logic [ADDR_WIDTH-1:0] S1_BASE = 32'h1000_0000;
  localparam  logic [ADDR_WIDTH-1:0] S1_HIGH = 32'h1fff_ffff;

endpackage
