class axi_transaction;
  import axi_crossbar_pkg::*;

  typedef enum int {WRITE_REQ, READ_REQ, WRITE_RSP, READ_RSP} trans_kind_e;
  typedef enum bit {MASTER0 = 1'b0, MASTER1 = 1'b1} master_e;
  typedef enum logic [1:0] {SLAVE0 = 2'd0, SLAVE1 = 2'd1, SLAVE_DECERR = 2'd2} slave_e;

  rand trans_kind_e trans_kind;
  rand master_e     master;
  rand slave_e      slave;

  rand logic [ID_WIDTH-1:0]   id;
  rand logic [ADDR_WIDTH-1:0] addr;
  rand logic [LEN_WIDTH-1:0]  len;
  rand logic [SIZE_WIDTH-1:0] size;
  rand logic [1:0]            burst;

  rand logic [DATA_WIDTH-1:0] data;
  rand logic [STRB_WIDTH-1:0] strb;

  logic [ID_WIDTH-1:0]   rid_bid;
  logic [DATA_WIDTH-1:0] rdata;
  logic [1:0]            resp;
  logic                  last;

  logic [DATA_WIDTH-1:0] wdata_q[$];
  logic [STRB_WIDTH-1:0] wstrb_q[$];
  logic [DATA_WIDTH-1:0] rdata_q[$];
  logic [1:0]            rresp_q[$];

  constraint c_default {
    size == 3'd2;
    burst == 2'b01;
    strb == 4'hF;
    len inside {[0:3]};
    id inside {[0:15]};
  }

  constraint c_addr_by_slave {
    if (slave == SLAVE0) addr inside {[32'h0000_0000:32'h0FFF_FFFC]};
    if (slave == SLAVE1) addr inside {[32'h1000_0000:32'h1FFF_FFFC]};
    if (slave == SLAVE_DECERR) !(addr inside {[32'h0000_0000:32'h0FFF_FFFF]}) &&
                                !(addr inside {[32'h1000_0000:32'h1FFF_FFFF]});
    addr[1:0] == 2'b00;
  }

  function new();
    trans_kind = WRITE_REQ;
    master     = MASTER0;
    slave      = SLAVE0;
    id         = '0;
    addr       = '0;
    len        = 8'd0;
    size       = 3'd2;
    burst      = 2'b01;
    data       = '0;
    strb       = 4'hF;
    rid_bid    = '0;
    rdata      = '0;
    resp       = 2'b00;
    last       = 1'b1;
  endfunction

  function int num_beats();
    return int'(len) + 1;
  endfunction

  function void build_default_write_data();
    int i;
    wdata_q.delete();
    wstrb_q.delete();
    for (i = 0; i < num_beats(); i++) begin
      wdata_q.push_back(data + i);
      wstrb_q.push_back(strb);
    end
  endfunction

  function axi_transaction copy();
    axi_transaction c;
    int i;
    c = new();
    c.trans_kind = trans_kind;
    c.master     = master;
    c.slave      = slave;
    c.id         = id;
    c.addr       = addr;
    c.len        = len;
    c.size       = size;
    c.burst      = burst;
    c.data       = data;
    c.strb       = strb;
    c.rid_bid    = rid_bid;
    c.rdata      = rdata;
    c.resp       = resp;
    c.last       = last;
    c.wdata_q.delete(); c.wstrb_q.delete(); c.rdata_q.delete(); c.rresp_q.delete();
    foreach (wdata_q[i]) c.wdata_q.push_back(wdata_q[i]);
    foreach (wstrb_q[i]) c.wstrb_q.push_back(wstrb_q[i]);
    foreach (rdata_q[i]) c.rdata_q.push_back(rdata_q[i]);
    foreach (rresp_q[i]) c.rresp_q.push_back(rresp_q[i]);
    return c;
  endfunction

  function string kind_name();
    case (trans_kind)
      WRITE_REQ: return "WRITE_REQ";
      READ_REQ : return "READ_REQ";
      WRITE_RSP: return "WRITE_RSP";
      READ_RSP : return "READ_RSP";
      default  : return "UNKNOWN";
    endcase
  endfunction

  function void display(string tag);
    $display("@[%0t] :: [%s] kind=%s M=%0d S=%0d ID=%0h ADDR=%h LEN=%0d DATA=%h RESP=%0b RDATA=%h",
             $time, tag, kind_name(), master, slave, id, addr, len, data, resp, rdata);
  endfunction
endclass

