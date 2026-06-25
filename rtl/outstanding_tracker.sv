module outstanding_tracker
  import axi_crossbar_pkg::*;

(
  input logic clk,
  input logic rst_n,

 
  // Write port (from ar_channel on AR handshake)
  input  logic [ID_WIDTH_S-1:0] wr_rid,      // tagged 5-bit RID
  input  logic                  wr_valid,     // write this entry
  output logic                  wr_ready,     // tracker not full
 
  //Lookup port (from r_channel for each incoming R beat) 
  input  logic [ID_WIDTH_S-1:0] lookup_rid,  // RID to look up
  output logic                  lookup_master,// 0=M0  1=M1
  output logic                  lookup_hit,  // entry found
 
  // Clear port (from r_channel on RLAST)
  input  logic [ID_WIDTH_S-1:0] clear_rid,   // RID whose burst ended
  input  logic                  clear_valid   // clear this entry now
  );


  //Storage 
  logic                  entry_valid [0:OSTND_DEPTH-1];
  logic [ID_WIDTH_S-1:0] entry_rid   [0:OSTND_DEPTH-1];
 
  //Full detection
  logic all_full;
  always_comb begin

    all_full = 1'b1;
    for (int i = 0; i < OSTND_DEPTH; i++)

      if (!entry_valid[i])
        all_full = 1'b0;
    
  end
  assign wr_ready = !all_full;
 
  //Find free slot for write
  logic [$clog2(OSTND_DEPTH)-1:0] free_slot;
  logic                            free_slot_found;
    
  always_comb begin
    free_slot       = '0;
    free_slot_found = 1'b0;
    for (int i = OSTND_DEPTH-1; i >= 0; i--) begin
      if (!entry_valid[i]) begin
        free_slot       = $clog2(OSTND_DEPTH)'(i);
        free_slot_found = 1'b1;
      end
    end
  end

  //Write and clear logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < OSTND_DEPTH; i++) begin
        entry_valid[i] <= 1'b0;
        entry_rid[i]   <= '0;
      end
    end else begin
      // Write new entry
      if (wr_valid && wr_ready && free_slot_found) begin
        entry_valid[free_slot] <= 1'b1;
        entry_rid  [free_slot] <= wr_rid;
      end

      // Clear entry when RLAST seen
      if (clear_valid) begin
        for (int i = 0; i < OSTND_DEPTH; i++) begin
          if (entry_valid[i] && entry_rid[i] == clear_rid) begin
            entry_valid[i] <= 1'b0;
          end
        end
      end
    end
  end

  // Combinational lookup
  // R channel calls this for every incoming R beat
  always_comb begin
    lookup_hit    = 1'b0;
    lookup_master = 1'b0;
    for (int i = 0; i < OSTND_DEPTH; i++) begin
      if (entry_valid[i] && entry_rid[i] == lookup_rid) begin
        lookup_hit    = 1'b1;
        lookup_master = entry_rid[i][4]; // bit[4] = master select
      end
    end
  end
 
endmodule
 







 






