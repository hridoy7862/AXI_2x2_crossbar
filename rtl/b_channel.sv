
module b_channel
  import axi_crossbar_pkg::*;
(

  input logic  clk,
  input logic  rst_n,


  //slave 0 B input
  input  logic [ID_WIDTH_S-1:0] s0_bid,
  input  logic [1:0]            s0_bresp,
  input  logic                  s0_bvalid,
  output logic                  s0_bready,

  // Slave 1 B input
  input  logic [ID_WIDTH_S-1:0] s1_bid,
  input  logic [1:0]            s1_bresp,
  input  logic                  s1_bvalid,
  output logic                  s1_bready,

  //Dummy slave B input
  input  logic [ID_WIDTH_S-1:0] dm_bid,
  input  logic [1:0]            dm_bresp,
  input  logic                  dm_bvalid,
  output logic                  dm_bready,

  //Master 0 B output 
  output logic [ID_WIDTH-1:0]   m0_bid,
  output logic [1:0]            m0_bresp,
  output logic                  m0_bvalid,
  input  logic                  m0_bready,

  //Master 1 B output 
  output logic [ID_WIDTH-1:0]   m1_bid,
  output logic [1:0]            m1_bresp,
  output logic                  m1_bvalid,
  input  logic                  m1_bready
  );


  //step 1: Slave side B fifos (one per slave + dummy)
 
  localparam int B_PKT = ID_WIDTH_S + 2; //BID(5), BRESP(2)
 
  //slave 0 FIFO
 
  logic                s0_bf_wr_valid, s0_bf_wr_ready;
  logic [B_PKT-1:0]    s0_bf_wr_data;
  logic                s0_bf_rd_valid, s0_bf_rd_ready;
  logic [B_PKT-1:0]    s0_bf_rd_data;

  //slave 1 FIFO

  logic                s1_bf_wr_valid, s1_bf_wr_ready;
  logic [B_PKT-1:0]    s1_bf_wr_data;
  logic                s1_bf_rd_valid, s1_bf_rd_ready;
  logic [B_PKT-1:0]    s1_bf_rd_data;

  //Dummy slave FIFO

  logic                dm_bf_wr_valid, dm_bf_wr_ready;
  logic [B_PKT-1:0]    dm_bf_wr_data;
  logic                dm_bf_rd_valid, dm_bf_rd_ready;
  logic [B_PKT-1:0]    dm_bf_rd_data;


  assign s0_bf_wr_data  = {s0_bid, s0_bresp};
  assign s0_bf_wr_valid = s0_bvalid;
  assign s0_bready      = s0_bf_wr_ready;

  assign s1_bf_wr_data  = {s1_bid, s1_bresp};
  assign s1_bf_wr_valid = s1_bvalid;
  assign s1_bready      = s1_bf_wr_ready;

  assign dm_bf_wr_data  = {dm_bid, dm_bresp};
  assign dm_bf_wr_valid = dm_bvalid;
  assign dm_bready      = dm_bf_wr_ready;

  axi_fifo #(.WIDTH(B_PKT), .DEPTH(B_FIFO_DEPTH)) u_s0_bfifo (

    .clk(clk), 
    .rst_n(rst_n),
    .wr_data(s0_bf_wr_data), 
    .wr_valid(s0_bf_wr_valid), 
    .wr_ready(s0_bf_wr_ready),
    .rd_data(s0_bf_rd_data), 
    .rd_valid(s0_bf_rd_valid), 
    .rd_ready(s0_bf_rd_ready)
  );

  axi_fifo #(.WIDTH(B_PKT), .DEPTH(B_FIFO_DEPTH)) u_s1_bfifo (

    .clk(clk), 
    .rst_n(rst_n),
    .wr_data(s1_bf_wr_data), 
    .wr_valid(s1_bf_wr_valid), 
    .wr_ready(s1_bf_wr_ready),
    .rd_data(s1_bf_rd_data), 
    .rd_valid(s1_bf_rd_valid), 
    .rd_ready(s1_bf_rd_ready)
  );

  axi_fifo #(.WIDTH(B_PKT), .DEPTH(B_FIFO_DEPTH)) u_dm_bfifo (

    .clk(clk), 
    .rst_n(rst_n),
    .wr_data(dm_bf_wr_data), 
    .wr_valid(dm_bf_wr_valid), 
    .wr_ready(dm_bf_wr_ready),
    .rd_data(dm_bf_rd_data), 
    .rd_valid(dm_bf_rd_valid), 
    .rd_ready(dm_bf_rd_ready)
  );


  // STEP 2: Master-side B FIFOs (one per master)
  // Master sees BVALID when this FIFO is not empty
 
  localparam int BM_PKT = ID_WIDTH + 2;  // BID(4) + BRESP(2) = 6 bits
 
  // M0 B FIFO
  logic              m0_bf_wr_valid, m0_bf_wr_ready;
  logic [BM_PKT-1:0] m0_bf_wr_data;
  logic              m0_bf_rd_valid, m0_bf_rd_ready;
  logic [BM_PKT-1:0] m0_bf_rd_data;
 
  // M1 B FIFO
  logic              m1_bf_wr_valid, m1_bf_wr_ready;
  logic [BM_PKT-1:0] m1_bf_wr_data;
  logic              m1_bf_rd_valid, m1_bf_rd_ready;
  logic [BM_PKT-1:0] m1_bf_rd_data;
 
  axi_fifo #(.WIDTH(BM_PKT), .DEPTH(B_FIFO_DEPTH)) u_m0_bfifo (
    
    .clk(clk), 
    .rst_n(rst_n),
    .wr_data(m0_bf_wr_data), 
    .wr_valid(m0_bf_wr_valid), 
    .wr_ready(m0_bf_wr_ready),
    .rd_data(m0_bf_rd_data), 
    .rd_valid(m0_bf_rd_valid), 
    .rd_ready(m0_bf_rd_ready)
  );
 
  axi_fifo #(.WIDTH(BM_PKT), .DEPTH(B_FIFO_DEPTH)) u_m1_bfifo (

    .clk(clk), .rst_n(rst_n),
    .wr_data(m1_bf_wr_data), 
    .wr_valid(m1_bf_wr_valid), 
    .wr_ready(m1_bf_wr_ready),
    .rd_data(m1_bf_rd_data), 
    .rd_valid(m1_bf_rd_valid), 
    .rd_ready(m1_bf_rd_ready)
    );


  // STEP 3: B Router + ID Stripper (combinational)
  
  // Unpack slave B FIFO heads
  logic [ID_WIDTH_S-1:0] s0_head_bid,  s1_head_bid,  dm_head_bid;
  logic [1:0]            s0_head_resp, s1_head_resp, dm_head_resp;
  logic                  s0_master_sel, s1_master_sel, dm_master_sel;
 

  assign {s0_head_bid, s0_head_resp} = s0_bf_rd_data;
  assign {s1_head_bid, s1_head_resp} = s1_bf_rd_data;
  assign {dm_head_bid, dm_head_resp} = dm_bf_rd_data;

  // Master select: BID[4] = 0 M0 ; BID[4] = 1 M1
  assign s0_master_sel = s0_head_bid[4];
  assign s1_master_sel = s1_head_bid[4];
  assign dm_master_sel = dm_head_bid[4];
 
 
  //  Route S0 response
  always_comb begin

    s0_bf_rd_ready = 1'b0;
        
 
    if (s0_bf_rd_valid) begin

      if (s0_master_sel == 1'b0 && m0_bf_wr_ready) begin
        s0_bf_rd_ready = 1'b1;  // pop S0 FIFO
      end else if (s0_master_sel == 1'b1 && m1_bf_wr_ready) begin
        s0_bf_rd_ready = 1'b1;
      
      end
    end
  end


  //  Route S1 response
  always_comb begin

    s1_bf_rd_ready = 1'b0;

    if (s1_bf_rd_valid) begin

      if (s1_master_sel == 1'b0 && m0_bf_wr_ready) begin
        s1_bf_rd_ready = 1'b1;  // pop S0 FIFO
      end else if (s1_master_sel == 1'b1 && m1_bf_wr_ready) begin
        s1_bf_rd_ready = 1'b1;

      end
    end
  end


  //  Route dummy slave response
  always_comb begin

    dm_bf_rd_ready = 1'b0;

    if (dm_bf_rd_valid) begin

      if (dm_master_sel == 1'b0 && m0_bf_wr_ready) begin
        dm_bf_rd_ready = 1'b1;  // pop S0 FIFO
      end else if (dm_master_sel == 1'b1 && m1_bf_wr_ready) begin
        dm_bf_rd_ready = 1'b1;

      end
    end
  end

  //Write to M0 B fifo
  //Priority : S0 first ,then S1, then Dummy(simple)
  

  always_comb begin
    m0_bf_wr_valid  = 1'b0;
    m0_bf_wr_data   = '0;

    if (s0_bf_rd_valid && s0_master_sel == 1'b0 && m0_bf_wr_ready) begin
        m0_bf_wr_valid = 1'b1;
        // ID stripper: remove bit[4], return [3:0] only
        m0_bf_wr_data  = {s0_head_bid[ID_WIDTH-1:0], s0_head_resp};
    end

    else if (s1_bf_rd_valid && s1_master_sel == 1'b0 && m0_bf_wr_ready) begin
        m0_bf_wr_valid = 1'b1;
        m0_bf_wr_data  = {s1_head_bid[ID_WIDTH-1:0], s1_head_resp};
    end


    else if (dm_bf_rd_valid && dm_master_sel == 1'b0 && m0_bf_wr_ready) begin
        m0_bf_wr_valid = 1'b1;
        m0_bf_wr_data  = {dm_head_bid[ID_WIDTH-1:0], dm_head_resp};
    end
  end


  // Write to M1 B FIFO

  always_comb begin
    m1_bf_wr_valid  = 1'b0;
    m1_bf_wr_data   = '0;

    if (s0_bf_rd_valid && s0_master_sel == 1'b1 && m1_bf_wr_ready) begin
        m1_bf_wr_valid = 1'b1;
        // ID stripper: remove bit[4], return [3:0] only
        m1_bf_wr_data  = {s0_head_bid[ID_WIDTH-1:0], s0_head_resp};
    end

    else if (s1_bf_rd_valid && s1_master_sel == 1'b1 && m1_bf_wr_ready) begin
        m1_bf_wr_valid = 1'b1;
        m1_bf_wr_data  = {s1_head_bid[ID_WIDTH-1:0], s1_head_resp};
    end


    else if (dm_bf_rd_valid && dm_master_sel == 1'b1 && m1_bf_wr_ready) begin
        m1_bf_wr_valid = 1'b1;
        m1_bf_wr_data  = {dm_head_bid[ID_WIDTH-1:0], dm_head_resp};
    end
  end


  //Step 4: Drive Master B outputs from master B fifos

  logic [ID_WIDTH-1:0]  m0_bid_int;
  logic [1:0]           m0_bresp_int;
  
  logic [ID_WIDTH-1:0]  m1_bid_int;
  logic [1:0]           m1_bresp_int;


  assign {m0_bid_int, m0_bresp_int} = m0_bf_rd_data;
  assign {m1_bid_int, m1_bresp_int} = m1_bf_rd_data;


  assign m0_bvalid        = m0_bf_rd_valid;
  assign m0_bid           = m0_bid_int;
  assign m0_bresp         = m0_bresp_int;
  assign m0_bf_rd_ready   = m0_bready;

  assign m1_bvalid        = m1_bf_rd_valid;
  assign m1_bid           = m1_bid_int;
  assign m1_bresp         = m1_bresp_int;
  assign m1_bf_rd_ready   = m1_bready;


  
  
endmodule
