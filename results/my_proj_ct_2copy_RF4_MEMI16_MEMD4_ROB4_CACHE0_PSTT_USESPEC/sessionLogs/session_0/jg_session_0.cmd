# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-23 17:16:48 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3229509
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:44149' '-nowindow' '-exitonerror' '-data' 'AAABjnicvZDNDsFQEIW/ChvxKn4jVt1QFRai/tYNIkEqlbYkVizEc3qTOq6ENPbm5syZM2duMhkLsC9pmmLCerwZ2yIbL53LdsbXDEPha+aFEmWWLEhYsZEuSh+ICNlJ3VStiTkSaCKmyp4z/mfC169EuSEO1X15E3o0xUNcYUCd1kd1jTNhRMdUDm2hL68m5TFlpuczV+UKnrKjPe4/e5ykI7Z/2qBi7hOYqz0BL8g3/g==' '-bridge_url' '172.28.176.73:44325' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC/.tmp/.initCmds.tcl' 'results/veri_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC/.tmp/.postCmds.tcl'
analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_STT=+PARTIAL_STT_USE_SPEC=+OBSV=1+INIT_VALUE=0 -sva ./src/simpleooo/two_copy_top_ct.v

elaborate -top top -bbox_mul 256
clock clk
reset rst -non_resettable_regs 0

abstract -init_value {copy1.memi_instance.array}
abstract -init_value {copy2.memi_instance.array}
assume {copy1.memi_instance.array == copy2.memi_instance.array}

assume {invalid_program==0}

abstract -init_value {copy1.memd[1]}
abstract -init_value {copy2.memd[1]}

assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

set_prove_orchestration off
set_engine_mode {AM}

set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PSTT_USESPEC -capture_setup -capture_session_data
get_design_info
exit
