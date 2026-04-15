# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-23 21:16:11 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3267715
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:46189' '-nowindow' '-exitonerror' '-data' 'AAABHniclY9LCsJAEAVrRDfiVaLiOkcQIScYTFRU4odEE1zpUb3J+NKCMriyYeiu6eJBOyC9hxCwcs93J3XE1XEv/skeUYfBd9nXG5GQs+RCwVY8FJ+pOLEXzTWtqblSyqiZcOCG/xieo/qGlpXmQo4X5zIbpuZ1uTvbzZS3+MlrxJUZ/ySNjUq74gUmlCn2' '-bridge_url' '172.28.176.73:44047' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_ptci_c2/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_ptci_c2/.tmp/.initCmds.tcl' 'results/veri_nofwd_ct_obsv0_ptci_c2.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_ptci_c2/.tmp/.postCmds.tcl'
# =============================================================================
# Experiment I: NoFwd_spectre + CT + OBSV=0 + Complete C2 PTCI
# =============================================================================
# Complete C2 PTCI: controls both rdata and gnt for copy2.
# Shared memd, rdata/gnt differences controlled by PTCI sticky logic.
# Expected result: FAIL
# =============================================================================

analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_STT=+PARTIAL_STT_USE_SPEC=+OBSV=0+INIT_VALUE=0+IMM_STALL= -sva ./src/simpleooo/two_copy_top_ct_ptci_c2.v

elaborate -top top -bbox_mul 256
clock clk
reset rst -non_resettable_regs 0

# Same program for both copies
abstract -init_value {copy1.memi_instance.array}
abstract -init_value {copy2.memi_instance.array}
assume {copy1.memi_instance.array == copy2.memi_instance.array}

# CT contract constraint
assume {invalid_program==0}

# Abstract shared memd (formal tool explores all initial values)
abstract -init_value {memd}

# Security property
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# PTCI reachability covers
cover {sticky_req}
cover {sticky_addr}
cover {allow_gnt_diff}
cover {allow_rdata_diff}
cover {commit_deviation}

# Prove configuration (Ht to find counterexample)
set_prove_orchestration off
set_engine_mode {Ht}
set_prove_time_limit 7d

prove -all
