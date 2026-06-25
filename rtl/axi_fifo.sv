
module axi_fifo #(
  parameter int WIDTH = 32,
  parameter int DEPTH = 8
  )
  (
  input  logic              clk,
  input  logic              rst_n,

  // Write port
  input  logic [WIDTH-1:0]  wr_data,
  input  logic              wr_valid,   // any wants to write
  output logic              wr_ready,   // FIFO not full

  // Read port
  output logic [WIDTH-1:0]  rd_data,
  output logic              rd_valid,   // FIFO not empty
  input  logic              rd_ready    // caller wants to read
  );


  localparam int ADDR_W = $clog2(DEPTH);
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_W:0]  wr_ptr;
  logic [ADDR_W:0]  rd_ptr;

  // Empty
  assign rd_valid = (wr_ptr != rd_ptr);

  // Full
  assign wr_ready = !( (wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1:0]) && (wr_ptr[ADDR_W]     != rd_ptr[ADDR_W]) );

  //Read data
  assign rd_data = mem[rd_ptr[ADDR_W-1:0]];

  //Write pointer
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
    end else begin
      if (wr_valid && wr_ready) begin
        mem[wr_ptr[ADDR_W-1:0]] <= wr_data;
        wr_ptr                  <= wr_ptr + 1'b1;
      end
    end
  end

  //Read pointer
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= '0;
    end else begin
      if (rd_valid && rd_ready) begin
        rd_ptr <= rd_ptr + 1'b1;
      end
    end
  end

endmodule
