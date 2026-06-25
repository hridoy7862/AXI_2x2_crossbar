module aw_dummy_slave
    import axi_crossbar_pkg::*;
(
    input  logic                clk,
    input  logic                rst_n,

    input  logic [ID_WIDTH_S-1:0]   s_awid,     // 5-bit tagged ID
    input  logic [ADDR_WIDTH-1:0]   s_awaddr,   // bad address (unused but kept for debug)
    input  logic [LEN_WIDTH-1:0]    s_awlen,    // burst length
    input  logic [SIZE_WIDTH-1:0]   s_awsize,
    input  logic [1:0]              s_awburst,
    input  logic                    s_awvalid,
    output logic                    s_awready,

    input  logic [DATA_WIDTH-1:0]   s_wdata,    // discarded
    input  logic [STRB_WIDTH-1:0]   s_wstrb,    // discarded
    input  logic                    s_wlast,
    input  logic                    s_wvalid,
    output logic                    s_wready,

    output logic [ID_WIDTH_S-1:0]   s_bid,
    output logic [1:0]              s_bresp,
    output logic                    s_bvalid,
    input  logic                    s_bready
);

    localparam int AW_ORD_W = ID_WIDTH_S + LEN_WIDTH;

    logic                   aw_fifo_wr_valid;
    logic                   aw_fifo_wr_ready;
    logic [AW_ORD_W-1:0]    aw_fifo_wr_data;
    logic                   aw_fifo_rd_valid;
    logic                   aw_fifo_rd_ready;
    logic [AW_ORD_W-1:0]    aw_fifo_rd_data;

    axi_fifo #(
        .WIDTH (AW_ORD_W),
        .DEPTH (AW_FIFO_DEPTH)
    ) u_aw_ord_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_data  (aw_fifo_wr_data),
        .wr_valid (aw_fifo_wr_valid),
        .wr_ready (aw_fifo_wr_ready),
        .rd_data  (aw_fifo_rd_data),
        .rd_valid (aw_fifo_rd_valid),
        .rd_ready (aw_fifo_rd_ready)
    );

    assign s_awready        = aw_fifo_wr_ready;
    assign aw_fifo_wr_valid = s_awvalid;
    assign aw_fifo_wr_data  = {s_awid, s_awlen};

    typedef enum logic [1:0] {
        DRAIN_IDLE  = 2'b00,
        DRAIN_BEATS = 2'b01
    } drain_state_e;

    drain_state_e            drain_state;
    logic [LEN_WIDTH-1:0]    beat_cnt;       // counts remaining beats
    logic [ID_WIDTH_S-1:0]   held_awid;      // saved ID for B response
    logic                    wlast_seen;      // trigger B response

    
    
    assign s_wready = (drain_state == DRAIN_BEATS);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            drain_state  <= DRAIN_IDLE;
            beat_cnt     <= '0;
            held_awid    <= '0;
            wlast_seen   <= 1'b0;
        end else begin
            wlast_seen <= 1'b0;  // default: no WLAST this cycle

            case (drain_state)

                DRAIN_IDLE: begin
                    // Wait until an AW order entry is available
                    if (aw_fifo_rd_valid) begin
                        held_awid   <= aw_fifo_rd_data[AW_ORD_W-1 : LEN_WIDTH];
                        beat_cnt    <= aw_fifo_rd_data[LEN_WIDTH-1 : 0];
                        drain_state <= DRAIN_BEATS;
                    end
                end

                DRAIN_BEATS: begin
                    // W beats arrive - just count them, discard data
                    if (s_wvalid) begin
                        if (s_wlast || beat_cnt == '0) begin
                            // Last beat of this burst
                            wlast_seen  <= 1'b1;   // trigger B gen
                            drain_state <= DRAIN_IDLE;
                        end else begin
                            beat_cnt <= beat_cnt - 1'b1;
                        end
                    end
                end

                default: drain_state <= DRAIN_IDLE;
            endcase
        end
    end

    // Pop AW order FIFO when we latch it in IDLE state
    assign aw_fifo_rd_ready = (drain_state == DRAIN_IDLE) && aw_fifo_rd_valid;

    localparam int B_PKT_W = ID_WIDTH_S + 2;  // BID + BRESP

    logic               b_fifo_wr_valid;
    logic               b_fifo_wr_ready;
    logic [B_PKT_W-1:0] b_fifo_wr_data;
    logic               b_fifo_rd_valid;
    logic               b_fifo_rd_ready;
    logic [B_PKT_W-1:0] b_fifo_rd_data;

    axi_fifo #(
        .WIDTH (B_PKT_W),
        .DEPTH (B_FIFO_DEPTH)
    ) u_b_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_data  (b_fifo_wr_data),
        .wr_valid (b_fifo_wr_valid),
        .wr_ready (b_fifo_wr_ready),
        .rd_data  (b_fifo_rd_data),
        .rd_valid (b_fifo_rd_valid),
        .rd_ready (b_fifo_rd_ready)
    );

    // Push: only after WLAST seen, carry the saved AWID
    assign b_fifo_wr_valid = wlast_seen;
    assign b_fifo_wr_data  = {held_awid, RESP_DECERR};

    // Drive B outputs directly from B FIFO
    assign s_bvalid           = b_fifo_rd_valid;
    assign {s_bid, s_bresp}   = b_fifo_rd_data;
    assign b_fifo_rd_ready    = s_bready;

endmodule
