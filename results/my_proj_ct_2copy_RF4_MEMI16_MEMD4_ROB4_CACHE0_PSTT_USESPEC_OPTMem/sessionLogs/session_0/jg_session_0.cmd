# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-23 17:19:42 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3230480
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:46493' '-nowindow' '-exitonerror' '-data' 'AAABqnicxZDLDsFgEIW/ChvxKq4Rq26oCgtpFesGaYJUiFtixTOIB/QmdfpLSOMBzJ+Zc85c8k/GAuxrkiQYs55vxLbIWqpz2czolkEofIt5eYkyc2YcWbCULkrv2LNlLXUXizhwIlbHgSobLoSfjlBTR8WGcKtsWgvo0RQOceUD6rQ+qmsqAR4dwxza8r5qNSmfMRO9kKmYK/cVHWlPbKL5SP/D42ers/Se1V/2qZjbxeaiL9aWPPw=' '-bridge_url' '172.28.176.73:46105' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC_OPTMem/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC_OPTMem/.tmp/.initCmds.tcl' 'results/veri_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC_OPTMem.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC_OPTMem/.tmp/.postCmds.tcl'
analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_STT=+PARTIAL_STT_USE_SPEC=+OBSV=1+INIT_VALUE=0 -sva ./src/simpleooo/two_copy_top_ct.v

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
set_engine_mode {Ht}

set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC_OPTMem -capture_setup -capture_session_data
get_design_info
exit
