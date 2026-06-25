class axi_reset_test extends axi_base_test;

  function new(virtual axi_if axi_intf);
    super.new(axi_intf);
  endfunction

  task check_zero(string name, logic value, ref int err);
    if (value !== 1'b0) begin
      $display("@[%0t] RESET FAIL: %s = %0b, expected 0",
               $time, name, value);
      err++;
    end
    else begin
      $display("@[%0t] RESET OK  : %s = %0b", $time, name, value);
    end
  endtask

  task show_signal(string name, logic value);
    $display("@[%0t] RESET INFO: %s = %0b", $time, name, value);
  endtask

  task run();
    int err;
    err = 0;

    $display("===== TEST 01: RESET TEST =====");

    wait(axi_intf.rst_n == 1'b0);
    repeat(2) @(posedge axi_intf.clk);

    $display("----- Checking reset state -----");

    // Master-side response VALID signals
    check_zero("m0_bvalid", axi_intf.m0_bvalid, err);
    check_zero("m0_rvalid", axi_intf.m0_rvalid, err);
    check_zero("m1_bvalid", axi_intf.m1_bvalid, err);
    check_zero("m1_rvalid", axi_intf.m1_rvalid, err);

    // Slave-side request VALID signals from crossbar
    check_zero("s0_awvalid", axi_intf.s0_awvalid, err);
    check_zero("s0_wvalid",  axi_intf.s0_wvalid,  err);
    check_zero("s0_arvalid", axi_intf.s0_arvalid, err);

    check_zero("s1_awvalid", axi_intf.s1_awvalid, err);
    check_zero("s1_wvalid",  axi_intf.s1_wvalid,  err);
    check_zero("s1_arvalid", axi_intf.s1_arvalid, err);

    // Display READY signals only
    show_signal("m0_awready", axi_intf.m0_awready);
    show_signal("m0_wready",  axi_intf.m0_wready);
    show_signal("m0_arready", axi_intf.m0_arready);
    show_signal("m1_awready", axi_intf.m1_awready);
    show_signal("m1_wready",  axi_intf.m1_wready);
    show_signal("m1_arready", axi_intf.m1_arready);

    show_signal("s0_bready", axi_intf.s0_bready);
    show_signal("s0_rready", axi_intf.s0_rready);
    show_signal("s1_bready", axi_intf.s1_bready);
    show_signal("s1_rready", axi_intf.s1_rready);

    wait(axi_intf.rst_n == 1'b1);
    repeat(5) @(posedge axi_intf.clk);

    if (err == 0)
      $display("===== RESET TEST PASSED =====");
    else
      $display("===== RESET TEST FAILED: %0d errors =====", err);

    $finish;
  endtask

endclass
