class axi_monitor #(int MASTER_ID = 0);
  virtual axi_if axi_intf;
  mailbox in_mon2ref_mb;
  mailbox out_mon2scb_mb;

  axi_transaction aw_q[$];
  axi_transaction w_q[$];

  function new(virtual axi_if axi_intf,
               mailbox in_mon2ref_mb,
               mailbox out_mon2scb_mb);
    $display("@[%0t] :: INSIDE AXI MONITOR CONSTRUCTOR M%0d", $time, MASTER_ID);
    this.axi_intf       = axi_intf;
    this.in_mon2ref_mb  = in_mon2ref_mb;
    this.out_mon2scb_mb = out_mon2scb_mb;
  endfunction

  task start_ready_control();
    wait(axi_intf.rst_n == 1'b1);
    forever begin
      @(posedge axi_intf.clk);
      if (MASTER_ID == 0) begin
        if (axi_intf.m0_b_stall_cycles > 0) begin
          axi_intf.m0_bready <= 1'b0;
          axi_intf.m0_b_stall_cycles = axi_intf.m0_b_stall_cycles - 1;
        end else axi_intf.m0_bready <= 1'b1;
        if (axi_intf.m0_r_stall_cycles > 0) begin
          axi_intf.m0_rready <= 1'b0;
          axi_intf.m0_r_stall_cycles = axi_intf.m0_r_stall_cycles - 1;
        end else axi_intf.m0_rready <= 1'b1;
      end
      else begin
        if (axi_intf.m1_b_stall_cycles > 0) begin
          axi_intf.m1_bready <= 1'b0;
          axi_intf.m1_b_stall_cycles = axi_intf.m1_b_stall_cycles - 1;
        end else axi_intf.m1_bready <= 1'b1;
        if (axi_intf.m1_r_stall_cycles > 0) begin
          axi_intf.m1_rready <= 1'b0;
          axi_intf.m1_r_stall_cycles = axi_intf.m1_r_stall_cycles - 1;
        end else axi_intf.m1_rready <= 1'b1;
      end
    end
  endtask

  task input_aw_capture();
    axi_transaction tr;
    wait(axi_intf.rst_n == 1'b1);
    forever begin
      @(posedge axi_intf.clk);
      if (MASTER_ID == 0) begin
        if (axi_intf.m0_awvalid && axi_intf.m0_awready) begin
          tr = new();
          tr.trans_kind = axi_transaction::WRITE_REQ;
          tr.master = axi_transaction::MASTER0;
          tr.id = axi_intf.m0_awid; 
          tr.addr = axi_intf.m0_awaddr; 
          tr.len = axi_intf.m0_awlen;
          tr.size = axi_intf.m0_awsize; 
          tr.burst = axi_intf.m0_awburst;
          aw_q.push_back(tr);
          $display("@[%0t] :: [M0 IN_MON] AW ID=%0h ADDR=%h LEN=%0d", $time, tr.id, tr.addr, tr.len);
        end
      end else begin
        if (axi_intf.m1_awvalid && axi_intf.m1_awready) begin
          tr = new();
          tr.trans_kind = axi_transaction::WRITE_REQ;
          tr.master = axi_transaction::MASTER1;
          tr.id = axi_intf.m1_awid; 
          tr.addr = axi_intf.m1_awaddr; 
          tr.len = axi_intf.m1_awlen;
          tr.size = axi_intf.m1_awsize; 
          tr.burst = axi_intf.m1_awburst;
          aw_q.push_back(tr);
          $display("@[%0t] :: [M1 IN_MON] AW ID=%0h ADDR=%h LEN=%0d", $time, tr.id, tr.addr, tr.len);
        end
      end
    end
  endtask

  task input_w_capture();
    axi_transaction tr;
    wait(axi_intf.rst_n == 1'b1);
    forever begin
      tr = new();
      tr.trans_kind = axi_transaction::WRITE_REQ;
      tr.master = (MASTER_ID == 0) ? axi_transaction::MASTER0 : axi_transaction::MASTER1;
      do begin
        @(posedge axi_intf.clk);
        if (MASTER_ID == 0) begin
          if (axi_intf.m0_wvalid && axi_intf.m0_wready) begin
            tr.wdata_q.push_back(axi_intf.m0_wdata);
            tr.wstrb_q.push_back(axi_intf.m0_wstrb);
            tr.data = axi_intf.m0_wdata;
            if (axi_intf.m0_wlast) begin w_q.push_back(tr); break; end
          end
        end else begin
          if (axi_intf.m1_wvalid && axi_intf.m1_wready) begin
            tr.wdata_q.push_back(axi_intf.m1_wdata);
            tr.wstrb_q.push_back(axi_intf.m1_wstrb);
            tr.data = axi_intf.m1_wdata;
            if (axi_intf.m1_wlast) begin w_q.push_back(tr); break; end
          end
        end
      end while (1);
      $display("@[%0t] :: [M%0d IN_MON] W BURST BEATS=%0d", $time, MASTER_ID, tr.wdata_q.size());
    end
  endtask

  task input_write_combine();
    axi_transaction aw_tr, w_tr, tr;
    forever begin
      wait(aw_q.size() > 0 && w_q.size() > 0);
      aw_tr = aw_q.pop_front();
      w_tr  = w_q.pop_front();
      tr = aw_tr.copy();
      tr.wdata_q.delete(); tr.wstrb_q.delete();
      foreach (w_tr.wdata_q[i]) tr.wdata_q.push_back(w_tr.wdata_q[i]);
      foreach (w_tr.wstrb_q[i]) tr.wstrb_q.push_back(w_tr.wstrb_q[i]);
      if (tr.wdata_q.size() > 0) tr.data = tr.wdata_q[0];
      in_mon2ref_mb.put(tr);
      $display("@[%0t] :: [M%0d IN_MON] WRITE_REQ SENT TO REF", $time, MASTER_ID);
    end
  endtask

  task input_ar_capture();
    axi_transaction tr;
    wait(axi_intf.rst_n == 1'b1);
    forever begin
      @(posedge axi_intf.clk);
      if (MASTER_ID == 0) begin
        if (axi_intf.m0_arvalid && axi_intf.m0_arready) begin
          tr = new(); 
          tr.trans_kind = axi_transaction::READ_REQ; 
          tr.master = axi_transaction::MASTER0;
          tr.id = axi_intf.m0_arid; 
          tr.addr = axi_intf.m0_araddr; 
          tr.len = axi_intf.m0_arlen;
          tr.size = axi_intf.m0_arsize; 
          tr.burst = axi_intf.m0_arburst;
          in_mon2ref_mb.put(tr);
          $display("@[%0t] :: [M0 IN_MON] READ_REQ sent to REF id=%0h addr=%h", $time, tr.id, tr.addr);
        end
      end else begin
        if (axi_intf.m1_arvalid && axi_intf.m1_arready) begin
          tr = new(); 
          tr.trans_kind = axi_transaction::READ_REQ; 
          tr.master = axi_transaction::MASTER1;
          tr.id = axi_intf.m1_arid; 
          tr.addr = axi_intf.m1_araddr; 
          tr.len = axi_intf.m1_arlen;
          tr.size = axi_intf.m1_arsize; 
          tr.burst = axi_intf.m1_arburst;
          in_mon2ref_mb.put(tr);
          $display("@[%0t] :: [M1 IN_MON] READ_REQ sent to REF id=%0h addr=%h", $time, tr.id, tr.addr);
        end
      end
    end
  endtask

  task output_b_capture();
    axi_transaction tr;
    wait(axi_intf.rst_n == 1'b1);
    forever begin
      @(posedge axi_intf.clk);
      if (MASTER_ID == 0) begin
        if (axi_intf.m0_bvalid && axi_intf.m0_bready) begin
          tr = new(); 
          tr.trans_kind = axi_transaction::WRITE_RSP; 
          tr.master = axi_transaction::MASTER0;
          tr.rid_bid = axi_intf.m0_bid; 
          tr.resp = axi_intf.m0_bresp;
          out_mon2scb_mb.put(tr);
          $display("@[%0t] :: [M0 OUT_MON] B ACTUAL BID=%0h RESP=%0b", $time, tr.rid_bid, tr.resp);
        end
      end else begin
        if (axi_intf.m1_bvalid && axi_intf.m1_bready) begin
          tr = new(); 
          tr.trans_kind = axi_transaction::WRITE_RSP; 
          tr.master = axi_transaction::MASTER1;
          tr.rid_bid = axi_intf.m1_bid; 
          tr.resp = axi_intf.m1_bresp;
          out_mon2scb_mb.put(tr);
          $display("@[%0t] :: [M1 OUT_MON] B ACTUAL BID=%0h RESP=%0b", $time, tr.rid_bid, tr.resp);
        end
      end
    end
  endtask

  task output_r_capture();
    axi_transaction tr;
    wait(axi_intf.rst_n == 1'b1);
    forever begin
      tr = new(); tr.trans_kind = axi_transaction::READ_RSP;
      tr.master = (MASTER_ID == 0) ? axi_transaction::MASTER0 : axi_transaction::MASTER1;
      do begin
        @(posedge axi_intf.clk);
        if (MASTER_ID == 0) begin
          if (axi_intf.m0_rvalid && axi_intf.m0_rready) begin
            tr.rid_bid = axi_intf.m0_rid; 
            tr.rdata_q.push_back(axi_intf.m0_rdata); 
            tr.rresp_q.push_back(axi_intf.m0_rresp);
            tr.rdata = axi_intf.m0_rdata; 
            tr.resp = axi_intf.m0_rresp; 
            tr.last = axi_intf.m0_rlast;
            if (axi_intf.m0_rlast) begin 
              out_mon2scb_mb.put(tr); break; 
            end
          end
        end else begin
          if (axi_intf.m1_rvalid && axi_intf.m1_rready) begin
            tr.rid_bid = axi_intf.m1_rid; 
            tr.rdata_q.push_back(axi_intf.m1_rdata); 
            tr.rresp_q.push_back(axi_intf.m1_rresp);
            tr.rdata = axi_intf.m1_rdata; 
            tr.resp = axi_intf.m1_rresp; 
            tr.last = axi_intf.m1_rlast;
            if (axi_intf.m1_rlast) 
              begin out_mon2scb_mb.put(tr); break; 
            end
          end
        end
      end while (1);
      $display("@[%0t] :: [M%0d OUT_MON] R actual id=%0h beats=%0d", $time, MASTER_ID, tr.rid_bid, tr.rdata_q.size());
    end
  endtask

  task start_all();
    fork
      start_ready_control();
      input_aw_capture(); 
      input_w_capture(); 
      input_write_combine(); 
      input_ar_capture();
      output_b_capture(); 
      output_r_capture();
    join_none
  endtask
endclass

