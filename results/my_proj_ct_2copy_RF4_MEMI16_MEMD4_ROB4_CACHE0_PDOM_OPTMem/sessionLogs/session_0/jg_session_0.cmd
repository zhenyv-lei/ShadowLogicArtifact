# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-23 17:28:23 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3232659
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:39191' '-nowindow' '-exitonerror' '-data' 'AAABinicvZC7CsJQEERPRBvxV3wiVml8ooUkBvugElCJRJIoWCnih/oncXIFJdi7sDs7O3PZy1qAfc2yDBPW843YFsXIeak4WdwKCJWvWFbWqLNmRcqGrXhV/EhMxF7sri4g4UQoR0KTAxf8j8PXq1S1I4w0zTWPCV3hnLFyRpveh42M4uEwMN2QvnIqrSXmSnfk8lVdluoC7YPHzy/O4jG7v+xvmNuE5mIvZoE3uA==' '-bridge_url' '172.28.176.73:33383' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PDOM_OPTMem/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PDOM_OPTMem/.tmp/.initCmds.tcl' 'results/veri_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PDOM_OPTMem.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PDOM_OPTMem/.tmp/.postCmds.tcl'
analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_DOM=+OBSV=1+INIT_VALUE=0 -sva ./src/simpleooo/two_copy_top_ct.v

elaborate -top top -bbox_mul 256
clock clk
reset rst -non_resettable_regs 0

abstract -init_value {copy1.memi_instance.array}
abstract -init_value {copy2.memi_instance.array}
assume {copy1.memi_instance.array == copy2.memi_instance.array}

assume {invalid_program==0}

abstract -init_value {copy1.memd}
abstract -init_value {copy2.memd}
assume {init -> copy1.memd[0] == copy2.memd[0]}
assume {init -> copy1.memd[2] == copy2.memd[2]}
assume {init -> copy1.memd[3] == copy2.memd[3]}

assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

set_prove_orchestration off
set_engine_mode {AM}

set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PDOM_OPTMem -capture_setup -capture_session_data
get_design_info
exit
