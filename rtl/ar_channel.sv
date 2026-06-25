module ar_channel
  import  axi_crossbar_pkg::*;
(

  input logic clk,
  input logic rst_n,

  // Master 0 AR
  input  logic [ID_WIDTH-1:0]   m0_arid,
  input  logic [ADDR_WIDTH-1:0] m0_araddr,
  input  logic [LEN_WIDTH-1:0]  m0_arlen,
  input  logic [SIZE_WIDTH-1:0] m0_arsize,
  input  logic [1:0]            m0_arburst,
  input  logic                  m0_arvalid,
  output logic                  m0_arready,

  // Master 1 AR
  input  logic [ID_WIDTH-1:0]   m1_arid,
  input  logic [ADDR_WIDTH-1:0] m1_araddr,
  input  logic [LEN_WIDTH-1:0]  m1_arlen,
  input  logic [SIZE_WIDTH-1:0] m1_arsize,
  input  logic [1:0]            m1_arburst,
  input  logic                  m1_arvalid,
  output logic                  m1_arready,

  // Slave 0 AR
  output logic [ID_WIDTH_S-1:0] s0_arid,
  output logic [ADDR_WIDTH-1:0] s0_araddr,
  output logic [LEN_WIDTH-1:0]  s0_arlen,
  output logic [SIZE_WIDTH-1:0] s0_arsize,
  output logic [1:0]            s0_arburst,
  output logic                  s0_arvalid,
  input  logic                  s0_arready,
 
  // Slave 1 AR
  output logic [ID_WIDTH_S-1:0] s1_arid,
  output logic [ADDR_WIDTH-1:0] s1_araddr,
  output logic [LEN_WIDTH-1:0]  s1_arlen,
  output logic [SIZE_WIDTH-1:0] s1_arsize,
  output logic [1:0]            s1_arburst,
  output logic                  s1_arvalid,
  input  logic                  s1_arready,

  //Dummy  Slave AR
  output logic [ID_WIDTH_S-1:0] dm_arid,
  output logic [ADDR_WIDTH-1:0] dm_araddr,
  output logic [LEN_WIDTH-1:0]  dm_arlen,
  output logic [SIZE_WIDTH-1:0] dm_arsize,
  output logic [1:0]            dm_arburst,
  output logic                  dm_arvalid,
  input  logic                  dm_arready


);

  // STEP 1: AR FIFOs (one per master)
  // Master 0
  logic                    m0_f_wr_valid, m0_f_wr_ready;
  logic [AR_PKT_WIDTH-1:0] m0_f_wr_data;
  logic                    m0_f_rd_valid, m0_f_rd_ready;
  logic [AR_PKT_WIDTH-1:0] m0_f_rd_data;
  
  //Master 1
  logic                    m1_f_wr_valid, m1_f_wr_ready;
  logic [AR_PKT_WIDTH-1:0] m1_f_wr_data;
  logic                    m1_f_rd_valid, m1_f_rd_ready;
  logic [AR_PKT_WIDTH-1:0] m1_f_rd_data;
 

  assign m0_f_wr_data  = {m0_arid, m0_araddr, m0_arlen, m0_arsize, m0_arburst};
  assign m0_f_wr_valid = m0_arvalid;
  assign m0_arready    = m0_f_wr_ready;
 
  
  assign m1_f_wr_data  = {m1_arid, m1_araddr, m1_arlen, m1_arsize, m1_arburst};
  assign m1_f_wr_valid = m1_arvalid;
  assign m1_arready    = m1_f_wr_ready;
 

  //Master 0 FIFO
  axi_fifo #(.WIDTH(AR_PKT_WIDTH), .DEPTH(AR_FIFO_DEPTH)) u_m0_arfifo (
        .clk(clk), 
        .rst_n(rst_n),
        .wr_data(m0_f_wr_data), 
        .wr_valid(m0_f_wr_valid), 
        .wr_ready(m0_f_wr_ready),
        .rd_data(m0_f_rd_data), 
        .rd_valid(m0_f_rd_valid), 
        .rd_ready(m0_f_rd_ready)
  );
 
  axi_fifo #(.WIDTH(AR_PKT_WIDTH), .DEPTH(AR_FIFO_DEPTH)) u_m1_arfifo (
        .clk(clk), 
        .rst_n(rst_n),
        .wr_data(m1_f_wr_data), 
        .wr_valid(m1_f_wr_valid), 
        .wr_ready(m1_f_wr_ready),
        .rd_data(m1_f_rd_data), 
        .rd_valid(m1_f_rd_valid), 
        .rd_ready(m1_f_rd_ready)
  );


  // STEP 2: Unpack FIFO heads
  logic [ID_WIDTH-1:0]   m0_head_id,    m1_head_id;
  logic [ADDR_WIDTH-1:0] m0_head_addr,  m1_head_addr;
  logic [LEN_WIDTH-1:0]  m0_head_len,   m1_head_len;
  logic [SIZE_WIDTH-1:0] m0_head_size,  m1_head_size;
  logic [1:0]            m0_head_burst, m1_head_burst;
 
  always_comb begin
        {m0_head_id, m0_head_addr, m0_head_len, m0_head_size, m0_head_burst} = m0_f_rd_data;

        {m1_head_id, m1_head_addr, m1_head_len, m1_head_size, m1_head_burst} = m1_f_rd_data;
  end

  // STEP 3: Address decoders
  target_slave_e m0_target, m1_target;

  axi_decoder u_dec_m0 (.addr(m0_head_addr), .target_slave(m0_target));
  axi_decoder u_dec_m1 (.addr(m1_head_addr), .target_slave(m1_target));

  // STEP 4: Per-slave request vectors
  logic [1:0] req_s0, req_s1;
 
  assign req_s0[0] = m0_f_rd_valid && (m0_target == TARGET_S0);
  assign req_s0[1] = m1_f_rd_valid && (m1_target == TARGET_S0);
  assign req_s1[0] = m0_f_rd_valid && (m0_target == TARGET_S1);
  assign req_s1[1] = m1_f_rd_valid && (m1_target == TARGET_S1);
 
  // STEP 5: Per-slave round-robin arbiters
  logic [1:0] grant_s0, grant_s1;
  logic       ack_s0,   ack_s1;

  round_robin_arbiter u_arb_s0 (
        .clk(clk), 
        .rst_n(rst_n),
        .req(req_s0), 
        .grant(grant_s0), 
        .ack(ack_s0)
  );

  round_robin_arbiter u_arb_s1 (
        .clk(clk), 
        .rst_n(rst_n),
        .req(req_s1), 
        .grant(grant_s1), 
        .ack(ack_s1)
  );
 
  // STEP 6: AR FSM per slave
  //   IDLE: latch grant, move to ACTIVE
  //   ACTIVE: hold on slave AR port, wait for ARREADY
  //   On ARREADY: pop AR FIFO, write outstanding tracker, go IDLE
 
  typedef enum logic [1:0] {
        AR_IDLE   = 2'b00,
        AR_ACTIVE = 2'b01
  } ar_state_e;
 
  // S0 FSM
  ar_state_e             s0_state;
  logic [1:0]            s0_held_grant;
  logic [ID_WIDTH_S-1:0] s0_held_id;
  logic [ADDR_WIDTH-1:0] s0_held_addr;
  logic [LEN_WIDTH-1:0]  s0_held_len;
  logic [SIZE_WIDTH-1:0] s0_held_size;
  logic [1:0]            s0_held_burst;
 


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s0_state      <= AR_IDLE;
      s0_held_grant <= '0;
      s0_held_id    <= '0;
      s0_held_addr  <= '0;
      s0_held_len   <= '0;
      s0_held_size  <= '0;
      s0_held_burst <= '0;
    end else case (s0_state)
      AR_IDLE: begin
        
        if (|grant_s0) begin
                  
          s0_held_grant <= grant_s0;
          // ID tagger: prepend master-select bit
          if (grant_s0[0]) begin
            s0_held_id    <= {1'b0, m0_head_id};
            s0_held_addr  <= m0_head_addr;
            s0_held_len   <= m0_head_len;
            s0_held_size  <= m0_head_size;
            s0_held_burst <= m0_head_burst;
          end else begin

            s0_held_id    <= {1'b1, m1_head_id};
            s0_held_addr  <= m1_head_addr;
            s0_held_len   <= m1_head_len;
            s0_held_size  <= m1_head_size;
            s0_held_burst <= m1_head_burst;
          end

          s0_state <= AR_ACTIVE;
        end
      end

      AR_ACTIVE: begin
        if (s0_arready)
          s0_state <= AR_IDLE;

        end
      default: s0_state <= AR_IDLE;
    endcase

  end
 
  assign s0_arvalid = (s0_state == AR_ACTIVE);
  assign s0_arid    = s0_held_id;
  assign s0_araddr  = s0_held_addr;
  assign s0_arlen   = s0_held_len;
  assign s0_arsize  = s0_held_size;
  assign s0_arburst = s0_held_burst;
  assign ack_s0     = (s0_state == AR_ACTIVE) && s0_arready;
 


  // S1 FSM
  ar_state_e             s1_state;
  logic [1:0]            s1_held_grant;
  logic [ID_WIDTH_S-1:0] s1_held_id;
  logic [ADDR_WIDTH-1:0] s1_held_addr;
  logic [LEN_WIDTH-1:0]  s1_held_len;
  logic [SIZE_WIDTH-1:0] s1_held_size;
  logic [1:0]            s1_held_burst;



  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s1_state      <= AR_IDLE;
      s1_held_grant <= '0;
      s1_held_id    <= '0;
      s1_held_addr  <= '0;
      s1_held_len   <= '0;
      s1_held_size  <= '0;
      s1_held_burst <= '0;
    end else case (s1_state)
      AR_IDLE: begin

        if (|grant_s1) begin

          s1_held_grant <= grant_s1;
          // ID tagger: prepend master-select bit
          if (grant_s1[0]) begin
            s1_held_id    <= {1'b0, m0_head_id};
            s1_held_addr  <= m0_head_addr;
            s1_held_len   <= m0_head_len;
            s1_held_size  <= m0_head_size;
            s1_held_burst <= m0_head_burst;
          end else begin

            s1_held_id    <= {1'b1, m1_head_id};
            s1_held_addr  <= m1_head_addr;
            s1_held_len   <= m1_head_len;
            s1_held_size  <= m1_head_size;
            s1_held_burst <= m1_head_burst;
          end

          s1_state <= AR_ACTIVE;
        end
      end

      AR_ACTIVE: begin
        if (s1_arready)
          s1_state <= AR_IDLE;

      end
      default: s1_state <= AR_IDLE;
    endcase

  end

  assign s1_arvalid = (s1_state == AR_ACTIVE);
  assign s1_arid    = s1_held_id;
  assign s1_araddr  = s1_held_addr;
  assign s1_arlen   = s1_held_len;
  assign s1_arsize  = s1_held_size;
  assign s1_arburst = s1_held_burst;
  assign ack_s1     = (s1_state == AR_ACTIVE) && s1_arready;

  
  // STEP 7: DECERR path — invalid address -dummy slave
  // Same logic as aw_channel DECERR FSMs
  
  ar_state_e             dm0_state, dm1_state;
  logic [ID_WIDTH_S-1:0] dm0_held_id, dm1_held_id;
  logic [ADDR_WIDTH-1:0] dm0_held_addr, dm1_held_addr;
  logic [LEN_WIDTH-1:0]  dm0_held_len, dm1_held_len;
  logic [SIZE_WIDTH-1:0] dm0_held_size, dm1_held_size;
  logic [1:0]            dm0_held_burst, dm1_held_burst;


  always_ff @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
      
      dm0_state      <= AR_IDLE;  dm1_state <= AR_IDLE;
      dm0_held_id    <= '0;     dm1_held_id <= '0;
      dm0_held_addr  <= '0;   dm1_held_addr <= '0;
      dm0_held_len   <= '0;    dm1_held_len <= '0;
      dm0_held_size  <= '0;   dm1_held_size <= '0;
      dm0_held_burst <= '0;  dm1_held_burst <= '0;
    end else begin

      // M0 DECERR FSM
      case (dm0_state)
        AR_IDLE: begin
          
          if (m0_f_rd_valid && (m0_target == TARGET_DEC)) begin
            
            dm0_held_id    <= {1'b0, m0_head_id};
            dm0_held_addr  <= m0_head_addr;
            dm0_held_len   <= m0_head_len;
            dm0_held_size  <= m0_head_size;
            dm0_held_burst <= m0_head_burst;
            dm0_state      <= AR_ACTIVE;
          end
        end
        AR_ACTIVE: begin
          if (dm_arready) dm0_state <= AR_IDLE;

        end

        default: dm0_state <= AR_IDLE;
      endcase
 
      // M1 DECERR FSM — M0 has priority
      case (dm1_state)
        AR_IDLE: begin

          if (m1_f_rd_valid && (m1_target == TARGET_DEC) && (dm0_state == AR_IDLE)) begin


            dm1_held_id    <= {1'b1, m1_head_id};
            dm1_held_addr  <= m1_head_addr;
            dm1_held_len   <= m1_head_len;
            dm1_held_size  <= m1_head_size;
            dm1_held_burst <= m1_head_burst;
            dm1_state      <= AR_ACTIVE;

          end
        end
        AR_ACTIVE: begin
          if (dm_arready) dm1_state <= AR_IDLE;
        end
        default: dm1_state <= AR_IDLE;
      endcase
    end
  end


  // Mux dummy slave outputs — M0 DECERR priority
  always_comb begin
    dm_arvalid = 1'b0;
    dm_arid    = '0;
    dm_araddr  = '0;
    dm_arlen   = '0;
    dm_arsize  = '0;
    dm_arburst = '0;
    if (dm0_state == AR_ACTIVE) begin
  
      dm_arvalid = 1'b1;
      dm_arid    = dm0_held_id;
      dm_araddr  = dm0_held_addr;
      dm_arlen   = dm0_held_len;
      dm_arsize  = dm0_held_size;
      dm_arburst = dm0_held_burst;

    end else if (dm1_state == AR_ACTIVE) begin

      dm_arvalid = 1'b1;
      dm_arid    = dm1_held_id;
      dm_araddr  = dm1_held_addr;
      dm_arlen   = dm1_held_len;
      dm_arsize  = dm1_held_size;
      dm_arburst = dm1_held_burst;
    end
  end

  // STEP 8: AR FIFO pop control
  // Pop when transaction is latched by an FSM (IDLE TO ACTIVE)
  always_comb begin
    m0_f_rd_ready = 1'b0;
    m1_f_rd_ready = 1'b0;

    // M0 pops
    if ((s0_state == AR_IDLE) && grant_s0[0])
      m0_f_rd_ready = 1'b1;

    if ((s1_state == AR_IDLE) && grant_s1[0])
      m0_f_rd_ready = 1'b1;

    if ((dm0_state == AR_IDLE) && m0_f_rd_valid && (m0_target == TARGET_DEC))
      m0_f_rd_ready = 1'b1;

    // M1 pops
    if ((s0_state == AR_IDLE) && grant_s0[1])
      m1_f_rd_ready = 1'b1;
    
    if ((s1_state == AR_IDLE) && grant_s1[1])
      m1_f_rd_ready = 1'b1;

    if ((dm1_state == AR_IDLE) && m1_f_rd_valid && (m1_target == TARGET_DEC) && (dm0_state == AR_IDLE))
      m1_f_rd_ready = 1'b1;
  end

endmodule


