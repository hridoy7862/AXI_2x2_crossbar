module axi_decoder
  import axi_crossbar_pkg::*;
  
  (
  input  logic [ADDR_WIDTH-1:0] addr,
  output target_slave_e         target_slave
  );

  always_comb begin
    target_slave = TARGET_DEC;

    if (addr >= S0_BASE && addr <= S0_HIGH) begin
      target_slave = TARGET_S0;
    end
    else if (addr >= S1_BASE && addr <= S1_HIGH) begin
      target_slave = TARGET_S1;
    end
  end

endmodule
