class axi_generator;
  axi_transaction axi_item;

  mailbox aw_gen2drv_mb;
  mailbox w_gen2drv_mb;
  mailbox ar_gen2drv_mb;
  semaphore sem;

  function new(mailbox aw_gen2drv_mb,
               mailbox w_gen2drv_mb,
               mailbox ar_gen2drv_mb,
               semaphore sem);
    $display("@[%0t] :: INSIDE AXI GENERATOR CONSTRUCTOR", $time);
    this.aw_gen2drv_mb = aw_gen2drv_mb;
    this.w_gen2drv_mb  = w_gen2drv_mb;
    this.ar_gen2drv_mb = ar_gen2drv_mb;
    this.sem           = sem;
  endfunction

  task generate_write_seq(axi_transaction::master_e master,
                          axi_transaction::slave_e  slave,
                          logic [3:0] id,
                          logic [31:0] addr,
                          logic [31:0] data,
                          int unsigned beats = 1);
    axi_item = new();
    axi_item.trans_kind = axi_transaction::WRITE_REQ;
    axi_item.master = master;
    axi_item.slave  = slave;
    axi_item.id     = id;
    axi_item.addr   = addr;
    axi_item.len    = beats - 1;
    axi_item.size   = 3'd2;
    axi_item.burst  = 2'b01;
    axi_item.data   = data;
    axi_item.strb   = 4'hF;
    axi_item.build_default_write_data();
    axi_item.display("GEN_WRITE");
    aw_gen2drv_mb.put(axi_item.copy());

    $display("@[%0t] :: **AW DATA SENT FROM GENERATOR TO DRIVER**",$time);

    w_gen2drv_mb.put(axi_item.copy());
    
    $display("@[%0t] :: **W DATA SENT FROM GENERATOR TO DRIVER**",$time);

    sem.get(2); // wait until AW and W drivers complete their handshakes
  endtask

  task generate_read_seq(axi_transaction::master_e master,
                         axi_transaction::slave_e  slave,
                         logic [3:0] id,
                         logic [31:0] addr,
                         int unsigned beats = 1);
    axi_item = new();
    axi_item.trans_kind = axi_transaction::READ_REQ;
    axi_item.master = master;
    axi_item.slave  = slave;
    axi_item.id     = id;
    axi_item.addr   = addr;
    axi_item.len    = beats - 1;
    axi_item.size   = 3'd2;
    axi_item.burst  = 2'b01;
    axi_item.display("GEN_READ");
    ar_gen2drv_mb.put(axi_item.copy());
    $display("@[%0t] :: **AR DATA SENT FROM GENERATOR TO DRIVER**",$time);
    sem.get(1); // wait until AR driver completes handshake
  endtask

  task generate_random_write_seq(bit allow_decerr = 0, bit allow_burst = 0);
    axi_transaction tr;
    tr = new();
    if (!tr.randomize() with {
          trans_kind == axi_transaction::WRITE_REQ;
          if (!allow_decerr) slave inside {axi_transaction::SLAVE0, axi_transaction::SLAVE1};
          if (!allow_burst) len == 0;
        }) $fatal("****RANDOM WRITE GENERATION FAILED****");
    tr.build_default_write_data();
    generate_write_seq(tr.master, tr.slave, tr.id, tr.addr, tr.data, tr.num_beats());
  endtask

  task generate_random_read_seq(bit allow_decerr = 0, bit allow_burst = 0);
    axi_transaction tr;
    tr = new();
    if (!tr.randomize() with {
          trans_kind == axi_transaction::READ_REQ;
          if (!allow_decerr) slave inside {axi_transaction::SLAVE0, axi_transaction::SLAVE1};
          if (!allow_burst) len == 0;
        }) $fatal("****RANDOM WRITE GENERATION FAILED****");
    generate_read_seq(tr.master, tr.slave, tr.id, tr.addr, tr.num_beats());
  endtask
endclass

