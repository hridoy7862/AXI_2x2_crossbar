module tb_top;
  import axi_crossbar_pkg::*;
  import axi_test_lib_pkg::*;

  logic clk;
  logic rst_n;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    repeat(5) @(posedge clk);
    rst_n = 1'b1;
  end


  axi_if vif(clk, rst_n);

  initial begin
    vif.m0_awvalid = 0; vif.m0_wvalid = 0; vif.m0_bready = 0; vif.m0_arvalid = 0; vif.m0_rready = 0;
    vif.m1_awvalid = 0; vif.m1_wvalid = 0; vif.m1_bready = 0; vif.m1_arvalid = 0; vif.m1_rready = 0;
    vif.s0_aw_stall_cycles = 0; vif.s0_w_stall_cycles = 0; vif.s0_ar_stall_cycles = 0; vif.s0_r_delay_cycles = 0;
    vif.s1_aw_stall_cycles = 0; vif.s1_w_stall_cycles = 0; vif.s1_ar_stall_cycles = 0; vif.s1_r_delay_cycles = 0;
    vif.m0_b_stall_cycles  = 0; vif.m1_b_stall_cycles  = 0; vif.m0_r_stall_cycles  = 0; vif.m1_r_stall_cycles  = 0;
  end
  

  write_path u_write_path (
    .clk(clk), .rst_n(rst_n),
    .m0_awid(vif.m0_awid), 
    .m0_awaddr(vif.m0_awaddr), 
    .m0_awlen(vif.m0_awlen), 
    .m0_awsize(vif.m0_awsize), 
    .m0_awburst(vif.m0_awburst), 
    .m0_awvalid(vif.m0_awvalid), 
    .m0_awready(vif.m0_awready),
    .m0_wdata(vif.m0_wdata), 
    .m0_wstrb(vif.m0_wstrb), 
    .m0_wlast(vif.m0_wlast), 
    .m0_wvalid(vif.m0_wvalid), 
    .m0_wready(vif.m0_wready),
    .m0_bid(vif.m0_bid), 
    .m0_bresp(vif.m0_bresp), 
    .m0_bvalid(vif.m0_bvalid), 
    .m0_bready(vif.m0_bready),


    .m1_awid(vif.m1_awid), 
    .m1_awaddr(vif.m1_awaddr), 
    .m1_awlen(vif.m1_awlen), 
    .m1_awsize(vif.m1_awsize), 
    .m1_awburst(vif.m1_awburst), 
    .m1_awvalid(vif.m1_awvalid), 
    .m1_awready(vif.m1_awready),
    .m1_wdata(vif.m1_wdata), 
    .m1_wstrb(vif.m1_wstrb), 
    .m1_wlast(vif.m1_wlast), 
    .m1_wvalid(vif.m1_wvalid), 
    .m1_wready(vif.m1_wready),
    .m1_bid(vif.m1_bid), 
    .m1_bresp(vif.m1_bresp), 
    .m1_bvalid(vif.m1_bvalid), 
    .m1_bready(vif.m1_bready),


    .s0_awid(vif.s0_awid), 
    .s0_awaddr(vif.s0_awaddr), 
    .s0_awlen(vif.s0_awlen), 
    .s0_awsize(vif.s0_awsize), 
    .s0_awburst(vif.s0_awburst), 
    .s0_awvalid(vif.s0_awvalid), 
    .s0_awready(vif.s0_awready),
    .s0_wdata(vif.s0_wdata), 
    .s0_wstrb(vif.s0_wstrb), 
    .s0_wlast(vif.s0_wlast), 
    .s0_wvalid(vif.s0_wvalid), 
    .s0_wready(vif.s0_wready),
    .s0_bid(vif.s0_bid), 
    .s0_bresp(vif.s0_bresp), 
    .s0_bvalid(vif.s0_bvalid), 
    .s0_bready(vif.s0_bready),


    .s1_awid(vif.s1_awid), 
    .s1_awaddr(vif.s1_awaddr), 
    .s1_awlen(vif.s1_awlen), 
    .s1_awsize(vif.s1_awsize), 
    .s1_awburst(vif.s1_awburst), 
    .s1_awvalid(vif.s1_awvalid), 
    .s1_awready(vif.s1_awready),
    .s1_wdata(vif.s1_wdata), 
    .s1_wstrb(vif.s1_wstrb), 
    .s1_wlast(vif.s1_wlast), 
    .s1_wvalid(vif.s1_wvalid), 
    .s1_wready(vif.s1_wready),
    .s1_bid(vif.s1_bid), 
    .s1_bresp(vif.s1_bresp), 
    .s1_bvalid(vif.s1_bvalid), 
    .s1_bready(vif.s1_bready)
  );

  read_path u_read_path (
    .clk(clk), .rst_n(rst_n),
    .m0_arid(vif.m0_arid), 
    .m0_araddr(vif.m0_araddr), 
    .m0_arlen(vif.m0_arlen), 
    .m0_arsize(vif.m0_arsize), 
    .m0_arburst(vif.m0_arburst), 
    .m0_arvalid(vif.m0_arvalid), 
    .m0_arready(vif.m0_arready),
    .m0_rid(vif.m0_rid), 
    .m0_rdata(vif.m0_rdata), 
    .m0_rresp(vif.m0_rresp), 
    .m0_rlast(vif.m0_rlast), 
    .m0_rvalid(vif.m0_rvalid), 
    .m0_rready(vif.m0_rready),


    .m1_arid(vif.m1_arid), 
    .m1_araddr(vif.m1_araddr), 
    .m1_arlen(vif.m1_arlen), 
    .m1_arsize(vif.m1_arsize), 
    .m1_arburst(vif.m1_arburst), 
    .m1_arvalid(vif.m1_arvalid), 
    .m1_arready(vif.m1_arready),
    .m1_rid(vif.m1_rid), 
    .m1_rdata(vif.m1_rdata), 
    .m1_rresp(vif.m1_rresp), 
    .m1_rlast(vif.m1_rlast), 
    .m1_rvalid(vif.m1_rvalid), 
    .m1_rready(vif.m1_rready),


    .s0_arid(vif.s0_arid), 
    .s0_araddr(vif.s0_araddr), 
    .s0_arlen(vif.s0_arlen), 
    .s0_arsize(vif.s0_arsize), 
    .s0_arburst(vif.s0_arburst), 
    .s0_arvalid(vif.s0_arvalid), 
    .s0_arready(vif.s0_arready),
    .s0_rid(vif.s0_rid), 
    .s0_rdata(vif.s0_rdata), 
    .s0_rresp(vif.s0_rresp), 
    .s0_rlast(vif.s0_rlast), 
    .s0_rvalid(vif.s0_rvalid), 
    .s0_rready(vif.s0_rready),


    .s1_arid(vif.s1_arid), 
    .s1_araddr(vif.s1_araddr), 
    .s1_arlen(vif.s1_arlen), 
    .s1_arsize(vif.s1_arsize), 
    .s1_arburst(vif.s1_arburst), 
    .s1_arvalid(vif.s1_arvalid), 
    .s1_arready(vif.s1_arready),
    .s1_rid(vif.s1_rid), 
    .s1_rdata(vif.s1_rdata), 
    .s1_rresp(vif.s1_rresp), 
    .s1_rlast(vif.s1_rlast), 
    .s1_rvalid(vif.s1_rvalid), 
    .s1_rready(vif.s1_rready)
  );

  axi_slave_model #(.SLAVE_ID(0)) s0_model (
    .clk(clk), .rst_n(rst_n),
    .s_awid(vif.s0_awid), 
    .s_awaddr(vif.s0_awaddr), 
    .s_awlen(vif.s0_awlen), 
    .s_awsize(vif.s0_awsize), 
    .s_awburst(vif.s0_awburst), 
    .s_awvalid(vif.s0_awvalid), 
    .s_awready(vif.s0_awready),


    .s_wdata(vif.s0_wdata), 
    .s_wstrb(vif.s0_wstrb), 
    .s_wlast(vif.s0_wlast), 
    .s_wvalid(vif.s0_wvalid), 
    .s_wready(vif.s0_wready),
    .s_bid(vif.s0_bid),


    .s_bresp(vif.s0_bresp), 
    .s_bvalid(vif.s0_bvalid), 
    .s_bready(vif.s0_bready),
    .s_arid(vif.s0_arid), 
    .s_araddr(vif.s0_araddr), 
    .s_arlen(vif.s0_arlen), 
    .s_arsize(vif.s0_arsize), 
    .s_arburst(vif.s0_arburst), 
    .s_arvalid(vif.s0_arvalid), 
    .s_arready(vif.s0_arready),


    .s_rid(vif.s0_rid), 
    .s_rdata(vif.s0_rdata), 
    .s_rresp(vif.s0_rresp), 
    .s_rlast(vif.s0_rlast), 
    .s_rvalid(vif.s0_rvalid), 
    .s_rready(vif.s0_rready),


    .aw_stall_cycles(vif.s0_aw_stall_cycles), 
    .w_stall_cycles(vif.s0_w_stall_cycles), 
    .ar_stall_cycles(vif.s0_ar_stall_cycles), 
    .r_delay_cycles(vif.s0_r_delay_cycles)
  );

  axi_slave_model #(.SLAVE_ID(1)) s1_model (
    .clk(clk), .rst_n(rst_n),
    .s_awid(vif.s1_awid), 
    .s_awaddr(vif.s1_awaddr), 
    .s_awlen(vif.s1_awlen), 
    .s_awsize(vif.s1_awsize), 
    .s_awburst(vif.s1_awburst), 
    .s_awvalid(vif.s1_awvalid), 
    .s_awready(vif.s1_awready),
    
    
    .s_wdata(vif.s1_wdata), 
    .s_wstrb(vif.s1_wstrb), 
    .s_wlast(vif.s1_wlast), 
    .s_wvalid(vif.s1_wvalid), 
    .s_wready(vif.s1_wready),
    
    
    .s_bid(vif.s1_bid), 
    .s_bresp(vif.s1_bresp), 
    .s_bvalid(vif.s1_bvalid), 
    .s_bready(vif.s1_bready),
    
    
    .s_arid(vif.s1_arid), 
    .s_araddr(vif.s1_araddr), 
    .s_arlen(vif.s1_arlen), 
    .s_arsize(vif.s1_arsize), 
    .s_arburst(vif.s1_arburst), 
    .s_arvalid(vif.s1_arvalid), 
    .s_arready(vif.s1_arready),
    
    
    .s_rid(vif.s1_rid), 
    .s_rdata(vif.s1_rdata), 
    .s_rresp(vif.s1_rresp), 
    .s_rlast(vif.s1_rlast), 
    .s_rvalid(vif.s1_rvalid), 
    .s_rready(vif.s1_rready),
    
    
    .aw_stall_cycles(vif.s1_aw_stall_cycles), 
    .w_stall_cycles(vif.s1_w_stall_cycles), 
    .ar_stall_cycles(vif.s1_ar_stall_cycles), 
    .r_delay_cycles(vif.s1_r_delay_cycles)
  );

  task run_test();
    axi_reset_test reset_t;
    axi_m0_write_s0_test t02;
    axi_m1_write_s0_test t03;
    axi_m1_write_s1_test t04;
    axi_m0_write_s1_test t05;
    axi_parallel_write_test t06;
    axi_same_slave_arbitration_test t07;
    axi_m0_read_s0_test t08;
    axi_m1_read_s1_test t09;
    axi_write_decerr_test t10;
    axi_read_decerr_test t11;
    axi_write_burst_test t12;
    axi_read_burst_test t13;
    axi_write_backpressure_test t14;
    axi_response_backpressure_test t15;
    axi_random_constrained_test trand;

    axi_regression_test treg;
    // Reset test must start while rst_n is still 0.
    // Other tests should start only after reset is released.
    if ($test$plusargs("reset")) begin 
      reset_t = new(vif); 
      reset_t.run(); 
    end
    else begin
      wait(rst_n == 1'b1);
      repeat(5) @(posedge clk);
      if ($test$plusargs("m0_write_s0")) begin 
      t02 = new(vif); 
      t02.run(); 
    end
    else if ($test$plusargs("m1_write_s0")) begin 
      t03 = new(vif); 
      t03.run(); 
    end
    else if ($test$plusargs("m1_write_s1")) begin 
      t04 = new(vif); 
      t04.run(); 
    end
    else if ($test$plusargs("m0_write_s1")) begin 
      t05 = new(vif); 
      t05.run(); 
    end
    else if ($test$plusargs("parallel_write")) begin 
      t06 = new(vif); 
      t06.run(); 
    end
    else if ($test$plusargs("arbitration")) begin 
      t07 = new(vif); 
      t07.run(); 
    end
    else if ($test$plusargs("m0_read_s0")) begin 
      t08 = new(vif); 
      t08.run(); 
    end
    else if ($test$plusargs("m1_read_s1")) begin 
      t09 = new(vif); 
      t09.run(); end
    else if ($test$plusargs("write_decerr")) begin 
      t10 = new(vif); 
      t10.run(); 
    end
    else if ($test$plusargs("read_decerr")) begin 
      t11 = new(vif); 
      t11.run(); 
    end
    else if ($test$plusargs("write_burst")) begin 
      t12 = new(vif); 
      t12.run(); end
    else if ($test$plusargs("read_burst")) begin 
      t13 = new(vif); 
      t13.run(); 
    end
    else if ($test$plusargs("write_backpressure")) begin 
      t14 = new(vif); 
      t14.run(); 
    end
    else if ($test$plusargs("response_backpressure")) begin 
      t15 = new(vif); 
      t15.run(); 
    end
    else if ($test$plusargs("random")) begin 
      trand = new(vif); 
      trand.run();
    end  
    else if ($test$plusargs("regression")) begin 
      treg = new(vif); 
      treg.run(); 
 
    end
    else begin
      $display("No plusarg selected. Running default smoke: m0_write_s0");
      t02 = new(vif); 
      t02.run();
    end
  end
  endtask

  initial begin
    $dumpfile("axi_crossbar.vcd");
    $dumpvars(0, tb_top);
    run_test();
    $finish;
  end

  /*initial begin
    #2000000;
    $fatal(1, "TB TIMEOUT");
  end
  */
endmodule

