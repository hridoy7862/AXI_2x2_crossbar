class axi_regression_test extends axi_base_test;

  function new(virtual axi_if axi_intf);
    super.new(axi_intf);
  endfunction

  task run();
    int i;
    axi_m0_write_s0_test t2;
    axi_random_constrained_test tr;
    

    for (i = 0; i < 100; i++) begin
      t2 = new(axi_intf);
      t2.run();
    end

    for (i = 0; i < 1000; i++) begin
      tr = new(axi_intf);
      tr.run();
    end





  endtask
endclass
