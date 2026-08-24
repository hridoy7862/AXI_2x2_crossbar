class axi_environment;
  axi_agent #(0) axi_m0_agnt;
  axi_agent #(1) axi_m1_agnt;
  axi_reference_model axi_ref;
  axi_scoreboard axi_scb;

  mailbox m0_aw_gen2drv_mb;
  mailbox m0_w_gen2drv_mb;
  mailbox m0_ar_gen2drv_mb;
  mailbox m1_aw_gen2drv_mb;
  mailbox m1_w_gen2drv_mb;
  mailbox m1_ar_gen2drv_mb;

  mailbox in_mon2ref_mb;
  mailbox ref2scb_mb;
  mailbox out_mon2scb_mb;

  function new(virtual axi_if axi_intf);
    $display("@[%0t] :: INSIDE AXI ENVIRONMENT CONSTRUCTOR", $time);
    m0_aw_gen2drv_mb = new(); 
    m0_w_gen2drv_mb = new(); 
    m0_ar_gen2drv_mb = new();
    m1_aw_gen2drv_mb = new(); 
    m1_w_gen2drv_mb = new(); 
    m1_ar_gen2drv_mb = new();
    in_mon2ref_mb    = new(); 
    ref2scb_mb = new(); 
    out_mon2scb_mb = new();

    axi_m0_agnt = new(axi_intf, m0_aw_gen2drv_mb, m0_w_gen2drv_mb, m0_ar_gen2drv_mb, in_mon2ref_mb, out_mon2scb_mb);
    axi_m1_agnt = new(axi_intf, m1_aw_gen2drv_mb, m1_w_gen2drv_mb, m1_ar_gen2drv_mb, in_mon2ref_mb, out_mon2scb_mb);
    axi_ref     = new(in_mon2ref_mb, ref2scb_mb);
    axi_scb     = new(ref2scb_mb, out_mon2scb_mb);
  endfunction
endclass

