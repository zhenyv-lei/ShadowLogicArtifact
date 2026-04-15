# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 02:03:46 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3310480
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:38333' '-nowindow' '-exitonerror' '-data' 'AAABHniclY9bCsIwFERPRH/ErfhYQJcggisIba2o1AdNrfilS3UncbyCEvzyQpg5N8OQOCC7xRixcY+3kjnSeXEv3SzvicLge9nXGTGmIKelZCMeik80HNmJ5nIVgTO1EoEpe674T8JzkK65sJIvlfHiQsmOmW1y663kg/oWP32duGH7Z9PE3lvbL54xgCo6' '-bridge_url' '172.28.176.73:41007' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_cache_s/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_cache_s/.tmp/.initCmds.tcl' 'results/veri_nofwd_ct_obsv0_cache_s.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_cache_s/.tmp/.postCmds.tcl'
# =============================================================================
# Supplementary: NoFwd_spectre + CT + OBSV=0 + Cache-S
# =============================================================================
# Fix ONLY the platform side (Cache-S, fixed latency), keep NoFwd defense.
# Expected result: PASS (fixed-latency cache eliminates timing side channel)
# =============================================================================

analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_STT=+PARTIAL_STT_USE_SPEC=+OBSV=0+INIT_VALUE=0+IMM_STALL= -sva ./src/simpleooo/two_copy_top_ct_cache_s.v

elaborate -top top -bbox_mul 256
clock clk
reset rst -non_resettable_regs 0

# Same program
abstract -init_value {copy1.memi_instance.array}
abstract -init_value {copy2.memi_instance.array}
assume {copy1.memi_instance.array == copy2.memi_instance.array}

# CT contract
assume {invalid_program==0}

# Abstract cache memory: public same, secret (mem[1]) can differ
abstract -init_value {cache_1.mem}
abstract -init_value {cache_2.mem}
assume {init -> cache_1.mem[0] == cache_2.mem[0]}
assume {init -> cache_1.mem[2] == cache_2.mem[2]}
assume {init -> cache_1.mem[3] == cache_2.mem[3]}

# Security property
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# AM for unbounded proof
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_nofwd_ct_obsv0_cache_s -capture_setup -capture_session_data -force
get_design_info
exit
