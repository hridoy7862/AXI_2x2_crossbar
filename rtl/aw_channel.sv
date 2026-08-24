module aw_channel
    import axi_crossbar_pkg::*;
(
    input  logic clk,
    input  logic rst_n,
    

    //MASTER 0 AW PORTS
    input  logic [ID_WIDTH-1:0]   m0_awid,
    input  logic [ADDR_WIDTH-1:0] m0_awaddr,
    input  logic [LEN_WIDTH-1:0]  m0_awlen,
    input  logic [SIZE_WIDTH-1:0] m0_awsize,
    input  logic [1:0]            m0_awburst,
    input  logic                  m0_awvalid,
    output logic                  m0_awready,
    
    //MASTER 1 AW PORTS
    input  logic [ID_WIDTH-1:0]   m1_awid,
    input  logic [ADDR_WIDTH-1:0] m1_awaddr,
    input  logic [LEN_WIDTH-1:0]  m1_awlen,
    input  logic [SIZE_WIDTH-1:0] m1_awsize,
    input  logic [1:0]            m1_awburst,
    input  logic                  m1_awvalid,
    output logic                  m1_awready,

    //SLAVE 0 AW PORTS
    output logic [ID_WIDTH_S-1:0] s0_awid,
    output logic [ADDR_WIDTH-1:0] s0_awaddr,
    output logic [LEN_WIDTH-1:0]  s0_awlen,
    output logic [SIZE_WIDTH-1:0] s0_awsize,
    output logic [1:0]            s0_awburst,
    output logic                   s0_awvalid,
    input  logic                  s0_awready,

    //SLAVE 1 AW PORTS
    output logic [ID_WIDTH_S-1:0] s1_awid,
    output logic [ADDR_WIDTH-1:0] s1_awaddr,
    output logic [LEN_WIDTH-1:0]  s1_awlen,
    output logic [SIZE_WIDTH-1:0] s1_awsize,
    output logic [1:0]            s1_awburst,
    output logic                  s1_awvalid,
    input  logic                  s1_awready,

    // DUMMY SLAVE FOR INVALID ADDRESS
    output logic [ID_WIDTH_S-1:0] dm_awid,
    output logic [ADDR_WIDTH-1:0] dm_awaddr,
    output logic [LEN_WIDTH-1:0]  dm_awlen,
    output logic [SIZE_WIDTH-1:0] dm_awsize,
    output logic [1:0]            dm_awburst,
    output logic                  dm_awvalid,
    input  logic                  dm_awready,

    //W ORDER TRACKER FOR SEND THE DETAILS OF AW INFORMATION TO THE W CHANNEL
    output logic [10:0]           m0_worder_data,
    output logic                  m0_worder_valid,
    input  logic                  m0_worder_ready,

    output logic [10:0]           m1_worder_data,
    output logic                  m1_worder_valid,
    input  logic                  m1_worder_ready
);

    // STEP 1: AW FIFOs (one per master)
    // Buffers incoming AW requests from masters
    // Master sees AWREADY=1 when FIFO is not full
    logic                   m0_fifo_wr_valid, m0_fifo_wr_ready;
    logic [AW_PKT_WIDTH-1:0] m0_fifo_wr_data;
    logic                   m0_fifo_rd_valid, m0_fifo_rd_ready;
    logic [AW_PKT_WIDTH-1:0] m0_fifo_rd_data;

    logic                   m1_fifo_wr_valid, m1_fifo_wr_ready;
    logic [AW_PKT_WIDTH-1:0] m1_fifo_wr_data;
    logic                   m1_fifo_rd_valid, m1_fifo_rd_ready;
    logic [AW_PKT_WIDTH-1:0] m1_fifo_rd_data;

    // Pack AW fields into one word for FIFO storage
    // Order: [awid | awaddr | awlen | awsize | awburst]
    assign m0_fifo_wr_data  = {m0_awid, m0_awaddr, m0_awlen, m0_awsize, m0_awburst};
    assign m0_fifo_wr_valid = m0_awvalid;
    assign m0_awready       = m0_fifo_wr_ready;   // master sees FIFO ready

    assign m1_fifo_wr_data  = {m1_awid, m1_awaddr, m1_awlen, m1_awsize, m1_awburst};
    assign m1_fifo_wr_valid = m1_awvalid;
    assign m1_awready       = m1_fifo_wr_ready;

    axi_fifo #(.WIDTH(AW_PKT_WIDTH), .DEPTH(AW_FIFO_DEPTH)) u_m0_aw_fifo (
        .clk      (clk),       
        .rst_n    (rst_n),
        .wr_data  (m0_fifo_wr_data),  
        .wr_valid (m0_fifo_wr_valid),
        .wr_ready (m0_fifo_wr_ready),
        .rd_data  (m0_fifo_rd_data),  
        .rd_valid (m0_fifo_rd_valid),
        .rd_ready (m0_fifo_rd_ready)
    );

    axi_fifo #(.WIDTH(AW_PKT_WIDTH), .DEPTH(AW_FIFO_DEPTH)) u_m1_aw_fifo (
        .clk      (clk),       
        .rst_n    (rst_n),
        .wr_data  (m1_fifo_wr_data),  
        .wr_valid (m1_fifo_wr_valid),
        .wr_ready (m1_fifo_wr_ready),
        .rd_data  (m1_fifo_rd_data),  
        .rd_valid (m1_fifo_rd_valid),
        .rd_ready (m1_fifo_rd_ready)
    );

    // STEP 2: Unpack FIFO heads for decoding
    // These are the current AW transactions waiting at the FIFO outputs
    logic [ID_WIDTH-1:0]   m0_head_id,   m1_head_id;
    logic [ADDR_WIDTH-1:0] m0_head_addr, m1_head_addr;
    logic [LEN_WIDTH-1:0]  m0_head_len,  m1_head_len;
    logic [SIZE_WIDTH-1:0] m0_head_size, m1_head_size;
    logic [1:0]            m0_head_burst,m1_head_burst;

    always_comb begin
        {m0_head_id, m0_head_addr, m0_head_len, m0_head_size, m0_head_burst}
            = m0_fifo_rd_data;
        {m1_head_id, m1_head_addr, m1_head_len, m1_head_size, m1_head_burst}
            = m1_fifo_rd_data;
    end

    // STEP 3: Address decoders (one per master)
    // Each master's FIFO head address is decoded independently
    target_slave_e m0_target, m1_target;

    axi_decoder u_dec_m0 (
      .addr(m0_head_addr), 
      .target_slave(m0_target)
      );
    axi_decoder u_dec_m1 (
      .addr(m1_head_addr), 
      .target_slave(m1_target)
      );

    // STEP 4: Build request vectors for each slave arbiter
    // req_s0[0] = M0 has a valid AW entry targeting S0
    // req_s0[1] = M1 has a valid AW entry targeting S0
    logic [1:0] req_s0, req_s1;

    assign req_s0[0] = m0_fifo_rd_valid && (m0_target == TARGET_S0);
    assign req_s0[1] = m1_fifo_rd_valid && (m1_target == TARGET_S0);
    assign req_s1[0] = m0_fifo_rd_valid && (m0_target == TARGET_S1);
    assign req_s1[1] = m1_fifo_rd_valid && (m1_target == TARGET_S1);

    // STEP 5: Per-slave round-robin arbiters
    // Arbiter S0 picks between M0 and M1 wanting S0
    // Arbiter S1 picks between M0 and M1 wanting S1
    logic [1:0] grant_s0, grant_s1;
    logic       ack_s0,   ack_s1;    // handshake complete signals

    round_robin_arbiter u_arb_s0 (
        .clk   (clk),   
        .rst_n (rst_n),
        .req   (req_s0), 
        .grant (grant_s0), 
        .ack (ack_s0)
    );

    round_robin_arbiter u_arb_s1 (
        .clk   (clk),   
        .rst_n (rst_n),
        .req   (req_s1), 
        .grant (grant_s1), 
        .ack (ack_s1)
    );

    // STEP 6: AW FSM per slave
    // FSM states:
    // IDLE   : no transaction in progress, look for a grant
    // ACTIVE : holding transaction on slave AW port, waiting AWREADY
    typedef enum logic [1:0] {
        AW_IDLE   = 2'b00,
        AW_ACTIVE = 2'b01
    } aw_state_e;

    aw_state_e             s0_state;
    logic [1:0]            s0_held_grant;   // which master is held
    logic [ID_WIDTH_S-1:0] s0_held_id;
    logic [ADDR_WIDTH-1:0] s0_held_addr;
    logic [LEN_WIDTH-1:0]  s0_held_len;
    logic [SIZE_WIDTH-1:0] s0_held_size;
    logic [1:0]            s0_held_burst;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s0_state      <= AW_IDLE;
            s0_held_grant <= '0;
        end else case (s0_state)

            AW_IDLE: begin
                if (|grant_s0) begin
                    s0_held_grant <= grant_s0;
                    // ID tagger: prepend master-select bit
                    // grant_s0[0]=M0 → bit[4]=0  ;  grant_s0[1]=M1 → bit[4]=1
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
                    s0_state <= AW_ACTIVE;
                end
            end

            AW_ACTIVE: begin
                // Hold until slave accepts
                if (s0_awready) begin
                    s0_state <= AW_IDLE;
                end
            end

            default: s0_state <= AW_IDLE;
        endcase
    end

    // Drive slave 0 AW port
    assign s0_awvalid = (s0_state == AW_ACTIVE);
    assign s0_awid    = s0_held_id;
    assign s0_awaddr  = s0_held_addr;
    assign s0_awlen   = s0_held_len;
    assign s0_awsize  = s0_held_size;
    assign s0_awburst = s0_held_burst;

    // Ack to arbiter S0: handshake complete
    assign ack_s0 = (s0_state == AW_ACTIVE) && s0_awready;

    aw_state_e           s1_state;
    logic [1:0]          s1_held_grant;
    logic [ID_WIDTH_S-1:0] s1_held_id;
    logic [ADDR_WIDTH-1:0] s1_held_addr;
    logic [LEN_WIDTH-1:0]  s1_held_len;
    logic [SIZE_WIDTH-1:0] s1_held_size;
    logic [1:0]            s1_held_burst;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_state      <= AW_IDLE;
            s1_held_grant <= '0;
        end else case (s1_state)

            AW_IDLE: begin
                if (|grant_s1) begin
                    s1_held_grant <= grant_s1;
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
                    s1_state <= AW_ACTIVE;
                end
            end

            AW_ACTIVE: begin
                if (s1_awready) begin
                    s1_state <= AW_IDLE;
                end
            end

            default: s1_state <= AW_IDLE;
        endcase
    end

    assign s1_awvalid = (s1_state == AW_ACTIVE);
    assign s1_awid    = s1_held_id;
    assign s1_awaddr  = s1_held_addr;
    assign s1_awlen   = s1_held_len;
    assign s1_awsize  = s1_held_size;
    assign s1_awburst = s1_held_burst;

    assign ack_s1 = (s1_state == AW_ACTIVE) && s1_awready;

    // STEP 7: DECERR path — invalid address → dummy slave
    //

    aw_state_e             dm0_state;
    logic [ID_WIDTH_S-1:0] dm0_held_id;
    logic [ADDR_WIDTH-1:0] dm0_held_addr;
    logic [LEN_WIDTH-1:0]  dm0_held_len;
    logic [SIZE_WIDTH-1:0] dm0_held_size;
    logic [1:0]            dm0_held_burst;

    aw_state_e             dm1_state;
    logic [ID_WIDTH_S-1:0] dm1_held_id;
    logic [ADDR_WIDTH-1:0] dm1_held_addr;
    logic [LEN_WIDTH-1:0]  dm1_held_len;
    logic [SIZE_WIDTH-1:0] dm1_held_size;
    logic [1:0]            dm1_held_burst;

    // Internal dummy slave signals (muxed from M0/M1 DECERR)
    logic [ID_WIDTH_S-1:0] dm_held_id_int;
    logic [ADDR_WIDTH-1:0] dm_held_addr_int;
    logic [LEN_WIDTH-1:0]  dm_held_len_int;
    logic [SIZE_WIDTH-1:0] dm_held_size_int;
    logic [1:0]            dm_held_burst_int;
    logic                  dm_awvalid_int;

    // Simple priority: M0 DECERR before M1 DECERR
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dm0_state <= AW_IDLE;
            dm1_state <= AW_IDLE;
        end else begin

            // M0 DECERR FSM
            case (dm0_state)
                AW_IDLE: begin
                    if (m0_fifo_rd_valid && (m0_target == TARGET_DEC)) begin
                        dm0_held_id    <= {1'b0, m0_head_id};
                        dm0_held_addr  <= m0_head_addr;
                        dm0_held_len   <= m0_head_len;
                        dm0_held_size  <= m0_head_size;
                        dm0_held_burst <= m0_head_burst;
                        dm0_state      <= AW_ACTIVE;
                    end
                end
                AW_ACTIVE: begin
                    // Wait until dummy slave accepts (dm_awready=1)
                    if (dm_awready && dm_awvalid_int && dm_held_id_int == dm0_held_id)
                        dm0_state <= AW_IDLE;
                end
                default: dm0_state <= AW_IDLE;
            endcase

            // M1 DECERR FSM
            case (dm1_state)
                AW_IDLE: begin
                    if (m1_fifo_rd_valid && (m1_target == TARGET_DEC) &&
                        (dm0_state == AW_IDLE)) begin  // M0 DECERR has priority
                        dm1_held_id    <= {1'b1, m1_head_id};
                        dm1_held_addr  <= m1_head_addr;
                        dm1_held_len   <= m1_head_len;
                        dm1_held_size  <= m1_head_size;
                        dm1_held_burst <= m1_head_burst;
                        dm1_state      <= AW_ACTIVE;
                    end
                end
                AW_ACTIVE: begin
                    if (dm_awready && dm_awvalid_int && dm_held_id_int == dm1_held_id)
                        dm1_state <= AW_IDLE;
                end
                default: dm1_state <= AW_IDLE;
            endcase
        end
    end

    // Mux: M0 DECERR has priority over M1 DECERR
    always_comb begin
        dm_awvalid_int    = 1'b0;
        dm_held_id_int    = '0;
        dm_held_addr_int  = '0;
        dm_held_len_int   = '0;
        dm_held_size_int  = '0;
        dm_held_burst_int = '0;

        if (dm0_state == AW_ACTIVE) begin
            dm_awvalid_int    = 1'b1;
            dm_held_id_int    = dm0_held_id;
            dm_held_addr_int  = dm0_held_addr;
            dm_held_len_int   = dm0_held_len;
            dm_held_size_int  = dm0_held_size;
            dm_held_burst_int = dm0_held_burst;
        end else if (dm1_state == AW_ACTIVE) begin
            dm_awvalid_int    = 1'b1;
            dm_held_id_int    = dm1_held_id;
            dm_held_addr_int  = dm1_held_addr;
            dm_held_len_int   = dm1_held_len;
            dm_held_size_int  = dm1_held_size;
            dm_held_burst_int = dm1_held_burst;
        end
    end

    // Drive dummy slave AW port
    assign dm_awid    = dm_held_id_int;
    assign dm_awaddr  = dm_held_addr_int;
    assign dm_awlen   = dm_held_len_int;
    assign dm_awsize  = dm_held_size_int;
    assign dm_awburst = dm_held_burst_int;
    assign dm_awvalid = dm_awvalid_int;

    // STEP 8: AW FIFO pop control
    // Pop a master's AW FIFO when its AW transaction is accepted:
    // For valid slave:   when AW FSM latches the grant (IDLE TO ACTIVE)
    // For DECERR:    when DECERR FSM latches the entry (IDLE TO ACTIVE)
    always_comb begin
        m0_fifo_rd_ready = 1'b0;
        m1_fifo_rd_ready = 1'b0;

        // M0: pop when S0 FSM latches M0's grant
        if ((s0_state == AW_IDLE) && grant_s0[0])
            m0_fifo_rd_ready = 1'b1;

        // M0: pop when S1 FSM latches M0's grant
        if ((s1_state == AW_IDLE) && grant_s1[0])
            m0_fifo_rd_ready = 1'b1;
        
        // M0: pop when DECERR FSM latches M0's bad address
        if ((dm0_state == AW_IDLE) && m0_fifo_rd_valid && (m0_target == TARGET_DEC))
            m0_fifo_rd_ready = 1'b1;

        
        // M1: pop when S0 FSM latches M1's grant
        if ((s0_state == AW_IDLE) && grant_s0[1])
            m1_fifo_rd_ready = 1'b1;
        
        // M1: pop when S1 FSM latches M1's grant
        if ((s1_state == AW_IDLE) && grant_s1[1])
            m1_fifo_rd_ready = 1'b1;
        
        // M1: pop when DECERR FSM latches M1's bad address
        if ((dm1_state == AW_IDLE) && m1_fifo_rd_valid && (m1_target == TARGET_DEC) && (dm0_state == AW_IDLE))
            m1_fifo_rd_ready = 1'b1;
    end

    // STEP 9: W-order tracker output
    // M0 W-order: push when M0's AW is latched by any FSM
    logic m0_worder_push, m1_worder_push;

    assign m0_worder_push = (
        ((s0_state == AW_IDLE) && grant_s0[0]) ||
        ((s1_state == AW_IDLE) && grant_s1[0]) ||
        ((dm0_state == AW_IDLE) && m0_fifo_rd_valid && (m0_target == TARGET_DEC))
    );

    assign m1_worder_push = (
        ((s0_state == AW_IDLE) && grant_s0[1]) ||
        ((s1_state == AW_IDLE) && grant_s1[1]) ||
        ((dm1_state == AW_IDLE) && m1_fifo_rd_valid && (m1_target == TARGET_DEC)
         && (dm0_state == AW_IDLE))
    );

    // Build W-order data
    always_comb begin
        // M0
        m0_worder_valid = m0_worder_push;
        if (m0_target == TARGET_DEC)
            m0_worder_data = {1'b1, 2'b10, m0_head_len};
        else
            m0_worder_data = {1'b0, 2'(m0_target[1:0]), m0_head_len};

        // M1
        m1_worder_valid = m1_worder_push;
        if (m1_target == TARGET_DEC)
            m1_worder_data = {1'b1, 2'b10, m1_head_len};
        else
            m1_worder_data = {1'b0, 2'(m1_target[1:0]), m1_head_len};
    end


endmodule
