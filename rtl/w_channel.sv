module w_channel 
  import axi_crossbar_pkg::*;
 (
  input logic clk,
  input logic rst_n,

  //Master 0 Ports

  input  logic [DATA_WIDTH-1:0]  m0_wdata,
  input  logic [STRB_WIDTH-1:0]  m0_wstrb,
  input  logic                   m0_wlast,
  input  logic                   m0_wvalid,
  output logic                   m0_wready,

  //Master 1 Ports
  input  logic [DATA_WIDTH-1:0]  m1_wdata,
  input  logic [STRB_WIDTH-1:0]  m1_wstrb,
  input  logic                   m1_wlast,
  input  logic                   m1_wvalid,
  output logic                   m1_wready,

  //AW order tracker input from AW channel
  //Master 0
  input  logic [10:0]           m0_worder_data,
  input  logic                  m0_worder_valid,
  input  logic                  m0_worder_ready,

  //Master 1
  input  logic [10:0]           m1_worder_data,
  input  logic                  m1_worder_valid,
  input  logic                  m1_worder_ready,

  //slave 0 W port
  output logic [DATA_WIDTH-1:0] s0_wdata,
  output logic [STRB_WIDTH-1:0] s0_wstrb,
  output logic                  s0_wlast,
  output logic                  s0_wvalid,
  input  logic                  s0_wready,

  //slave 1 W port
  output logic [DATA_WIDTH-1:0] s1_wdata,
  output logic [STRB_WIDTH-1:0] s1_wstrb,
  output logic                  s1_wlast,
  output logic                  s1_wvalid,
  input  logic                  s1_wready,

  //Dummy slave W port
  output logic [DATA_WIDTH-1:0] dm_wdata,
  output logic [STRB_WIDTH-1:0] dm_wstrb,
  output logic                  dm_wlast,
  output logic                  dm_wvalid,
  input  logic                  dm_wready
 );



  //STEP:1 W FIFOs (one per master)

  localparam int W_PKT = DATA_WIDTH + STRB_WIDTH + 1;

  //M0 FIFO
  logic                         m0_wf_wr_valid, m0_wf_wr_ready;
  logic [W_PKT-1:0]             m0_wf_wr_data;
  logic                         m0_wf_rd_valid, m0_wf_rd_ready;
  logic [W_PKT-1:0]             m0_wf_rd_data;

  //M1 FIFO
  logic                         m1_wf_wr_valid, m1_wf_wr_ready;
  logic [W_PKT-1:0]             m1_wf_wr_data;
  logic                         m1_wf_rd_valid, m1_wf_rd_ready;
  logic [W_PKT-1:0]             m1_wf_rd_data;
  
  //M0
  assign m0_wf_wr_data        = {m0_wdata, m0_wstrb, m0_wlast};
  assign m0_wf_wr_valid       = m0_wvalid;
  assign m0_wready            = m0_wf_wr_ready;

  //M1
  assign m1_wf_wr_data        = {m1_wdata, m1_wstrb, m1_wlast};
  assign m1_wf_wr_valid       = m1_wvalid;
  assign m1_wready            = m1_wf_wr_ready;

  //M0 FIFO
  axi_fifo #(.WIDTH(W_PKT), .DEPTH(W_FIFO_DEPTH)) u_m0_wfifo (
    .clk (clk),     
    .rst_n(rst_n),
    .wr_data  (m0_wf_wr_data),    
    .wr_valid (m0_wf_wr_valid),
    .wr_ready (m0_wf_wr_ready),   
    .rd_data  (m0_wf_rd_data),
    .rd_valid (m0_wf_rd_valid),   
    .rd_ready (m0_wf_rd_ready)
  );

  //M1 FIFO
  axi_fifo #(.WIDTH(W_PKT), .DEPTH(W_FIFO_DEPTH)) u_m1_wfifo (
    .clk (clk),     
    .rst_n(rst_n),
    .wr_data  (m1_wf_wr_data),    
    .wr_valid (m1_wf_wr_valid),
    .wr_ready (m1_wf_wr_ready),   
    .rd_data  (m1_wf_rd_data),
    .rd_valid (m1_wf_rd_valid),   
    .rd_ready (m1_wf_rd_ready)
  );

  //STEP 2: AW order tracker FIFOs (one per master)
  //M0
  logic                     m0_ord_rd_valid, m0_ord_rd_ready;
  logic [10:0]              m0_ord_rd_data;
  
  //M1
  logic                     m1_ord_rd_valid, m1_ord_rd_ready;
  logic [10:0]              m1_ord_rd_data;

  //M0  Order FIFO
  axi_fifo #(.WIDTH(11), .DEPTH(ORD_FIFO_DEPTH)) u_m0_ord (
    .clk (clk),     .rst_n(rst_n),
    .wr_data  (m0_worder_data),    
    .wr_valid (m0_worder_valid),
    .wr_ready (m0_worder_ready),   
    .rd_data  (m0_ord_rd_data),
    .rd_valid (m0_ord_rd_valid),   
    .rd_ready (m0_ord_rd_ready)
  );

  //M1  Order FIFO
  axi_fifo #(.WIDTH(11), .DEPTH(ORD_FIFO_DEPTH)) u_m1_ord (
    .clk (clk),     
    .rst_n(rst_n),
    .wr_data  (m1_worder_data),    
    .wr_valid (m1_worder_valid),
    .wr_ready (m1_worder_ready),   
    .rd_data  (m1_ord_rd_data),
    .rd_valid (m1_ord_rd_valid),   
    .rd_ready (m1_ord_rd_ready)
  );

  //STEP:3 W FSM per Master
  // IDLE: wait for an order tracker entry to arrive
  // ACTIVE: forward W beats to the target slave
  

  typedef enum logic [1:0] {
    W_IDLE    = 2'b00,
    W_ACTIVE  = 2'b01
  } w_fsm_e;

  //M0 W FSM
  w_fsm_e                m0_wfsm;
  logic                  m0_decerr; //current burst is DECERR
  logic [1:0]            m0_slave_sel;
  logic [LEN_WIDTH-1:0]  m0_beat_cnt;

  //Unpack order tracker head for M0

  logic                  m0_ord_decerr;
  logic                  m0_ord_slave;
  logic [LEN_WIDTH-1:0]  m0_ord_len;
  
  assign {m0_ord_decerr, m0_ord_slave, m0_ord_len} = m0_ord_rd_data;

  //unpack W FIFO head for M0

  logic [DATA_WIDTH-1:0]  m0_whead_data;
  logic [STRB_WIDTH-1:0]  m0_whead_strb;
  logic                   m0_whead_last;

  assign {m0_whead_data, m0_whead_strb, m0_whead_last} = m0_wf_rd_data;

  logic m0_beat_accepted;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m0_wfsm         <= W_IDLE;
      m0_decerr       <= 1'b0;
      m0_slave_sel    <= 2'b00;
      m0_beat_cnt     <= '0;
      
    end else begin
      case (m0_wfsm)
        W_IDLE: begin
          //wait for order tracker entry

          if (m0_ord_rd_valid) begin
            m0_decerr       <= m0_ord_decerr;
            m0_slave_sel    <= m0_ord_slave;
            m0_beat_cnt     <= m0_ord_len;
            m0_wfsm         <= W_ACTIVE;
          end
        end
        
        W_ACTIVE: begin
          // Beat consumed when slave accepts it
          if (m0_beat_accepted) begin
            if (m0_whead_last || m0_beat_cnt == '0) begin
              //Last beat --burst done, back to IDLE
              m0_wfsm   <= W_IDLE;
              
            end else begin
              m0_beat_cnt   <=m0_beat_cnt - 1'b1;
            end
          end
        end

        default: m0_wfsm <= W_IDLE;
      endcase
    end
  end

  //pop order tracker when latched in IDLE

  assign m0_ord_rd_ready = (m0_wfsm == W_IDLE) && m0_ord_rd_valid;






  //M1 W FSM
  w_fsm_e                m1_wfsm;
  logic                  m1_decerr; //current burst is DECERR
  logic [1:0]            m1_slave_sel;
  logic [LEN_WIDTH-1:0]  m1_beat_cnt;

  //Unpack order tracker head for M1

  logic                  m1_ord_decerr;
  logic                  m1_ord_slave;
  logic [LEN_WIDTH-1:0]  m1_ord_len;

  assign {m1_ord_decerr, m1_ord_slave, m1_ord_len} = m1_ord_rd_data;

  //unpack W FIFO head for M1

  logic [DATA_WIDTH-1:0]  m1_whead_data;
  logic [STRB_WIDTH-1:0]  m1_whead_strb;
  logic                   m1_whead_last;

  assign {m1_whead_data, m1_whead_strb, m1_whead_last} = m1_wf_rd_data;

  logic m1_beat_accepted;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m1_wfsm         <= W_IDLE;
      m1_decerr       <= 1'b0;
      m1_slave_sel    <= 2'b00;
      m1_beat_cnt     <= '0;

    end else begin
      case (m1_wfsm)
        W_IDLE: begin
          //wait for order tracker entry

          if (m1_ord_rd_valid) begin
            m1_decerr       <= m1_ord_decerr;
            m1_slave_sel    <= m1_ord_slave;
            m1_beat_cnt     <= m1_ord_len;
            m1_wfsm         <= W_ACTIVE;
          end
        end

        W_ACTIVE: begin
          // Beat consumed when slave accepts it
          if (m1_beat_accepted) begin
            if (m1_whead_last || m1_beat_cnt == '0) begin
              //Last beat --burst done, back to IDLE
              m1_wfsm   <= W_IDLE;

            end else begin
              m1_beat_cnt   <=m1_beat_cnt - 1'b1;
            end
          end
        end

        default: m1_wfsm <= W_IDLE;
      endcase
    end
  end

  //pop order tracker when latched in IDLE

  assign m1_ord_rd_ready = (m1_wfsm == W_IDLE) && m1_ord_rd_valid;

  
  //STEP4: W ROuter 
  //slave 0

  always_comb begin
    s0_wvalid = 1'b0;
    s0_wdata  = '0;
    s0_wstrb  = '0;
    s0_wlast  = 1'b0;

    if (m0_wfsm == W_ACTIVE && m0_slave_sel == 2'b00 && !m0_decerr && m0_wf_rd_valid) begin
      s0_wvalid = 1'b1;
      s0_wdata  = m0_whead_data;
      s0_wstrb  = m0_whead_strb;
      s0_wlast  = m0_whead_last;
    end

    else if (m1_wfsm == W_ACTIVE && m1_slave_sel == 2'b00 && !m1_decerr && m1_wf_rd_valid) begin
      s0_wvalid = 1'b1;
      s0_wdata  = m1_whead_data;
      s0_wstrb  = m1_whead_strb;
      s0_wlast  = m1_whead_last;

    end
  end

  //slave 1
  always_comb begin
    s1_wvalid = 1'b0;
    s1_wdata  = '0;
    s1_wstrb  = '0;
    s1_wlast  = 1'b0;

    if (m0_wfsm == W_ACTIVE && m0_slave_sel == 2'b01 && !m0_decerr && m0_wf_rd_valid) begin
      s1_wvalid = 1'b1;
      s1_wdata  = m0_whead_data;
      s1_wstrb  = m0_whead_strb;
      s1_wlast  = m0_whead_last;
    end

    else if (m1_wfsm == W_ACTIVE && m1_slave_sel == 2'b01 && !m1_decerr && m1_wf_rd_valid) begin
      s1_wvalid = 1'b1;
      s1_wdata  = m1_whead_data;
      s1_wstrb  = m1_whead_strb;
      s1_wlast  = m1_whead_last;

    end
  end

  //Dummy slave DECERR drain

    always_comb begin
    dm_wvalid = 1'b0;
    dm_wdata  = '0;
    dm_wstrb  = '0;
    dm_wlast  = 1'b0;

    if (m0_wfsm == W_ACTIVE && m0_decerr && m0_wf_rd_valid) begin
      dm_wvalid = 1'b1;
      dm_wdata  = m0_whead_data;
      dm_wstrb  = m0_whead_strb;
      dm_wlast  = m0_whead_last;
    end

    else if (m1_wfsm == W_ACTIVE && m1_decerr && m1_wf_rd_valid) begin
      dm_wvalid = 1'b1;
      dm_wdata  = m1_whead_data;
      dm_wstrb  = m1_whead_strb;
      dm_wlast  = m1_whead_last;

    end
  end


  //STEP 5: Beat accepted signal


  always_comb begin

    m0_beat_accepted = 1'b0;
    m1_beat_accepted = 1'b0;

    if (m0_wfsm == W_ACTIVE && m0_wf_rd_valid) begin
      if (m0_decerr)
        m0_beat_accepted  = dm_wready;  //dummy always ready
      
      else if (m0_slave_sel == 2'b00)
        m0_beat_accepted  = s0_wready && s0_wvalid;

      else if (m0_slave_sel == 2'b01)
        m0_beat_accepted  = s1_wready && s1_wvalid;
    end

    if (m1_wfsm == W_ACTIVE && m1_wf_rd_valid) begin
      if (m1_decerr)
        m1_beat_accepted  = dm_wready;  //dummy always ready

      else if (m1_slave_sel == 2'b00)
        m1_beat_accepted  = s0_wready && s0_wvalid && !(m0_wfsm == W_ACTIVE && m0_slave_sel == 2'b00 && !m0_decerr);

      else if (m1_slave_sel == 2'b01)
        m1_beat_accepted  = s1_wready && s1_wvalid && !(m0_wfsm == W_ACTIVE && m0_slave_sel == 2'b01 && !m0_decerr);
    end
  end

  //pop W FIFOs when beat accepted

  assign m0_wf_rd_ready  = m0_beat_accepted;
  assign m1_wf_rd_ready  = m1_beat_accepted;

endmodule
