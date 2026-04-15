# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 01:45:19 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3303529
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:35997' '-nowindow' '-exitonerror' '-data' 'AAABHniclY9BCsIwFERfRDfiVariukcQwRMEWwWViNJqwVU9qjeJky8owZUfws+bmQzEAWUfY8TGPd+b0pFP4kGurB/ZhtHXHOpMKKjYcKVmLx6LLzScOYqWuu1ouRGUaJlx4o7/JDxb+UHvk1or46VXSnbMLZd6D+Yt1Lf66evEjSX+aZoaBfvFCxteKdg=' '-bridge_url' '172.28.176.73:36047' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_delay_ct_obsv0_ptci_c2/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_delay_ct_obsv0_ptci_c2/.tmp/.initCmds.tcl' 'results/veri_delay_ct_obsv0_ptci_c2.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_delay_ct_obsv0_ptci_c2/.tmp/.postCmds.tcl'
# =============================================================================
# Experiment (6): SimpleOoO-S (Delay_spectre) + C2 PTCI
# =============================================================================
# Delay_spectre prevents speculative loads from issuing.
# C2 PTCI: addr difference allows timing difference.
# Expected: PASS (no speculative loads → no secret-dependent addresses → PTCI never triggers)
# =============================================================================

analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_DOM=+OBSV=0+INIT_VALUE=0+IMM_STALL= -sva ./src/simpleooo/two_copy_top_ct_ptci.v

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

# PTCI covers
cover {sticky_dmem_addr}
cover {diff_dmem_addr}
cover {allow_timing_diff}
cover {commit_deviation}

# AM for unbounded proof
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_delay_ct_obsv0_ptci_c2 -capture_setup -capture_session_data -force
get_design_info
exit
