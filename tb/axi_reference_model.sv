class axi_reference_model;
  import axi_crossbar_pkg::*;

  mailbox in_mon2ref_mb;
  mailbox ref2scb_mb;
  axi_transaction in_item;
  axi_transaction exp_item;

  logic [DATA_WIDTH-1:0] s0_mem [logic [ADDR_WIDTH-1:0]];
  logic [DATA_WIDTH-1:0] s1_mem [logic [ADDR_WIDTH-1:0]];

  function new(mailbox in_mon2ref_mb, mailbox ref2scb_mb);
    $display("@[%0t] :: INSIDE AXI REFERENCE MODEL CONSTRUCTOR", $time);
    this.in_mon2ref_mb = in_mon2ref_mb;
    this.ref2scb_mb    = ref2scb_mb;
  endfunction

  function axi_transaction::slave_e decode(input logic [ADDR_WIDTH-1:0] addr);
    if (addr >= S0_BASE && addr <= S0_HIGH) return axi_transaction::SLAVE0;
    else if (addr >= S1_BASE && addr <= S1_HIGH) return axi_transaction::SLAVE1;
    else return axi_transaction::SLAVE_DECERR;
  endfunction

  function automatic logic [DATA_WIDTH-1:0] default_data(input axi_transaction::slave_e slave,
                                                         input logic [ADDR_WIDTH-1:0] addr);
    if (slave == axi_transaction::SLAVE0) return (32'h5000_0000 ^ addr);
    else return (32'hA000_0000 ^ addr);
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

  task process_write(axi_transaction tr);
    axi_transaction::slave_e target;
    logic [ADDR_WIDTH-1:0] beat_addr;
    logic [DATA_WIDTH-1:0] old_data;
    int i;
    target = decode(tr.addr);
    exp_item = new();
    exp_item.trans_kind = axi_transaction::WRITE_RSP;
    exp_item.master     = tr.master;
    exp_item.id         = tr.id;
    exp_item.rid_bid    = tr.id;
    exp_item.addr       = tr.addr;
    exp_item.resp       = (target == axi_transaction::SLAVE_DECERR) ? RESP_DECERR : RESP_OKAY;

    if (target != axi_transaction::SLAVE_DECERR) begin
      for (i = 0; i < tr.wdata_q.size(); i++) begin
        beat_addr = tr.addr + (i * 4);
        if (target == axi_transaction::SLAVE0) begin
          old_data = s0_mem.exists(beat_addr) ? s0_mem[beat_addr] : default_data(target, beat_addr);
          s0_mem[beat_addr] = apply_strobe(old_data, tr.wdata_q[i], tr.wstrb_q[i]);
        end else begin
          old_data = s1_mem.exists(beat_addr) ? s1_mem[beat_addr] : default_data(target, beat_addr);
          s1_mem[beat_addr] = apply_strobe(old_data, tr.wdata_q[i], tr.wstrb_q[i]);
        end
      end
    end

    ref2scb_mb.put(exp_item);
    $display("@[%0t] :: [REF] Expected WRITE_RSP M=%0d BID=%0h RESP=%0b", $time, exp_item.master, exp_item.rid_bid, exp_item.resp);
  endtask

  task process_read(axi_transaction tr);
    axi_transaction::slave_e target;
    logic [ADDR_WIDTH-1:0] beat_addr;
    int i;
    target = decode(tr.addr);
    exp_item = new();
    exp_item.trans_kind = axi_transaction::READ_RSP;
    exp_item.master     = tr.master;
    exp_item.id         = tr.id;
    exp_item.rid_bid    = tr.id;
    exp_item.addr       = tr.addr;
    exp_item.len        = tr.len;
    exp_item.resp       = (target == axi_transaction::SLAVE_DECERR) ? RESP_DECERR : RESP_OKAY;

    for (i = 0; i < tr.num_beats(); i++) begin
      beat_addr = tr.addr + (i * 4);
      if (target == axi_transaction::SLAVE_DECERR) begin
        exp_item.rdata_q.push_back('0);
        exp_item.rresp_q.push_back(RESP_DECERR);
      end else if (target == axi_transaction::SLAVE0) begin
        exp_item.rdata_q.push_back(s0_mem.exists(beat_addr) ? s0_mem[beat_addr] : default_data(target, beat_addr));
        exp_item.rresp_q.push_back(RESP_OKAY);
      end else begin
        exp_item.rdata_q.push_back(s1_mem.exists(beat_addr) ? s1_mem[beat_addr] : default_data(target, beat_addr));
        exp_item.rresp_q.push_back(RESP_OKAY);
      end
    end
    if (exp_item.rdata_q.size() > 0) exp_item.rdata = exp_item.rdata_q[exp_item.rdata_q.size()-1];
    ref2scb_mb.put(exp_item);
    $display("@[%0t] :: [REF] Expected READ_RSP M=%0d RID=%0h beats=%0d RESP=%0b", $time, exp_item.master, exp_item.rid_bid, exp_item.rdata_q.size(), exp_item.resp);
  endtask

  task run();
    forever begin
      in_mon2ref_mb.get(in_item);
      if (in_item.trans_kind == axi_transaction::WRITE_REQ) process_write(in_item);
      else if (in_item.trans_kind == axi_transaction::READ_REQ) process_read(in_item);
    end
  endtask
endclass

