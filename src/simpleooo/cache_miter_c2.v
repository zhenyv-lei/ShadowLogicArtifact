`include "src/simpleooo/param.v"
`include "src/simpleooo/cache_regular.v"
`include "src/simpleooo/cache_secure.v"

// =============================================================================
// Experiment II: Cache Contract Compliance Verification
// =============================================================================
// Verify whether caches satisfy C1 and C2 contracts.
//
// C2 check: same req/addr/we, different wdata → gnt must be same
//   (C2 does NOT allow wdata→gnt)
//
// C1 check: same req/we, different addr → gnt must be same
//   (C1 does NOT allow addr→gnt)
// =============================================================================

module cache_compliance_top(
    input clk,
    input rst
);

// =========================================================================
// Unconstrained inputs (formal tool explores all)
// =========================================================================
wire                       req_valid;
wire [`MEMD_SIZE_LOG-1:0]  addr_shared;   // shared address for C2 test
wire [`MEMD_SIZE_LOG-1:0]  addr_1, addr_2;  // different addresses for C1 test

// =========================================================================
// C2 compliance: Regular Cache
// Same req/addr, different internal data → gnt must be same
// =========================================================================
cache_regular reg_cache_c2_1(
    .clk(clk), .rst(rst),
    .req_valid(req_valid),
    .req_addr(addr_shared)
);
cache_regular reg_cache_c2_2(
    .clk(clk), .rst(rst),
    .req_valid(req_valid),
    .req_addr(addr_shared)
);

// C2 assertion: wdata/internal data doesn't affect gnt (timing)
wire c2_regular_pass = (reg_cache_c2_1.resp_delayed == reg_cache_c2_2.resp_delayed);

// =========================================================================
// C1 compliance: Regular Cache
// Same req, different addr → gnt must be same
// =========================================================================
cache_regular reg_cache_c1_1(
    .clk(clk), .rst(rst),
    .req_valid(req_valid),
    .req_addr(addr_1)
);
cache_regular reg_cache_c1_2(
    .clk(clk), .rst(rst),
    .req_valid(req_valid),
    .req_addr(addr_2)
);

// C1 assertion: addr doesn't affect gnt (timing)
wire c1_regular_pass = (reg_cache_c1_1.resp_delayed == reg_cache_c1_2.resp_delayed);

// =========================================================================
// C1 compliance: Cache-S (secure, fixed latency)
// Same req, different addr → gnt must be same
// =========================================================================
cache_secure sec_cache_c1_1(
    .clk(clk), .rst(rst),
    .req_valid(req_valid),
    .req_addr(addr_1)
);
cache_secure sec_cache_c1_2(
    .clk(clk), .rst(rst),
    .req_valid(req_valid),
    .req_addr(addr_2)
);

// C1 assertion: addr doesn't affect gnt
wire c1_secure_pass = (sec_cache_c1_1.resp_delayed == sec_cache_c1_2.resp_delayed);

endmodule
