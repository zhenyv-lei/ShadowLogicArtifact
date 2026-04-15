# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-23 19:59:28 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3254094
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:44403' '-nowindow' '-exitonerror' '-data' 'AAABEnicjY5NCsIwFIS/iG7Eq7T1AF2LW08Q2lpQiSitLbjSo3qTdBJBCW588JjMT4ZngPLhvSeOeb2R0pBO4LNU2T0ThMXXnGtXZNRU3Gg4iC/Fr3RcOIlt9GrpGXBK9BScuWM/CctevtP/oDbKWOm1kiPrmAu9RzVtf5pG8U7evx15RBcvnwAxsifk' '-bridge_url' '172.28.176.73:44093' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_delay_ct_obsv0_ptci/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_delay_ct_obsv0_ptci/.tmp/.initCmds.tcl' 'results/veri_delay_ct_obsv0_ptci.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_delay_ct_obsv0_ptci/.tmp/.postCmds.tcl'
# =============================================================================
# Experiment 4: Delay_spectre + CT + OBSV_COMMITTED_ADDR + PTCI (C2)
# =============================================================================
# Delay_spectre prevents speculative loads from issuing entirely.
# Expected result: PASS (even with C2 PTCI, no speculative memory access)
# =============================================================================

analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_DOM=+OBSV=0+INIT_VALUE=0+IMM_STALL= -sva ./src/simpleooo/two_copy_top_ct_ptci.v

elaborate -top top -bbox_mul 256
clock clk
reset rst -non_resettable_regs 0

# Same program for both copies
abstract -init_value {copy1.memi_instance.array}
abstract -init_value {copy2.memi_instance.array}
assume {copy1.memi_instance.array == copy2.memi_instance.array}

# CT contract constraint
assume {invalid_program==0}

# Abstract memory: public entries same, secret (memd[1]) can differ
abstract -init_value {memd_1}
abstract -init_value {memd_2}
assume {init -> memd_1[0] == memd_2[0]}
assume {init -> memd_1[2] == memd_2[2]}
assume {init -> memd_1[3] == memd_2[3]}

# Security property
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# PTCI reachability covers
cover {sticky_dmem_addr}
cover {diff_dmem_addr}
cover {allow_timing_diff}
cover {commit_deviation}

# Prove configuration (AM for unbounded proof)
set_prove_orchestration off
set_engine_mode {AM}

set_prove_time_limit 7d

prove -all
