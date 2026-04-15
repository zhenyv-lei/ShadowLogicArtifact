# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-23 20:28:48 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3261217
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:45607' '-nowindow' '-exitonerror' '-data' 'AAABDnicjY5BCsJADEXfSN2IV6m9QJfi3hOUVgZaqbZ0VHClR/Um4zeCMrgxEJKX/HzigPIWY8TCPd6V0pHGi2fpZHtPKsy/y0y5JKeh5sSOVrwQj0wM7EVrdZ7AmV6KQMGBK9VHUemqtkuvPhgP0ozSd9ocxV4+mx+fi3iS5j+Hlf3X29dPjaMnJg==' '-bridge_url' '172.28.176.73:33883' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_cache_s_compliance/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_cache_s_compliance/.tmp/.initCmds.tcl' 'results/veri_cache_s_compliance.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_cache_s_compliance/.tmp/.postCmds.tcl'
# =============================================================================
# Experiment B: Cache-S Contract Compliance Verification
# =============================================================================
# Verify Cache-S satisfies C1 contract (timing independent of address).
# Expected result: PASS
# =============================================================================

analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2 -sva ./src/simpleooo/cache_miter_verify.v

elaborate -top cache_miter_top
clock clk
reset rst -non_resettable_regs 0

# Abstract internal storage (different secrets between instances)
abstract -init_value {cache_1.mem}
abstract -init_value {cache_2.mem}

# C1 assertion: timing never depends on address
assert {c1_timing_safe}
assert {c1_timing_equal}

# Prove
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 1h

prove -all
save -jdb results/my_jdb_cache_s_compliance -capture_setup -capture_session_data -force
exit
