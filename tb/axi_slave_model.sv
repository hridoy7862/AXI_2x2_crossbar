class axi_slave_aw_info;
  import axi_crossbar_pkg::*;
  logic [ID_WIDTH_S-1:0] id;
  logic [ADDR_WIDTH-1:0] addr;
  logic [LEN_WIDTH-1:0]  len;
endclass

class axi_slave_wburst;
  import axi_crossbar_pkg::*;
  logic [DATA_WIDTH-1:0] data_q[$];
  logic [STRB_WIDTH-1:0] strb_q[$];
endclass

module axi_slave_model
  import axi_crossbar_pkg::*;
#(parameter int SLAVE_ID = 0)
(
  input  logic clk,
  input  logic rst_n,

  input  logic [ID_WIDTH_S-1:0] s_awid,
  input  logic [ADDR_WIDTH-1:0] s_awaddr,
  input  logic [LEN_WIDTH-1:0]  s_awlen,
  input  logic [SIZE_WIDTH-1:0] s_awsize,
  input  logic [1:0]            s_awburst,
  input  logic                  s_awvalid,
  output logic                  s_awready,

  input  logic [DATA_WIDTH-1:0] s_wdata,
  input  logic [STRB_WIDTH-1:0] s_wstrb,
  input  logic                  s_wlast,
  input  logic                  s_wvalid,
  output logic                  s_wready,

  output logic [ID_WIDTH_S-1:0] s_bid,
  output logic [1:0]            s_bresp,
  output logic                  s_bvalid,
  input  logic                  s_bready,

  input  logic [ID_WIDTH_S-1:0] s_arid,
  input  logic [ADDR_WIDTH-1:0] s_araddr,
  input  logic [LEN_WIDTH-1:0]  s_arlen,
  input  logic [SIZE_WIDTH-1:0] s_arsize,
  input  logic [1:0]            s_arburst,
  input  logic                  s_arvalid,
  output logic                  s_arready,

  output logic [ID_WIDTH_S-1:0] s_rid,
  output logic [DATA_WIDTH-1:0] s_rdata,
  output logic [1:0]            s_rresp,
  output logic                  s_rlast,
  output logic                  s_rvalid,
  input  logic                  s_rready,

  input int aw_stall_cycles,
  input int w_stall_cycles,
  input int ar_stall_cycles,
  input int r_delay_cycles
);


  always @(posedge clk) begin
    if (rst_n) begin
      if (vif.s0_aw_stall_cycles > 0) vif.s0_aw_stall_cycles = vif.s0_aw_stall_cycles - 1;
      if (vif.s0_w_stall_cycles  > 0) vif.s0_w_stall_cycles  = vif.s0_w_stall_cycles  - 1;
      if (vif.s0_ar_stall_cycles > 0) vif.s0_ar_stall_cycles = vif.s0_ar_stall_cycles - 1;
      if (vif.s1_aw_stall_cycles > 0) vif.s1_aw_stall_cycles = vif.s1_aw_stall_cycles - 1;
      if (vif.s1_w_stall_cycles  > 0) vif.s1_w_stall_cycles  = vif.s1_w_stall_cycles  - 1;
      if (vif.s1_ar_stall_cycles > 0) vif.s1_ar_stall_cycles = vif.s1_ar_stall_cycles - 1;
    end
  end


  logic [DATA_WIDTH-1:0] mem [logic [ADDR_WIDTH-1:0]];

  axi_slave_aw_info aw_q[$];
  axi_slave_wburst  wb_q[$];
  axi_slave_wburst  cur_wb;

  logic [ID_WIDTH_S-1:0] arid_q;
  logic [ADDR_WIDTH-1:0] araddr_q;
  logic [LEN_WIDTH-1:0]  arlen_q;
  int                    r_count;
  int                    r_delay_cnt;
  logic                  r_pending;

  function automatic logic [DATA_WIDTH-1:0] default_data(input logic [ADDR_WIDTH-1:0] a);
    default_data = (SLAVE_ID == 0) ? (32'h5000_0000 ^ a) : (32'hA000_0000 ^ a);
  endfunction

  function automatic logic [DATA_WIDTH-1:0] apply_strobe(
      input logic [DATA_WIDTH-1:0] old_data,
      input logic [DATA_WIDTH-1:0] new_data,
      input logic [STRB_WIDTH-1:0] strobe);
    logic [DATA_WIDTH-1:0] result;
    int i;
    begin
      result = old_data;
      for (i = 0; i < STRB_WIDTH; i++) begin
        if (strobe[i]) result[i*8 +: 8] = new_data[i*8 +: 8];
      end
      return result;
    end
  endfunction

  assign s_awready = (aw_stall_cycles == 0);
  assign s_wready  = (w_stall_cycles  == 0);
  assign s_arready = (ar_stall_cycles == 0) && !r_pending;

  task automatic try_process_write();
    axi_slave_aw_info aw;
    axi_slave_wburst  wb;
    logic [ADDR_WIDTH-1:0] beat_addr;
    logic [DATA_WIDTH-1:0] old_data;
    int i;
    begin
      if (!s_bvalid && aw_q.size() > 0 && wb_q.size() > 0) begin
        aw = aw_q.pop_front();
        wb = wb_q.pop_front();
        for (i = 0; i < wb.data_q.size(); i++) begin
          beat_addr = aw.addr + (i * 4);
          old_data = mem.exists(beat_addr) ? mem[beat_addr] : default_data(beat_addr);
          mem[beat_addr] = apply_strobe(old_data, wb.data_q[i], wb.strb_q[i]);
          $display("@[%0t] :: [SLV%0d] WRITE beat=%0d addr=%h data=%h", $time, SLAVE_ID, i, beat_addr, wb.data_q[i]);
        end
        s_bid    <= aw.id;
        s_bresp  <= RESP_OKAY;
        s_bvalid <= 1'b1;
      end
    end
  endtask

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_bid <= '0; 
      s_bresp <= RESP_OKAY; 
      s_bvalid <= 1'b0;
      arid_q <= '0; 
      araddr_q <= '0; 
      arlen_q <= '0; 
      r_count <= 0; 
      r_delay_cnt <= 0; 
      r_pending <= 1'b0;
      s_rid <= '0; 
      s_rdata <= '0; 
      s_rresp <= RESP_OKAY; 
      s_rlast <= 1'b0; 
      s_rvalid <= 1'b0;
      aw_q.delete(); wb_q.delete(); cur_wb = new();
    end
    else begin
      if (cur_wb == null) cur_wb = new();

      if (s_awvalid && s_awready) begin
        axi_slave_aw_info aw;
        aw = new();
        aw.id = s_awid; aw.addr = s_awaddr; aw.len = s_awlen;
        aw_q.push_back(aw);
        $display("@[%0t] :: [SLV%0d] AW id=%h addr=%h len=%0d", $time, SLAVE_ID, s_awid, s_awaddr, s_awlen);
      end

      if (s_wvalid && s_wready) begin
        cur_wb.data_q.push_back(s_wdata);
        cur_wb.strb_q.push_back(s_wstrb);
        $display("@[%0t] :: [SLV%0d] W data=%h last=%b", $time, SLAVE_ID, s_wdata, s_wlast);
        if (s_wlast) begin
          wb_q.push_back(cur_wb);
          cur_wb = new();
        end
      end

      try_process_write();

      if (s_bvalid && s_bready) begin
        s_bvalid <= 1'b0;
        $display("@[%0t] :: [SLV%0d] B handshake bid=%h", $time, SLAVE_ID, s_bid);
      end

      if (s_arvalid && s_arready) begin
        arid_q      <= s_arid;
        araddr_q    <= s_araddr;
        arlen_q     <= s_arlen;
        r_count     <= 0;
        r_delay_cnt <= r_delay_cycles;
        r_pending   <= 1'b1;
        $display("@[%0t] :: [SLV%0d] AR id=%h addr=%h len=%0d", $time, SLAVE_ID, s_arid, s_araddr, s_arlen);
      end

      if (r_pending && !s_rvalid) begin
        if (r_delay_cnt > 0) r_delay_cnt <= r_delay_cnt - 1;
        else begin
          logic [ADDR_WIDTH-1:0] beat_addr;
          beat_addr = araddr_q + (r_count * 4);
          s_rid    <= arid_q;
          s_rdata  <= mem.exists(beat_addr) ? mem[beat_addr] : default_data(beat_addr);
          s_rresp  <= RESP_OKAY;
          s_rlast  <= (r_count == int'(arlen_q));
          s_rvalid <= 1'b1;
        end
      end

      if (s_rvalid && s_rready) begin
        $display("@[%0t] :: [SLV%0d] R beat=%0d data=%h last=%b", $time, SLAVE_ID, r_count, s_rdata, s_rlast);
        if (s_rlast) begin
          s_rvalid  <= 1'b0;
          s_rlast   <= 1'b0;
          r_pending <= 1'b0;
        end
        else begin
          s_rvalid <= 1'b0;
          r_count  <= r_count + 1;
        end
      end
    end
  end
endmodule

