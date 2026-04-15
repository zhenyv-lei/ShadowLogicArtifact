# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 01:33:14 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3299331
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:41189' '-nowindow' '-exitonerror' '-data' 'AAABPnicpY9dDgExFIW/Ci9iK34WMJvwLhozRpApMsPgiaXaSZ2WkMajmzTnfPee3qYGyG7ee2KZx0vJDGkF7qSd6T1R6H2HXZ0BQ3IWHClYi/viAzV7tqKZXEnDiUqJhjGOK/aTsOykK84s5QtlrDhXsmUiX3KJPSfn3ulwO7y20f75z/5WXGv23+ZR1Cr+8glEZjFC' '-bridge_url' '172.28.176.73:37955' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_ext_mem_no_ptci/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_ext_mem_no_ptci/.tmp/.initCmds.tcl' 'results/veri_nofwd_ct_obsv0_ext_mem_no_ptci.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_ext_mem_no_ptci/.tmp/.postCmds.tcl'
# =============================================================================
# Experiment 1b: NoFwd_spectre + CT + OBSV_COMMITTED_ADDR + ext_mem (NO PTCI)
# =============================================================================
# Sanity check: cpu_ooo_ext_mem with external memd but dmem_resp_delayed=0
# Expected result: PASS (equivalent to Experiment 1 with original cpu_ooo.v)
# =============================================================================

analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_STT=+PARTIAL_STT_USE_SPEC=+OBSV=0+INIT_VALUE=0+IMM_STALL= -sva ./src/simpleooo/two_copy_top_ct_ext_mem.v

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

# Prove configuration (AM for unbounded proof)
set_prove_orchestration off
set_engine_mode {AM}

set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_nofwd_ct_obsv0_ext_mem_no_ptci -capture_setup -capture_session_data -force
get_design_info
exit
