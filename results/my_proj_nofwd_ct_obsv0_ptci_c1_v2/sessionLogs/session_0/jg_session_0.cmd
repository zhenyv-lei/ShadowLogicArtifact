# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 01:33:04 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3299143
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:38765' '-nowindow' '-exitonerror' '-data' 'AAABKniclY9LCgIxEERfRDfiVfyu5xKK++CMisr4YUYjrvSo3iTWtKAEVzYk1dX9KGgHZPcYI1bu+VYyR1qNb6WT6SNR6HyXbb0efXIWnCnYyHflT1Qc2cnN1K2ouVCKqBmy54b/EJ6DdM2VpfpCjJfPRQZGxjW5W9uN9QcmSp3/pAb5yrj/8wY2K+2iFzDeLA4=' '-bridge_url' '172.28.176.73:44627' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_ptci_c1_v2/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_ptci_c1_v2/.tmp/.initCmds.tcl' 'results/veri_nofwd_ct_obsv0_ptci_c1_v2.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_ptci_c1_v2/.tmp/.postCmds.tcl'
# =============================================================================
# NoFwd_spectre + CT + OBSV=0 + C1 PTCI (correct version)
# =============================================================================
# C1: addr does NOT affect gnt. Only req affects gnt.
# Independent memd per copy (secret at memd[1]).
# PTCI only controls timing (delayed), data from independent memd.
# Expected result: PASS
# =============================================================================

analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_STT=+PARTIAL_STT_USE_SPEC=+OBSV=0+INIT_VALUE=0+IMM_STALL= -sva ./src/simpleooo/two_copy_top_ct_ptci_c1_v2.v

elaborate -top top -bbox_mul 256
clock clk
reset rst -non_resettable_regs 0

# Same program
abstract -init_value {copy1.memi_instance.array}
abstract -init_value {copy2.memi_instance.array}
assume {copy1.memi_instance.array == copy2.memi_instance.array}

# CT contract
assume {invalid_program==0}

# Independent memd: public same, secret (memd[1]) can differ
abstract -init_value {memd_1}
abstract -init_value {memd_2}
assume {init -> memd_1[0] == memd_2[0]}
assume {init -> memd_1[2] == memd_2[2]}
assume {init -> memd_1[3] == memd_2[3]}

# Security property
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# Covers
cover {sticky_dmem_req}
cover {allow_timing_diff}
cover {commit_deviation}

# AM for unbounded proof
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_nofwd_ct_obsv0_ptci_c1_v2 -capture_setup -capture_session_data -force
get_design_info
exit
