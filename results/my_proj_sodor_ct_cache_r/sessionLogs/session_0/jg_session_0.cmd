# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-04-01 00:07:56 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3869745
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:39037' '-nowindow' '-exitonerror' '-data' 'AAABBnicY2RgYLCp////PwMYMD6A0Aw2jAyoAMRnQhUJbEChGRhYEZIsQMzDoMuQxJDIUMKQzJAB5HMB+QUMRQz5DFlAngOQlcpQzFDKkANUUcygz5DLUMkQD1cRDxTLZ0gB4iIgOxmoBkQmgs1KBbKLgGY4YZhRBuQXMWQSoVsP7K4csGsBWOIloA==' '-bridge_url' '172.28.176.73:44315' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_ct_cache_r/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_ct_cache_r/.tmp/.initCmds.tcl' 'results/veri_sodor_ct_cache_r.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_ct_cache_r/.tmp/.postCmds.tcl'
# =============================================================================
# Sodor + Regular Cache: Combined Verification
# =============================================================================
# Expected: PASS (Sodor has no speculative execution)
# =============================================================================

analyze -sva src/sodor2/sodor_2_stage.sv src/sodor2/two_copy_top_ct_cache_r.sv src/sodor2/param.vh

elaborate -top top -bbox_mul 256 -bbox_a 1024 -bbox_m plusarg_reader -bbox_m GenericDigitalInIOCell -bbox_m GenericDigitalOutIOCell -bbox_m ClockDividerN -bbox_m EICG_wrapper
clock clk
reset rst -non_resettable_regs 0

abstract -init_value {copy1.d.regfile}
abstract -init_value {copy2.d.regfile}

# Abstract cache memory
abstract -init_value {cache_1.mem}
abstract -init_value {cache_2.mem}
assume {cache_1.mem == cache_2.mem}

# Abstract cache tags (same initial state)
abstract -init_value {cache_1.cached_addr}
abstract -init_value {cache_2.cached_addr}
assume {cache_1.cached_addr == cache_2.cached_addr}

get_design_info -list undriven

# Address range constraints
assume {(copy1.io_imem_req_bits_addr >> 2) < `IMEM_SIZE}
assume {(copy2.io_imem_req_bits_addr >> 2) < `IMEM_SIZE}
assume {(mem_addr_1>>2 < `MEM_SIZE && mem_addr_1>>2 >= `DMEM_SIZE) || mem_addr_1 == 0}
assume {(mem_addr_2>>2 < `MEM_SIZE && mem_addr_2>>2 >= `DMEM_SIZE) || mem_addr_2 == 0}

# Legal instructions
assume {copy1.d.regfile_exe_rs1_data_MPORT_addr < `RF_SIZE && copy1.d.regfile_exe_rs2_data_MPORT_addr < `RF_SIZE}
assume {copy2.d.regfile_exe_rs1_data_MPORT_addr < `RF_SIZE && copy2.d.regfile_exe_rs2_data_MPORT_addr < `RF_SIZE}
assume {copy1.d.regfile_MPORT_1_addr < `RF_SIZE}
assume {copy2.d.regfile_MPORT_1_addr < `RF_SIZE}
assume {!copy1.c.illegal && !copy2.c.illegal}
assume {!copy1.c.io_dat_inst_misaligned && !copy2.c.io_dat_inst_misaligned}
assume {!copy1.c.io_dat_data_misaligned && !copy2.c.io_dat_data_misaligned}

# CT contract
assume {!invalid_program}

# Security property
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# Prove
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d
prove -all

save -jdb results/my_jdb_sodor_ct_cache_r -capture_setup -capture_session_data -force
exit
