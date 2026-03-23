`include "src/simpleooo/param.v"

`include "src/simpleooo/decode.v"
`include "src/simpleooo/execute.v"
`include "src/simpleooo/param.v"
`include "src/simpleooo/rf.v"
`include "src/simpleooo/memi.v"

`include "src/simpleooo/cpu_ooo_ext_mem.v"
`include "src/simpleooo/cache_secure.v"

// =============================================================================
// Experiment C: SimpleOoO-SS (Delay_spectre) + Cache-S Combined Verification
// =============================================================================
// CPU with Delay defense + fixed-latency secure cache.
// Expected result: PASS (both sides are safe)
// =============================================================================

module top(
    input clk,
    input rst
);

reg init;
always @(posedge clk) begin
    if (rst) init <= 1;
    else     init <= 0;
end

// =========================================================================
// Cache-S instances (one per copy, with independent secret data)
// =========================================================================
cache_secure cache_1(
    .clk(clk), .rst(rst),
    .req_valid(copy1.dmem_req_valid),
    .req_addr(copy1.dmem_req_addr),
    .resp_data(),
    .resp_delayed()
);

cache_secure cache_2(
    .clk(clk), .rst(rst),
    .req_valid(copy2.dmem_req_valid),
    .req_addr(copy2.dmem_req_addr),
    .resp_data(),
    .resp_delayed()
);

// =========================================================================
// Core instantiation: SimpleOoO-SS (Delay_spectre) + Cache-S
// =========================================================================
reg [`ROB_SIZE_LOG-1:0] ROB_tail_1, ROB_tail_2;
reg stall_1, stall_2, finish_1, finish_2, commit_deviation, addr_deviation, invalid_program;
reg C_mem_valid_r, C_mem_rdwt_r, C_is_br_r, C_taken_r;
reg [`MEMD_SIZE_LOG-1:0] C_mem_addr_r;

cpu_ooo_ext_mem copy1(
    .clk(stall_1 ? 0 : clk),
    .rst(rst),
    .dmem_resp_data(cache_1.resp_data),
    .dmem_resp_delayed(cache_1.resp_delayed)
);

cpu_ooo_ext_mem copy2(
    .clk(stall_2 ? 0 : clk),
    .rst(rst),
    .dmem_resp_data(cache_2.resp_data),
    .dmem_resp_delayed(cache_2.resp_delayed)
);

// =========================================================================
// Shadow Logic (same as two_copy_top_ct.v)
// =========================================================================
always @(posedge clk) begin
    if (rst) begin
        stall_1 <= 0;
        stall_2 <= 0;
        finish_1 <= 0;
        finish_2 <= 0;
        commit_deviation <= 0;
        invalid_program <= 0;
    end
    else begin
        `ifndef IMM_STALL
        if (!stall_1 && !stall_2 && copy1.C_valid && copy2.C_valid) begin
            if (copy1.C_mem_valid && copy1.C_mem_rdwt && copy2.C_mem_valid && copy2.C_mem_rdwt && copy1.C_mem_addr != copy2.C_mem_addr)
                invalid_program <= 1;
            if (copy1.C_is_br && copy2.C_is_br && copy1.C_taken != copy2.C_taken)
                invalid_program <= 1;
        end
        else if (!stall_1 && !stall_2 && copy1.C_valid && !copy2.C_valid) begin
            stall_1 <= 1;
            commit_deviation <= 1;
            if (!(commit_deviation || ((`OBSV==`OBSV_EVERY_ADDR) ? addr_deviation : 0))) begin
                ROB_tail_1 <= copy1.ROB_tail;
                ROB_tail_2 <= copy2.ROB_tail;
            end
            C_mem_valid_r <= copy1.C_mem_valid;
            C_mem_rdwt_r <= copy1.C_mem_rdwt;
            C_mem_addr_r <= copy1.C_mem_addr;
            C_is_br_r <= copy1.C_is_br;
            C_taken_r <= copy1.C_taken;
        end
        else if (!stall_1 && !stall_2 && !copy1.C_valid && copy2.C_valid) begin
            stall_2 <= 1;
            commit_deviation <= 1;
            if (!commit_deviation) begin
                ROB_tail_1 <= copy1.ROB_tail;
                ROB_tail_2 <= copy2.ROB_tail;
            end
            C_mem_valid_r <= copy2.C_mem_valid;
            C_mem_rdwt_r <= copy2.C_mem_rdwt;
            C_mem_addr_r <= copy2.C_mem_addr;
            C_is_br_r <= copy2.C_is_br;
            C_taken_r <= copy2.C_taken;
        end
        else if (stall_1 && !stall_2 && copy2.C_valid) begin
            if (C_mem_valid_r && C_mem_rdwt_r && copy2.C_mem_valid && copy2.C_mem_rdwt && C_mem_addr_r != copy2.C_mem_addr)
                invalid_program <= 1;
            if (C_is_br_r && copy2.C_is_br && C_taken_r != copy2.C_taken)
                invalid_program <= 1;
            stall_1 <= 0;
        end
        else if (!stall_1 && stall_2 && copy1.C_valid) begin
            if (copy1.C_mem_valid && copy1.C_mem_rdwt && C_mem_valid_r && C_mem_rdwt_r && copy1.C_mem_addr != C_mem_addr_r)
                invalid_program <= 1;
            if (copy1.C_is_br && C_is_br_r && copy1.C_taken != C_taken_r)
                invalid_program <= 1;
            stall_2 <= 0;
        end
        `else
        if (!stall_1 && !stall_2 && copy1.C_valid && copy2.C_valid) begin
            if (copy1.C_mem_valid && copy1.C_mem_rdwt && copy2.C_mem_valid && copy2.C_mem_rdwt && copy1.C_mem_addr != copy2.C_mem_addr)
                invalid_program = 1;
            if (copy1.C_is_br && copy2.C_is_br && copy1.C_taken != copy2.C_taken)
                invalid_program = 1;
        end
        else if (!stall_1 && !stall_2 && copy1.C_valid && !copy2.C_valid) begin
            stall_1 = 1;
            commit_deviation <= 1;
            if (!(commit_deviation || ((`OBSV==`OBSV_EVERY_ADDR) ? addr_deviation : 0))) begin
                ROB_tail_1 <= copy1.ROB_tail;
                ROB_tail_2 <= copy2.ROB_tail;
            end
        end
        else if (!stall_1 && !stall_2 && !copy1.C_valid && copy2.C_valid) begin
            stall_2 = 1;
            commit_deviation <= 1;
            if (!commit_deviation) begin
                ROB_tail_1 <= copy1.ROB_tail;
                ROB_tail_2 <= copy2.ROB_tail;
            end
        end
        else if (stall_1 && !stall_2 && copy2.C_valid) begin
            if (copy1.C_mem_valid && copy1.C_mem_rdwt && copy2.C_mem_valid && copy2.C_mem_rdwt && copy1.C_mem_addr != copy2.C_mem_addr)
                invalid_program = 1;
            if (copy1.C_is_br && copy2.C_is_br && copy1.C_taken != copy2.C_taken)
                invalid_program = 1;
            stall_1 = 0;
        end
        else if (!stall_1 && stall_2 && copy1.C_valid) begin
            if (copy1.C_mem_valid && copy1.C_mem_rdwt && copy2.C_mem_valid && copy2.C_mem_rdwt && copy1.C_mem_addr != copy2.C_mem_addr)
                invalid_program = 1;
            if (copy1.C_is_br && copy2.C_is_br && copy1.C_taken != copy2.C_taken)
                invalid_program = 1;
            stall_2 = 0;
        end
        `endif

        // Detect deviation in address (only with OBSV_EVERY_ADDR)
        if ((`OBSV==`OBSV_EVERY_ADDR) && !commit_deviation && copy1.ld_addr!=copy2.ld_addr) begin
            addr_deviation <= 1;
            ROB_tail_1 <= copy1.ROB_tail;
            ROB_tail_2 <= copy2.ROB_tail;
        end

        // Drain the ROB
        if ((commit_deviation || ((`OBSV==`OBSV_EVERY_ADDR) ? addr_deviation : 0)) && ((copy1.C_valid && copy1.ROB_head == ROB_tail_1-1 ) || (copy1.C_valid && copy1.C_squash)))
            finish_1 <= 1;
        if ((commit_deviation || ((`OBSV==`OBSV_EVERY_ADDR) ? addr_deviation : 0)) && ((copy2.C_valid && copy2.ROB_head == ROB_tail_1-1 ) || (copy2.C_valid && copy2.C_squash)))
            finish_2 <= 1;
    end
end

endmodule
