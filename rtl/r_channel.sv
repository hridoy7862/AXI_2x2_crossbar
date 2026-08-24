module r_channel
  import axi_crossbar_pkg::*;
(

  input logic clk,
  input logic rst_n,

  // Slave 0 R
  input  logic [ID_WIDTH_S-1:0] s0_rid,
  input  logic [DATA_WIDTH-1:0] s0_rdata,
  input  logic [1:0]            s0_rresp,
  input  logic                  s0_rlast,
  input  logic                  s0_rvalid,
  output logic                  s0_rready,

  
  // Slave 1 R
  input  logic [ID_WIDTH_S-1:0] s1_rid,
  input  logic [DATA_WIDTH-1:0] s1_rdata,
  input  logic [1:0]            s1_rresp,
  input  logic                  s1_rlast,
  input  logic                  s1_rvalid,
  output logic                  s1_rready,
 
  // Dummy Slave  R
  input  logic [ID_WIDTH_S-1:0] dm_rid,
  input  logic [DATA_WIDTH-1:0] dm_rdata,
  input  logic [1:0]            dm_rresp,
  input  logic                  dm_rlast,
  input  logic                  dm_rvalid,
  output logic                  dm_rready,

  /*/ Outstanding tracker
  output logic [ID_WIDTH_S-1:0] ostnd_lookup_rid,
  input  logic                  ostnd_lookup_master,
  input  logic                  ostnd_lookup_hit,
  output logic [ID_WIDTH_S-1:0] ostnd_clear_rid,
  output logic                  ostnd_clear_valid,
  */

  // Master 0 R
  output logic [ID_WIDTH-1:0]   m0_rid,
  output logic [DATA_WIDTH-1:0] m0_rdata,
  output logic [1:0]            m0_rresp,
  output logic                  m0_rlast,
  output logic                  m0_rvalid,
  input  logic                  m0_rready,
 

  // Master 1 R
  output logic [ID_WIDTH-1:0]   m1_rid,
  output logic [DATA_WIDTH-1:0] m1_rdata,
  output logic [1:0]            m1_rresp,
  output logic                  m1_rlast,
  output logic                  m1_rvalid,
  input  logic                  m1_rready
  );

  // Packet Width

  localparam int RS_PKT = ID_WIDTH_S + DATA_WIDTH + 2 + 1; // slave-side
  localparam int RM_PKT = ID_WIDTH   + DATA_WIDTH + 2 + 1; // master-side

  // Slave-side R FIFOs
  
  logic s0_rd_rdy, s1_rd_rdy, dm_rd_rdy; // FIFO pop controls
 
  logic [RS_PKT-1:0] s0_f_rd_data, s1_f_rd_data, dm_f_rd_data;
  logic              s0_f_rd_valid, s1_f_rd_valid, dm_f_rd_valid;
  logic              s0_f_wr_rdy,   s1_f_wr_rdy,   dm_f_wr_rdy;
 
  axi_fifo #(.WIDTH(RS_PKT),.DEPTH(R_FIFO_DEPTH)) u_s0_rf (
        .clk(clk),  
        .rst_n(rst_n),
        .wr_data ({s0_rid,s0_rdata,s0_rresp,s0_rlast}),
        .wr_valid(s0_rvalid), 
        .wr_ready(s0_f_wr_rdy),
        .rd_data (s0_f_rd_data), 
        .rd_valid(s0_f_rd_valid), 
        .rd_ready(s0_rd_rdy)
  );
  axi_fifo #(.WIDTH(RS_PKT),.DEPTH(R_FIFO_DEPTH)) u_s1_rf (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data ({s1_rid,s1_rdata,s1_rresp,s1_rlast}),
        .wr_valid(s1_rvalid), 
        .wr_ready(s1_f_wr_rdy),
        .rd_data (s1_f_rd_data), 
        .rd_valid(s1_f_rd_valid), 
        .rd_ready(s1_rd_rdy)
  );
  axi_fifo #(.WIDTH(RS_PKT),.DEPTH(R_FIFO_DEPTH)) u_dm_rf (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data ({dm_rid,dm_rdata,dm_rresp,dm_rlast}),
        .wr_valid(dm_rvalid), 
        .wr_ready(dm_f_wr_rdy),
        .rd_data (dm_f_rd_data), 
        .rd_valid(dm_f_rd_valid), 
        .rd_ready(dm_rd_rdy)
  );
 
  assign s0_rready = s0_f_wr_rdy;
  assign s1_rready = s1_f_wr_rdy;
  assign dm_rready = dm_f_wr_rdy;
 
  // Master-side R FIFOs
  logic              m0_rf_wr_valid, m0_rf_wr_rdy;
  logic [RM_PKT-1:0] m0_rf_wr_data;
  logic              m0_rf_rd_valid;
  logic [RM_PKT-1:0] m0_rf_rd_data;
 
  logic              m1_rf_wr_valid, m1_rf_wr_rdy;
  logic [RM_PKT-1:0] m1_rf_wr_data;
  logic              m1_rf_rd_valid;
  logic [RM_PKT-1:0] m1_rf_rd_data;
 
  axi_fifo #(.WIDTH(RM_PKT),.DEPTH(R_FIFO_DEPTH)) u_m0_rf (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data(m0_rf_wr_data), 
        .wr_valid(m0_rf_wr_valid), 
        .wr_ready(m0_rf_wr_rdy),
        .rd_data(m0_rf_rd_data), 
        .rd_valid(m0_rf_rd_valid), 
        .rd_ready(m0_rready)
  );
  axi_fifo #(.WIDTH(RM_PKT),.DEPTH(R_FIFO_DEPTH)) u_m1_rf (
        .clk(clk),.rst_n(rst_n),
        .wr_data(m1_rf_wr_data), 
        .wr_valid(m1_rf_wr_valid), 
        .wr_ready(m1_rf_wr_rdy),
        .rd_data(m1_rf_rd_data), 
        .rd_valid(m1_rf_rd_valid), 
        .rd_ready(m1_rready)
  );


  // Unpack slave FIFO heads
  logic [ID_WIDTH_S-1:0] s0h_rid,   s1h_rid,    dmh_rid;
  logic [DATA_WIDTH-1:0] s0h_rdata, s1h_rdata,  dmh_rdata;
  logic [1:0]            s0h_rresp, s1h_rresp,  dmh_rresp;
  logic                  s0h_rlast, s1h_rlast,  dmh_rlast;

  assign {s0h_rid,s0h_rdata,s0h_rresp,s0h_rlast} = s0_f_rd_data;
  assign {s1h_rid,s1h_rdata,s1h_rresp,s1h_rlast} = s1_f_rd_data;
  assign {dmh_rid,dmh_rdata,dmh_rresp,dmh_rlast} = dm_f_rd_data;

  // R Router  –  purely combinational
  // RID[4] = master select (set by ID tagger in ar_channel)
  always_comb begin

    // defaults
    s0_rd_rdy      = 1'b0;
    s1_rd_rdy      = 1'b0;
    dm_rd_rdy      = 1'b0;
    m0_rf_wr_valid = 1'b0;
    m0_rf_wr_data  = '0;
    m1_rf_wr_valid = 1'b0;
    m1_rf_wr_data  = '0;
 
    //  Route to M0 (priority: S0 > S1 > Dummy)
    if (s0_f_rd_valid && (s0h_rid[4]==1'b0) && m0_rf_wr_rdy) begin

      m0_rf_wr_valid = 1'b1;
      m0_rf_wr_data  = {s0h_rid[3:0], s0h_rdata, s0h_rresp, s0h_rlast};
      s0_rd_rdy      = 1'b1;
   
    end else if (s1_f_rd_valid && (s1h_rid[4]==1'b0) && m0_rf_wr_rdy) begin

      m0_rf_wr_valid = 1'b1;
      m0_rf_wr_data  = {s1h_rid[3:0], s1h_rdata, s1h_rresp, s1h_rlast};
      s1_rd_rdy      = 1'b1;
    end else if (dm_f_rd_valid && (dmh_rid[4]==1'b0) && m0_rf_wr_rdy) begin

      m0_rf_wr_valid = 1'b1;
      m0_rf_wr_data  = {dmh_rid[3:0], dmh_rdata, dmh_rresp, dmh_rlast};
      dm_rd_rdy      = 1'b1;
    end
 
    //Route to M1 (priority: S0 > S1 > Dummy) 
    // Only pick a source NOT already claimed by M0 routing above
    if (s0_f_rd_valid && (s0h_rid[4]==1'b1) && m1_rf_wr_rdy && !s0_rd_rdy) begin
      m1_rf_wr_valid = 1'b1;
      m1_rf_wr_data  = {s0h_rid[3:0], s0h_rdata, s0h_rresp, s0h_rlast};
      s0_rd_rdy      = 1'b1;
    end else if (s1_f_rd_valid && (s1h_rid[4]==1'b1) && m1_rf_wr_rdy && !s1_rd_rdy) begin
      m1_rf_wr_valid = 1'b1;
      m1_rf_wr_data  = {s1h_rid[3:0], s1h_rdata, s1h_rresp, s1h_rlast};
      s1_rd_rdy      = 1'b1;
    end else if (dm_f_rd_valid && (dmh_rid[4]==1'b1) && m1_rf_wr_rdy && !dm_rd_rdy) begin
      m1_rf_wr_valid = 1'b1;
      m1_rf_wr_data  = {dmh_rid[3:0], dmh_rdata, dmh_rresp, dmh_rlast};
      dm_rd_rdy      = 1'b1;
    end
  end
  
  // Drive master R outputs from master R FIFOs
  logic [ID_WIDTH-1:0]   m0i_rid,   m1i_rid;
  logic [DATA_WIDTH-1:0] m0i_rdata, m1i_rdata;
  logic [1:0]            m0i_rresp, m1i_rresp;
  logic                  m0i_rlast, m1i_rlast;
 
  assign {m0i_rid,m0i_rdata,m0i_rresp,m0i_rlast} = m0_rf_rd_data;
  assign {m1i_rid,m1i_rdata,m1i_rresp,m1i_rlast} = m1_rf_rd_data;
 
  assign m0_rvalid = m0_rf_rd_valid;
  assign m0_rid    = m0i_rid;
  assign m0_rdata  = m0i_rdata;
  assign m0_rresp  = m0i_rresp;
  assign m0_rlast  = m0i_rlast;
 
  assign m1_rvalid = m1_rf_rd_valid;
  assign m1_rid    = m1i_rid;
  assign m1_rdata  = m1i_rdata;
  assign m1_rresp  = m1i_rresp;
  assign m1_rlast  = m1i_rlast;
 
endmodule


