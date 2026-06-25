module ar_dummy_slave
  import axi_crossbar_pkg::*;
(

  input logic clk,
  input logic rst_n,

  //AR port 
  input  logic [ID_WIDTH_S-1:0] s_arid,
  input  logic [LEN_WIDTH-1:0]  s_arlen,
  input  logic                  s_arvalid,
  output logic                  s_arready,

  //R output port
  output logic [ID_WIDTH_S-1:0] s_rid,
  output logic [DATA_WIDTH-1:0] s_rdata,
  output logic [1:0]            s_rresp,
  output logic                  s_rlast,
  output logic                  s_rvalid,
  input  logic                  s_rready

  );

 
  // AR order FIFO
  // Stores {arid, arlen} for each accepted AR
  localparam int AR_ORD_W = ID_WIDTH_S + LEN_WIDTH;
 
  logic                 af_wr_valid, af_wr_ready;
  logic [AR_ORD_W-1:0]  af_wr_data;
  logic                 af_rd_valid, af_rd_ready;
  logic [AR_ORD_W-1:0]  af_rd_data;
 
  axi_fifo #(.WIDTH(AR_ORD_W), .DEPTH(AR_FIFO_DEPTH)) u_ar_ord (
        .clk(clk), 
        .rst_n(rst_n),
        .wr_data(af_wr_data), 
        .wr_valid(af_wr_valid), 
        .wr_ready(af_wr_ready),
        .rd_data(af_rd_data), 
        .rd_valid(af_rd_valid), 
        .rd_ready(af_rd_ready)
  );


  // AR port: accept as long as order FIFO is not full
  assign s_arready  = af_wr_ready;
  assign af_wr_valid = s_arvalid;
  assign af_wr_data  = {s_arid, s_arlen};
 
  //R fills FSM
  typedef enum logic [1:0] {
    RF_IDLE  = 2'b00,
    RF_BEATS = 2'b01
  } rfill_state_e;
 
  rfill_state_e          rf_state;
  logic [LEN_WIDTH-1:0]  beat_cnt;    // beats remaining (0 = last beat)
  logic [ID_WIDTH_S-1:0] held_rid;
 
  // Pop AR order FIFO when latched in IDLE
  assign af_rd_ready = (rf_state == RF_IDLE) && af_rd_valid;
 

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rf_state  <= RF_IDLE;
      beat_cnt  <= '0;
      held_rid  <= '0;

    end else case (rf_state)

      RF_IDLE: begin
        if (af_rd_valid) begin

          held_rid  <= af_rd_data[AR_ORD_W-1 : LEN_WIDTH];
          beat_cnt  <= af_rd_data[LEN_WIDTH-1 : 0];
          rf_state  <= RF_BEATS;
        end
      end
 
      RF_BEATS: begin

        // Advance only when downstream accepts this beat
        if (s_rready) begin
          if (beat_cnt == '0) begin
            // Was last beat (RLAST asserted this cycle)
            rf_state <= RF_IDLE;
          end else begin
            beat_cnt <= beat_cnt - 1'b1;
          end
        end
      end
 
      default: rf_state <= RF_IDLE;
    endcase
  end
 
  //Drive R outputs 
  assign s_rvalid = (rf_state == RF_BEATS);
  assign s_rid    = held_rid;
  assign s_rdata  = '0;                          // data irrelevant on DECERR
  assign s_rresp  = RESP_DECERR;
  assign s_rlast  = (rf_state == RF_BEATS) && (beat_cnt == '0);
 
endmodule
  
