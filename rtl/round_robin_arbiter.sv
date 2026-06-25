module round_robin_arbiter (
  input  logic       clk,
  input  logic       rst_n,

  //req[0] = Master 0 wants this slave & req[1] = Master 1 wants this slave
  input  logic [1:0] req,
  output logic [1:0] grant,

  //ack: completes its AW handshake with the slave (AWVALID && AWREADY)
  input  logic       ack
  );

  //0 = Master 0 has priority next & 1 = Master 1 has priority next
  logic priority_m;

  always_comb begin
    grant = 2'b00;  

    if (priority_m) begin
      if (req[1]) 
        grant = 2'b10;                            // grant master 1
      else if (req[0]) 
        grant = 2'b01;                            // fallback to master 0

    end else begin
      if (req[0]) 
        grant = 2'b01;                            // grant master 0
      else if (req[1]) 
        grant = 2'b10;                            // fallback to master 1
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      priority_m <= 1'b0;                         //master 0 has priority at reset

    end else if (ack && (grant != 2'b00)) begin

      // Whoever won this round, other master gets priority next
      if (grant[0]) 
        priority_m <= 1'b1;                        // M0 won then M1 next

      else        
        priority_m <= 1'b0;                        // M1 won then M0 next
    
    end
  end
endmodule
