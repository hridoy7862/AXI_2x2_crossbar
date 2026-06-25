class axi_agent #(int MASTER_ID = 0);
  axi_driver    #(MASTER_ID) axi_drvr;
  axi_monitor   #(MASTER_ID) axi_mntr;
  axi_generator              axi_gen;
  semaphore sem;

  function new(virtual axi_if axi_intf,
               mailbox aw_gen2drv_mb,
               mailbox w_gen2drv_mb,
               mailbox ar_gen2drv_mb,
               mailbox in_mon2ref_mb,
               mailbox out_mon2scb_mb);
    $display("@[%0t] :: INSIDE AXI AGENT CONSTRUCTOR M%0d", $time, MASTER_ID);
    sem = new();
    axi_drvr = new(axi_intf, aw_gen2drv_mb, w_gen2drv_mb, ar_gen2drv_mb, sem);
    axi_mntr = new(axi_intf, in_mon2ref_mb, out_mon2scb_mb);
    axi_gen  = new(aw_gen2drv_mb, w_gen2drv_mb, ar_gen2drv_mb, sem);
  endfunction
endclass

