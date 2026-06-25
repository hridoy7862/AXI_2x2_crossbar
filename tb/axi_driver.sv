class axi_driver #(int MASTER_ID = 0);
  virtual axi_if axi_intf;
  mailbox aw_gen2drv_mb;
  mailbox w_gen2drv_mb;
  mailbox ar_gen2drv_mb;
  semaphore sem;

  function new(virtual axi_if axi_intf,
               mailbox aw_gen2drv_mb,
               mailbox w_gen2drv_mb,
               mailbox ar_gen2drv_mb,
               semaphore sem);
    $display("@[%0t] :: INSIDE AXI DRIVER CONSTRUCTOR M%0d", $time, MASTER_ID);
    this.axi_intf      = axi_intf;
    this.aw_gen2drv_mb = aw_gen2drv_mb;
    this.w_gen2drv_mb  = w_gen2drv_mb;
    this.ar_gen2drv_mb = ar_gen2drv_mb;
    this.sem           = sem;
    fork
      aw_drive();
      w_drive();
      ar_drive();
    join_none
  endfunction

  task aw_drive();
    axi_transaction tr;
    forever begin
      aw_gen2drv_mb.get(tr);
      $display("@[%0t] :: AW RECIEVE DATA FROM MAILBOX",$time);
      @(posedge axi_intf.clk);
      if (MASTER_ID == 0) begin
        axi_intf.m0_awid    <= tr.id;
        axi_intf.m0_awaddr  <= tr.addr;
        axi_intf.m0_awlen   <= tr.len;
        axi_intf.m0_awsize  <= tr.size;
        axi_intf.m0_awburst <= tr.burst;
        axi_intf.m0_awvalid <= 1'b1;
        do @(posedge axi_intf.clk); while (!(axi_intf.m0_awvalid && axi_intf.m0_awready));
        axi_intf.m0_awvalid <= 1'b0;
      end
      else begin
        axi_intf.m1_awid    <= tr.id;
        axi_intf.m1_awaddr  <= tr.addr;
        axi_intf.m1_awlen   <= tr.len;
        axi_intf.m1_awsize  <= tr.size;
        axi_intf.m1_awburst <= tr.burst;
        axi_intf.m1_awvalid <= 1'b1;
        do @(posedge axi_intf.clk); while (!(axi_intf.m1_awvalid && axi_intf.m1_awready));
        axi_intf.m1_awvalid <= 1'b0;
      end
      $display("@[%0t] :: [M%0d DRIVER] AW HANDSHAKE DONE ID=%0h ADDR=%h LEN=%0d", $time, MASTER_ID, tr.id, tr.addr, tr.len);
      sem.put(1);
    end
  endtask

  task w_drive();
    axi_transaction tr;
    int i;
    forever begin
      w_gen2drv_mb.get(tr);
      $display("@[%0t] :: W RECIEVE DATA FROM MAILBOX",$time);
      for (i = 0; i < tr.num_beats(); i++) begin
        @(posedge axi_intf.clk);
        if (MASTER_ID == 0) begin
          axi_intf.m0_wdata  <= tr.wdata_q[i];
          axi_intf.m0_wstrb  <= tr.wstrb_q[i];
          axi_intf.m0_wlast  <= (i == tr.num_beats()-1);
          axi_intf.m0_wvalid <= 1'b1;
          do @(posedge axi_intf.clk); while (!(axi_intf.m0_wvalid && axi_intf.m0_wready));
          axi_intf.m0_wvalid <= 1'b0;
          axi_intf.m0_wlast  <= 1'b0;
        end
        else begin
          axi_intf.m1_wdata  <= tr.wdata_q[i];
          axi_intf.m1_wstrb  <= tr.wstrb_q[i];
          axi_intf.m1_wlast  <= (i == tr.num_beats()-1);
          axi_intf.m1_wvalid <= 1'b1;
          do @(posedge axi_intf.clk); while (!(axi_intf.m1_wvalid && axi_intf.m1_wready));
          axi_intf.m1_wvalid <= 1'b0;
          axi_intf.m1_wlast  <= 1'b0;
        end
        $display("@[%0t] :: [M%0d DRIVER] W HANDSHAKE DONE BEAT=%0d DATA=%h", $time, MASTER_ID, i, tr.wdata_q[i]);
      end
      sem.put(1);
    end
  endtask

  task ar_drive();
    axi_transaction tr;
    forever begin
      ar_gen2drv_mb.get(tr);
      $display("@[%0t] :: AR RECIEVE DATA FROM MAILBOX",$time);
      @(posedge axi_intf.clk);
      if (MASTER_ID == 0) begin
        axi_intf.m0_arid    <= tr.id;
        axi_intf.m0_araddr  <= tr.addr;
        axi_intf.m0_arlen   <= tr.len;
        axi_intf.m0_arsize  <= tr.size;
        axi_intf.m0_arburst <= tr.burst;
        axi_intf.m0_arvalid <= 1'b1;
        do @(posedge axi_intf.clk); while (!(axi_intf.m0_arvalid && axi_intf.m0_arready));
        axi_intf.m0_arvalid <= 1'b0;
      end
      else begin
        axi_intf.m1_arid    <= tr.id;
        axi_intf.m1_araddr  <= tr.addr;
        axi_intf.m1_arlen   <= tr.len;
        axi_intf.m1_arsize  <= tr.size;
        axi_intf.m1_arburst <= tr.burst;
        axi_intf.m1_arvalid <= 1'b1;
        do @(posedge axi_intf.clk); while (!(axi_intf.m1_arvalid && axi_intf.m1_arready));
        axi_intf.m1_arvalid <= 1'b0;
      end
      $display("@[%0t] :: [M%0d DRIVER] AR HANDSHAKE DONE ID=%0h ADDR=%h LEN=%0d", $time, MASTER_ID, tr.id, tr.addr, tr.len);
      sem.put(1);
    end
  endtask
endclass

