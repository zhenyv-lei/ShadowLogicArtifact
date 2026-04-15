# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 13:19:14 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3332226
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:37177' '-nowindow' '-exitonerror' '-data' 'AAABinicvZDNCoJQEIU/ozbRq1QY0apNv9QiNGkvFUKFYagFrYroQXsTO97AkPYNzJw5c85lLmMB/VuWZZiwXh+kb1GOnFfKk+W9hFD7ilVlgyYb1qRs2YnXxU/ERBzEHuoCEs6EciS0OXLFLxy+XqWqHWGkaa55TOkKF0yUc2x6BRsbxcNhaLoRA+VMmi3mSnfk8lVdVuoC7YPnzy8u4jH7v+xvmduE5mJvZ003ug==' '-bridge_url' '172.28.176.73:35771' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE1_PDOM_OPTMem/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE1_PDOM_OPTMem/.tmp/.initCmds.tcl' 'results/veri_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE1_PDOM_OPTMem.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE1_PDOM_OPTMem/.tmp/.postCmds.tcl'
analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_DOM=+USE_CACHE=+OBSV=1+INIT_VALUE=0 -sva ./src/simpleooo/two_copy_top_ct.v

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

abstract -init_value {copy1.cached_addr}
abstract -init_value {copy2.cached_addr}
assume {init -> copy1.cached_addr == copy2.cached_addr}
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

set_prove_orchestration off
set_engine_mode {AM}

set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE1_PDOM_OPTMem -capture_setup -capture_session_data
get_design_info
exit
