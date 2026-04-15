# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 01:49:50 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3305515
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:45271' '-nowindow' '-exitonerror' '-data' 'AAABHniclY9bCsIwFERPRH/ErfhYQJcggisIba2o1AdprfilS3UncbyCEvzyQpg5N8OQOCC7xRixcY+3kjnSeXEv3SzvicLge9nXGTGmIKelZCMeik8EjuxEc7mKhjO1Eg1T9lzxn4TnIF1zYSVfKuPFhZIdM9vk1lvJB/Utfvo6cWD7Z9PE3lvbL54xGio4' '-bridge_url' '172.28.176.73:37871' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_cache_r/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_cache_r/.tmp/.initCmds.tcl' 'results/veri_nofwd_ct_obsv0_cache_r.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_nofwd_ct_obsv0_cache_r/.tmp/.postCmds.tcl'
# =============================================================================
# Experiment (3): NoFwd_spectre + CT + OBSV=0 + Regular Cache (ext_mem version)
# =============================================================================
# Uses cpu_ooo_ext_mem + cache_regular (with store support).
# Expected result: FAIL (cache hit/miss causes timing leak)
# =============================================================================

analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_STT=+PARTIAL_STT_USE_SPEC=+OBSV=0+INIT_VALUE=0+IMM_STALL= -sva ./src/simpleooo/two_copy_top_ct_cache_r.v

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

# Abstract cache tag (same initial state)
abstract -init_value {cache_1.cached_addr}
abstract -init_value {cache_2.cached_addr}
assume {init -> cache_1.cached_addr == cache_2.cached_addr}

# Security property
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# Prove (Ht to find counterexample)
set_prove_orchestration off
set_engine_mode {Ht}
set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_nofwd_ct_obsv0_cache_r -capture_setup -capture_session_data -force
get_design_info
exit
