class axi_scoreboard;
  mailbox ref2scb_mb;
  mailbox out_mon2scb_mb;
  axi_transaction exp_item;
  axi_transaction act_item;
  int pass;
  int fail;

  axi_transaction exp_q[string][$];
  axi_transaction act_q[string][$];

  function new(mailbox ref2scb_mb, mailbox out_mon2scb_mb);
    $display("@[%0t] :: INSIDE AXI SCOREBOARD CONSTRUCTOR", $time);
    this.ref2scb_mb     = ref2scb_mb;
    this.out_mon2scb_mb = out_mon2scb_mb;
    pass = 0; fail = 0;
  endfunction

  function string key(axi_transaction tr);
    string k;
    k = $sformatf("%0d_%0d_%0h", tr.trans_kind, tr.master, tr.rid_bid);
    return k;
  endfunction

  function bit compare_items(axi_transaction exp, axi_transaction act);
    int i;
    if (exp.trans_kind != act.trans_kind) return 0;
    if (exp.master     != act.master)     return 0;
    if (exp.rid_bid    != act.rid_bid)    return 0;
    if (exp.resp       != act.resp)       return 0;
    if (exp.trans_kind == axi_transaction::WRITE_RSP) return 1;
    if (exp.rdata_q.size() != act.rdata_q.size()) return 0;
    for (i = 0; i < exp.rdata_q.size(); i++) begin
      if (exp.rdata_q[i] !== act.rdata_q[i]) return 0;
      if (exp.rresp_q[i] !== act.rresp_q[i]) return 0;
    end
    return 1;
  endfunction

  task compare_pair(axi_transaction exp, axi_transaction act);
    if (compare_items(exp, act)) begin
      pass++;
      $display("@[%0t] :: [SCB PASS] kind=%s M=%0d ID=%0h RESP=%0b beats=%0d",
               $time, exp.kind_name(), exp.master, exp.rid_bid, exp.resp, exp.rdata_q.size());
    end else begin
      fail++;
      $display("@[%0t] :: [SCB FAIL]", $time);
      exp.display("EXPECTED");
      act.display("ACTUAL");
    end
  endtask

  task process_expected();
    string k;
    forever begin
      ref2scb_mb.get(exp_item);
      k = key(exp_item);
      if (act_q.exists(k) && act_q[k].size() > 0) begin
        act_item = act_q[k].pop_front();
        compare_pair(exp_item, act_item);
      end else begin
        exp_q[k].push_back(exp_item);
      end
    end
  endtask

  task process_actual();
    string k;
    forever begin
      out_mon2scb_mb.get(act_item);
      k = key(act_item);
      if (exp_q.exists(k) && exp_q[k].size() > 0) begin
        exp_item = exp_q[k].pop_front();
        compare_pair(exp_item, act_item);
      end else begin
        act_q[k].push_back(act_item);
      end
    end
  endtask

  task compare();
    fork
      process_expected();
      process_actual();
    join_none
  endtask

  task report();
    $display("========================================================");
    $display("[AXI SCOREBOARD REPORT] PASS=%0d FAIL=%0d TOTAL=%0d", pass, fail, pass+fail);
    if (fail == 0) $display("[AXI SCOREBOARD REPORT] RESULT: PASS");
    else           $display("[AXI SCOREBOARD REPORT] RESULT: FAIL");
    $display("========================================================");
  endtask
endclass

