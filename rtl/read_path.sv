module read_path
    import axi_crossbar_pkg::*;
(
    input  logic clk,
    input  logic rst_n,

    // Master 0
    // AR
    input  logic [ID_WIDTH-1:0]   m0_arid,
    input  logic [ADDR_WIDTH-1:0] m0_araddr,
    input  logic [LEN_WIDTH-1:0]  m0_arlen,
    input  logic [SIZE_WIDTH-1:0] m0_arsize,
    input  logic [1:0]            m0_arburst,
    input  logic                  m0_arvalid,
    output logic                  m0_arready,
    // R
    output logic [ID_WIDTH-1:0]   m0_rid,
    output logic [DATA_WIDTH-1:0] m0_rdata,
    output logic [1:0]            m0_rresp,
    output logic                  m0_rlast,
    output logic                  m0_rvalid,
    input  logic                  m0_rready,

    // Master 1
    // AR
    input  logic [ID_WIDTH-1:0]   m1_arid,
    input  logic [ADDR_WIDTH-1:0] m1_araddr,
    input  logic [LEN_WIDTH-1:0]  m1_arlen,
    input  logic [SIZE_WIDTH-1:0] m1_arsize,
    input  logic [1:0]            m1_arburst,
    input  logic                  m1_arvalid,
    output logic                  m1_arready,
    
    // R
    output logic [ID_WIDTH-1:0]   m1_rid,
    output logic [DATA_WIDTH-1:0] m1_rdata,
    output logic [1:0]            m1_rresp,
    output logic                  m1_rlast,
    output logic                  m1_rvalid,
    input  logic                  m1_rready,

    // Slave 0
    // AR
    output logic [ID_WIDTH_S-1:0] s0_arid,
    output logic [ADDR_WIDTH-1:0] s0_araddr,
    output logic [LEN_WIDTH-1:0]  s0_arlen,
    output logic [SIZE_WIDTH-1:0] s0_arsize,
    output logic [1:0]            s0_arburst,
    output logic                  s0_arvalid,
    input  logic                  s0_arready,
    
    // R
    input  logic [ID_WIDTH_S-1:0] s0_rid,
    input  logic [DATA_WIDTH-1:0] s0_rdata,
    input  logic [1:0]            s0_rresp,
    input  logic                  s0_rlast,
    input  logic                  s0_rvalid,
    output logic                  s0_rready,

    //Slave 1
    // AR
    output logic [ID_WIDTH_S-1:0] s1_arid,
    output logic [ADDR_WIDTH-1:0] s1_araddr,
    output logic [LEN_WIDTH-1:0]  s1_arlen,
    output logic [SIZE_WIDTH-1:0] s1_arsize,
    output logic [1:0]            s1_arburst,
    output logic                  s1_arvalid,
    input  logic                  s1_arready,
    // R
    input  logic [ID_WIDTH_S-1:0] s1_rid,
    input  logic [DATA_WIDTH-1:0] s1_rdata,
    input  logic [1:0]            s1_rresp,
    input  logic                  s1_rlast,
    input  logic                  s1_rvalid,
    output logic                  s1_rready
);

    // Internal wires

   /* // ar_channel to outstanding_tracker (write on AR handshake)
    logic [ID_WIDTH_S-1:0] ostnd_wr_rid;
    logic                  ostnd_wr_master;
    logic                  ostnd_wr_valid;
    logic                  ostnd_wr_ready;

    // r_channel to  outstanding_tracker (lookup + clear)
    logic [ID_WIDTH_S-1:0] ostnd_lookup_rid;
    logic                  ostnd_lookup_master;
    logic                  ostnd_lookup_hit;
    logic [ID_WIDTH_S-1:0] ostnd_clear_rid;
    logic                  ostnd_clear_valid;
    */
    // ar_channel to dummy slave AR
    logic [ID_WIDTH_S-1:0] dm_arid;
    logic [ADDR_WIDTH-1:0] dm_araddr;
    logic [LEN_WIDTH-1:0]  dm_arlen;
    logic [SIZE_WIDTH-1:0] dm_arsize;
    logic [1:0]            dm_arburst;
    logic                  dm_arvalid;
    logic                  dm_arready;

    // dummy slave to r_channel R
    logic [ID_WIDTH_S-1:0] dm_rid;
    logic [DATA_WIDTH-1:0] dm_rdata;
    logic [1:0]            dm_rresp;
    logic                  dm_rlast;
    logic                  dm_rvalid;
    logic                  dm_rready;

    // AR channel
    ar_channel u_ar_channel (
        .clk             (clk),
        .rst_n           (rst_n),
        // M0
        .m0_arid         (m0_arid),
        .m0_araddr       (m0_araddr),
        .m0_arlen        (m0_arlen),
        .m0_arsize       (m0_arsize),
        .m0_arburst      (m0_arburst),
        .m0_arvalid      (m0_arvalid),
        .m0_arready      (m0_arready),
        // M1
        .m1_arid         (m1_arid),
        .m1_araddr       (m1_araddr),
        .m1_arlen        (m1_arlen),
        .m1_arsize       (m1_arsize),
        .m1_arburst      (m1_arburst),
        .m1_arvalid      (m1_arvalid),
        .m1_arready      (m1_arready),
        // S0
        .s0_arid         (s0_arid),
        .s0_araddr       (s0_araddr),
        .s0_arlen        (s0_arlen),
        .s0_arsize       (s0_arsize),
        .s0_arburst      (s0_arburst),
        .s0_arvalid      (s0_arvalid),
        .s0_arready      (s0_arready),
        // S1
        .s1_arid         (s1_arid),
        .s1_araddr       (s1_araddr),
        .s1_arlen        (s1_arlen),
        .s1_arsize       (s1_arsize),
        .s1_arburst      (s1_arburst),
        .s1_arvalid      (s1_arvalid),
        .s1_arready      (s1_arready),
        // Dummy
        .dm_arid         (dm_arid),
        .dm_araddr       (dm_araddr),
        .dm_arlen        (dm_arlen),
        .dm_arsize       (dm_arsize),
        .dm_arburst      (dm_arburst),
        .dm_arvalid      (dm_arvalid),
        .dm_arready      (dm_arready)
        // Outstanding tracker write
        //.ostnd_rid       (ostnd_wr_rid),
        //.ostnd_master    (ostnd_wr_master),
        //.ostnd_wr_valid  (ostnd_wr_valid),
        //.ostnd_wr_ready  (ostnd_wr_ready)
    );

    // Outstanding transaction tracker
   /* outstanding_tracker u_ostnd (
        .clk            (clk),
        .rst_n          (rst_n),
        // Write (from ar_channel)
        .wr_rid         (ostnd_wr_rid),
        .wr_valid       (ostnd_wr_valid),
        .wr_ready       (ostnd_wr_ready),
        // Lookup (from r_channel)
        .lookup_rid     (ostnd_lookup_rid),
        .lookup_master  (ostnd_lookup_master),
        .lookup_hit     (ostnd_lookup_hit),
        // Clear (from r_channel on RLAST)
        .clear_rid      (ostnd_clear_rid),
        .clear_valid    (ostnd_clear_valid)
    );*/

    // Dummy slave — DECERR R beat generator
    ar_dummy_slave u_dummy_slave (
        .clk        (clk),
        .rst_n      (rst_n),
        // AR from ar_channel
        .s_arid     (dm_arid),
        .s_arlen    (dm_arlen),
        .s_arvalid  (dm_arvalid),
        .s_arready  (dm_arready),
        // R to r_channel
        .s_rid      (dm_rid),
        .s_rdata    (dm_rdata),
        .s_rresp    (dm_rresp),
        .s_rlast    (dm_rlast),
        .s_rvalid   (dm_rvalid),
        .s_rready   (dm_rready)
    );

    // R channel — routes R data from slaves to correct master
    r_channel u_r_channel (
        .clk               (clk),
        .rst_n             (rst_n),
        // S0 R
        .s0_rid            (s0_rid),
        .s0_rdata          (s0_rdata),
        .s0_rresp          (s0_rresp),
        .s0_rlast          (s0_rlast),
        .s0_rvalid         (s0_rvalid),
        .s0_rready         (s0_rready),
        // S1 R
        .s1_rid            (s1_rid),
        .s1_rdata          (s1_rdata),
        .s1_rresp          (s1_rresp),
        .s1_rlast          (s1_rlast),
        .s1_rvalid         (s1_rvalid),
        .s1_rready         (s1_rready),
        // Dummy R
        .dm_rid            (dm_rid),
        .dm_rdata          (dm_rdata),
        .dm_rresp          (dm_rresp),
        .dm_rlast          (dm_rlast),
        .dm_rvalid         (dm_rvalid),
        .dm_rready         (dm_rready),
        /*// Outstanding tracker
        .ostnd_lookup_rid  (ostnd_lookup_rid),
        .ostnd_lookup_master(ostnd_lookup_master),
        .ostnd_lookup_hit  (ostnd_lookup_hit),
        .ostnd_clear_rid   (ostnd_clear_rid),
        .ostnd_clear_valid (ostnd_clear_valid),*/
        // M0 R
        .m0_rid            (m0_rid),
        .m0_rdata          (m0_rdata),
        .m0_rresp          (m0_rresp),
        .m0_rlast          (m0_rlast),
        .m0_rvalid         (m0_rvalid),
        .m0_rready         (m0_rready),
        // M1 R
        .m1_rid            (m1_rid),
        .m1_rdata          (m1_rdata),
        .m1_rresp          (m1_rresp),
        .m1_rlast          (m1_rlast),
        .m1_rvalid         (m1_rvalid),
        .m1_rready         (m1_rready)
    );

endmodule
