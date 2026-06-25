class axi_base_test;
  axi_environment axi_env;
  virtual axi_if axi_intf;

  function new(virtual axi_if axi_intf);
    $display("@[%0t] :: INSIDE AXI BASE TEST CONSTRUCTOR", $time);
    this.axi_intf = axi_intf;
    axi_env = new(axi_intf);
  endfunction

  task start_background_threads();
    fork
      axi_env.axi_m0_agnt.axi_mntr.start_all();
      axi_env.axi_m1_agnt.axi_mntr.start_all();
      axi_env.axi_ref.run();
      axi_env.axi_scb.compare();
    join_none
  endtask

  task clear_backpressure();
    axi_intf.s0_aw_stall_cycles = 0; axi_intf.s0_w_stall_cycles = 0; axi_intf.s0_ar_stall_cycles = 0; axi_intf.s0_r_delay_cycles = 0;
    axi_intf.s1_aw_stall_cycles = 0; axi_intf.s1_w_stall_cycles = 0; axi_intf.s1_ar_stall_cycles = 0; axi_intf.s1_r_delay_cycles = 0;
    axi_intf.m0_b_stall_cycles  = 0; axi_intf.m1_b_stall_cycles  = 0; axi_intf.m0_r_stall_cycles  = 0; axi_intf.m1_r_stall_cycles  = 0;
  endtask

  task m0_write_s0(logic [3:0] id, logic [31:0] addr, logic [31:0] data, int unsigned beats = 1);
    axi_env.axi_m0_agnt.axi_gen.generate_write_seq(axi_transaction::MASTER0, axi_transaction::SLAVE0, id, addr, data, beats);
  endtask
  task m0_write_s1(logic [3:0] id, logic [31:0] addr, logic [31:0] data, int unsigned beats = 1);
    axi_env.axi_m0_agnt.axi_gen.generate_write_seq(axi_transaction::MASTER0, axi_transaction::SLAVE1, id, addr, data, beats);
  endtask
  task m1_write_s0(logic [3:0] id, logic [31:0] addr, logic [31:0] data, int unsigned beats = 1);
    axi_env.axi_m1_agnt.axi_gen.generate_write_seq(axi_transaction::MASTER1, axi_transaction::SLAVE0, id, addr, data, beats);
  endtask
  task m1_write_s1(logic [3:0] id, logic [31:0] addr, logic [31:0] data, int unsigned beats = 1);
    axi_env.axi_m1_agnt.axi_gen.generate_write_seq(axi_transaction::MASTER1, axi_transaction::SLAVE1, id, addr, data, beats);
  endtask
  task m0_write_invalid(logic [3:0] id, logic [31:0] addr, logic [31:0] data);
    axi_env.axi_m0_agnt.axi_gen.generate_write_seq(axi_transaction::MASTER0, axi_transaction::SLAVE_DECERR, id, addr, data, 1);
  endtask
  task m1_write_invalid(logic [3:0] id, logic [31:0] addr, logic [31:0] data);
    axi_env.axi_m1_agnt.axi_gen.generate_write_seq(axi_transaction::MASTER1, axi_transaction::SLAVE_DECERR, id, addr, data, 1);
  endtask

  task m0_read_s0(logic [3:0] id, logic [31:0] addr, int unsigned beats = 1);
    axi_env.axi_m0_agnt.axi_gen.generate_read_seq(axi_transaction::MASTER0, axi_transaction::SLAVE0, id, addr, beats);
  endtask
  task m0_read_s1(logic [3:0] id, logic [31:0] addr, int unsigned beats = 1);
    axi_env.axi_m0_agnt.axi_gen.generate_read_seq(axi_transaction::MASTER0, axi_transaction::SLAVE1, id, addr, beats);
  endtask
  task m1_read_s0(logic [3:0] id, logic [31:0] addr, int unsigned beats = 1);
    axi_env.axi_m1_agnt.axi_gen.generate_read_seq(axi_transaction::MASTER1, axi_transaction::SLAVE0, id, addr, beats);
  endtask
  task m1_read_s1(logic [3:0] id, logic [31:0] addr, int unsigned beats = 1);
    axi_env.axi_m1_agnt.axi_gen.generate_read_seq(axi_transaction::MASTER1, axi_transaction::SLAVE1, id, addr, beats);
  endtask
  task m0_read_invalid(logic [3:0] id, logic [31:0] addr);
    axi_env.axi_m0_agnt.axi_gen.generate_read_seq(axi_transaction::MASTER0, axi_transaction::SLAVE_DECERR, id, addr, 1);
  endtask
  task m1_read_invalid(logic [3:0] id, logic [31:0] addr);
    axi_env.axi_m1_agnt.axi_gen.generate_read_seq(axi_transaction::MASTER1, axi_transaction::SLAVE_DECERR, id, addr, 1);
  endtask

  task finish_test(int wait_cycles = 80);
    repeat(wait_cycles) @(posedge axi_intf.clk);
    axi_env.axi_scb.report();
  endtask
endclass

