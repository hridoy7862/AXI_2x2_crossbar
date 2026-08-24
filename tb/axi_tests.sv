
class axi_m0_write_s0_test extends axi_base_test;
  function new(virtual axi_if axi_intf); 
    super.new(axi_intf); 
  endfunction
  task run();
    $display("===== TEST 02: M0 WRITE TO S0 =====");
    start_background_threads(); 
    clear_backpressure();
    m0_write_s0(4'h1, 32'h0000_0010, 32'hA5A5_1234);
    finish_test();
  endtask
endclass

class axi_m1_write_s0_test extends axi_base_test;
  function new(virtual axi_if axi_intf); 
    super.new(axi_intf); 
  endfunction
  task run();
    $display("===== TEST 03: M1 WRITE TO S0 =====");
    start_background_threads(); 
    clear_backpressure();
    m1_write_s0(4'h2, 32'h0000_0020, 32'hBEEF_1111);
    finish_test();
  endtask
endclass

class axi_m1_write_s1_test extends axi_base_test;
  function new(virtual axi_if axi_intf); 
    super.new(axi_intf); 
  endfunction
  task run();
    $display("===== TEST 04: M1 WRITE TO S1 =====");
    start_background_threads(); 
    clear_backpressure();
    m1_write_s1(4'h3, 32'h1000_0010, 32'hCAFE_2222);
    finish_test();
  endtask
endclass

class axi_m0_write_s1_test extends axi_base_test;
  function new(virtual axi_if axi_intf); 
    super.new(axi_intf); 
  endfunction
  task run();
    $display("===== TEST 05: M0 WRITE TO S1 =====");
    start_background_threads(); 
    clear_backpressure();
    m0_write_s1(4'h4, 32'h1000_0020, 32'hFACE_3333);
    finish_test();
  endtask
endclass

class axi_parallel_write_test extends axi_base_test;
  function new(virtual axi_if axi_intf); 
    super.new(axi_intf); 
  endfunction
  task run();
    $display("===== TEST 06: PARALLEL WRITE M0->S0 AND M1->S1 =====");
    start_background_threads(); 
    clear_backpressure();
    fork
      m0_write_s0(4'h5, 32'h0000_0030, 32'h1111_AAAA);
      m1_write_s1(4'h6, 32'h1000_0030, 32'h2222_BBBB);
    join
    finish_test();
  endtask
endclass

class axi_same_slave_arbitration_test extends axi_base_test;
  function new(virtual axi_if axi_intf); 
    super.new(axi_intf); 
  endfunction
  task run();
    $display("===== TEST 07: SAME SLAVE ARBITRATION M0->S0 AND M1->S0 =====");
    start_background_threads(); 
    clear_backpressure();
    fork
      m0_write_s0(4'h7, 32'h0000_0040, 32'hAAAA_0001);
      m1_write_s0(4'h8, 32'h0000_0050, 32'hBBBB_0002);
    join
    finish_test(120);
  endtask
endclass

class axi_m0_read_s0_test extends axi_base_test;
  function new(virtual axi_if axi_intf); 
    super.new(axi_intf); 
  endfunction
  task run();
    $display("===== TEST 08: M0 READ FROM S0 =====");
    start_background_threads(); 
    clear_backpressure();
    m0_write_s0(4'h9, 32'h0000_0060, 32'h1234_5678);
    repeat(20) @(posedge axi_intf.clk);
    m0_read_s0(4'hA, 32'h0000_0060);
    finish_test(120);
  endtask
endclass

class axi_m1_read_s1_test extends axi_base_test;
  function new(virtual axi_if axi_intf); super.new(axi_intf); endfunction
  task run();
    $display("===== TEST 09: M1 READ FROM S1 =====");
    start_background_threads(); clear_backpressure();
    m1_write_s1(4'hB, 32'h1000_0060, 32'h8765_4321);
    repeat(20) @(posedge axi_intf.clk);
    m1_read_s1(4'hC, 32'h1000_0060);
    finish_test(120);
  endtask
endclass

class axi_write_decerr_test extends axi_base_test;
  function new(virtual axi_if axi_intf); 
    super.new(axi_intf); 
  endfunction
  task run();
    $display("===== TEST 10: INVALID ADDRESS WRITE DECERR =====");
    start_background_threads(); 
    clear_backpressure();
    m0_write_invalid(4'hD, 32'h3000_0000, 32'hDEAD_BEEF);
    finish_test(120);
  endtask
endclass

class axi_read_decerr_test extends axi_base_test;
  function new(virtual axi_if axi_intf); super.new(axi_intf); endfunction
  task run();
    $display("===== TEST 11: INVALID ADDRESS READ DECERR =====");
    start_background_threads(); 
    clear_backpressure();
    m1_read_invalid(4'hE, 32'h3000_0010);
    finish_test(120);
  endtask
endclass

class axi_write_burst_test extends axi_base_test;
  function new(virtual axi_if axi_intf); super.new(axi_intf); endfunction
  task run();
    $display("===== TEST 12: WRITE BURST TEST =====");
    start_background_threads(); clear_backpressure();
    m0_write_s0(4'h1, 32'h0000_0100, 32'h1000_0000, 4);
    finish_test(150);
  endtask
endclass

class axi_read_burst_test extends axi_base_test;
  function new(virtual axi_if axi_intf); super.new(axi_intf); endfunction
  task run();
    $display("===== TEST 13: READ BURST TEST =====");
    start_background_threads(); clear_backpressure();
    m1_write_s1(4'h2, 32'h1000_0100, 32'h2000_0000, 4);
    repeat(30) @(posedge axi_intf.clk);
    m1_read_s1(4'h3, 32'h1000_0100, 4);
    finish_test(180);
  endtask
endclass

class axi_write_backpressure_test extends axi_base_test;
  function new(virtual axi_if axi_intf); super.new(axi_intf); endfunction
  task run();
    $display("===== TEST 14: WRITE BACKPRESSURE TEST =====");
    start_background_threads(); clear_backpressure();
    axi_intf.s0_aw_stall_cycles = 5;
    axi_intf.s0_w_stall_cycles  = 7;
    m0_write_s0(4'h4, 32'h0000_0200, 32'hABCD_0001);
    finish_test(180);
  endtask
endclass

class axi_response_backpressure_test extends axi_base_test;
  function new(virtual axi_if axi_intf); super.new(axi_intf); endfunction
  task run();
    $display("===== TEST 15: RESPONSE BACKPRESSURE TEST =====");
    start_background_threads(); clear_backpressure();
    axi_intf.m0_b_stall_cycles = 8;
    axi_intf.m1_r_stall_cycles = 8;
    m0_write_s0(4'h5, 32'h0000_0300, 32'hABCD_0002);
    m1_write_s1(4'h6, 32'h1000_0300, 32'hABCD_0003);
    repeat(20) @(posedge axi_intf.clk);
    m1_read_s1(4'h7, 32'h1000_0300);
    finish_test(200);
  endtask
endclass

class axi_random_constrained_test extends axi_base_test;
  function new(virtual axi_if axi_intf); super.new(axi_intf); endfunction
  task run();
    int i;
    $display("===== CONSTRAINED RANDOM MIXED TEST =====");
    start_background_threads(); clear_backpressure();
    for (i = 0; i < 100; i++) begin
      if ($urandom_range(0,1)) begin
        if ($urandom_range(0,1)) axi_env.axi_m0_agnt.axi_gen.generate_random_write_seq(1, 1);
        else                    axi_env.axi_m1_agnt.axi_gen.generate_random_write_seq(1, 1);
      end else begin
        if ($urandom_range(0,1)) axi_env.axi_m0_agnt.axi_gen.generate_random_read_seq(1, 1);
        else                    axi_env.axi_m1_agnt.axi_gen.generate_random_read_seq(1, 1);
      end
      repeat(5) @(posedge axi_intf.clk);
    end
    finish_test(300);
  endtask
endclass

