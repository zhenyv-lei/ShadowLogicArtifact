# =============================================================================
# Phase 1a (Hybrid): Core Verification under C1 Contract (DarkRISCV 3-stage)
# =============================================================================
# Concrete imem (shared SRAM) + PTCI on dmem only
# Expected result: PASS (core is timing-safe under ideal memory)
# =============================================================================

analyze -sv src/darkriscv/rtl/darkriscv.v src/darkriscv/rtl/two_copy_top_c1.sv -incdir src/darkriscv/rtl
elaborate -top top

clock clk
reset rst -non_resettable_regs 0

# ---------------------------------------------------------------------------
# Abstract register file (secret data: different initial values per copy)
# ---------------------------------------------------------------------------
abstract -init_value {copy1.REGS}
abstract -init_value {copy2.REGS}

get_design_info -list undriven

# ---------------------------------------------------------------------------
# imem ACK constraint (fixed 1-cycle response)
# ---------------------------------------------------------------------------
assume {IDACK_shared}

# ---------------------------------------------------------------------------
# dmem ACK constraints (fixed 1-cycle response)
# ---------------------------------------------------------------------------
assume {DDACK_shared == copy1.DDREQ}
assume {DDACK_unc == copy2.DDREQ}

# ---------------------------------------------------------------------------
# Legal instructions: exclude illegal opcodes
# ---------------------------------------------------------------------------
assume {!copy1.IERR && !copy2.IERR}

# ---------------------------------------------------------------------------
# Same program assumption (constant-time contract)
# ---------------------------------------------------------------------------
assume {!invalid_program}

# ---------------------------------------------------------------------------
# Platform response time for dmem
# ---------------------------------------------------------------------------
assume {copy1.DDREQ |-> ##[0:1] DDACK_shared}
assume {copy2.DDREQ |-> ##[0:1] DDACK_copy2}

# ---------------------------------------------------------------------------
# Security property: no timing leakage
# ---------------------------------------------------------------------------
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# ---------------------------------------------------------------------------
# Reachability covers
# ---------------------------------------------------------------------------

# PTCI allow signals (dmem only)
cover {allow_dmem_gnt_diff}
cover {allow_dmem_rdata_diff}

# sticky signals (dmem only)
cover {sticky_dmem_req}
cover {sticky_dmem_addr}
cover {sticky_dmem_we}
cover {sticky_dmem_wdata}

# diff signals (dmem only)
cover {diff_dmem_req}
cover {diff_dmem_addr}

# shadow logic reachability
cover {commit_deviation}
cover {commit_1}
cover {commit_2}

# ---------------------------------------------------------------------------
# Prove configuration
# ---------------------------------------------------------------------------
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d
prove -all

save -jdb my_jdb_c1_2copy_darkriscv3 -capture_setup -capture_session_data -force

exit
