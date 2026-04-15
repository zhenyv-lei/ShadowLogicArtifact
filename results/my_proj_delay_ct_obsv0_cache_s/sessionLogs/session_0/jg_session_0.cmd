# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 01:33:21 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3299501
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:38223' '-nowindow' '-exitonerror' '-data' 'AAABHniclY9dCsIwEIS/iL6IV/HnAD2CCJ4gtLWgElEaW/BJj+pN4nQFJfjkQtj9ZidD4oDinlLCyj3fncKR18CjXNk+sg6T73KsM2NORcmVmr14Kr7QcuYoWmtqiHQEOSJLTtzwH4dnp33Q/UGt5fHSKzl7VqaUlttojsrb/OT14pbDn0kLe2+wX7wAJkoqHA==' '-bridge_url' '172.28.176.73:37035' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_delay_ct_obsv0_cache_s/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_delay_ct_obsv0_cache_s/.tmp/.initCmds.tcl' 'results/veri_delay_ct_obsv0_cache_s.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_delay_ct_obsv0_cache_s/.tmp/.postCmds.tcl'
# =============================================================================
# Experiment C: SimpleOoO-SS (Delay_spectre) + Cache-S Combined Verification
# =============================================================================
# CPU with Delay defense + fixed-latency secure cache.
# Expected result: PASS
# =============================================================================

analyze +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_DOM=+OBSV=0+INIT_VALUE=0+IMM_STALL= -sva ./src/simpleooo/two_copy_top_ct_cache_s.v

elaborate -top top -bbox_mul 256
clock clk
reset rst -non_resettable_regs 0

# Same program for both copies
abstract -init_value {copy1.memi_instance.array}
abstract -init_value {copy2.memi_instance.array}
assume {copy1.memi_instance.array == copy2.memi_instance.array}

# CT contract constraint
assume {invalid_program==0}

# Abstract cache memory: public entries same, secret (mem[1]) can differ
abstract -init_value {cache_1.mem}
abstract -init_value {cache_2.mem}
assume {init -> cache_1.mem[0] == cache_2.mem[0]}
assume {init -> cache_1.mem[2] == cache_2.mem[2]}
assume {init -> cache_1.mem[3] == cache_2.mem[3]}

# Security property
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# Prove configuration (AM for unbounded proof)
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d

prove -all
save -jdb results/my_jdb_delay_ct_obsv0_cache_s -capture_setup -capture_session_data -force
get_design_info
exit
