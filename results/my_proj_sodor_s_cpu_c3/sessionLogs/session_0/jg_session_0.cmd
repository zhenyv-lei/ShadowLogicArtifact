# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 20:20:48 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3365984
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:43691' '-nowindow' '-exitonerror' '-data' 'AAAA/nicY2RgYLCp////PwMYMD6A0Aw2jAyoAMRnQhUJbEChGRhYEZIsQMzDoMuQxJDIUMKQzJAB5HMB+QUMRQz5DFkgG4CsVIZihlKGHKCKYgZ9hlyGSoZ4uIp4oFg+QwoQF4HZ8UBTCoCqQbQxUL8dhv4yIL+IIZOATj2we3LArgQAHAcjwA==' '-bridge_url' '172.28.176.73:35907' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_s_cpu_c3/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_s_cpu_c3/.tmp/.initCmds.tcl' 'results/veri_sodor_s_cpu_c3.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_s_cpu_c3/.tmp/.postCmds.tcl'
# =============================================================================
# Sodor-S CPU_C3: Secure Sodor under C3 Platform Timing Contract
# =============================================================================
# Defense: mask interrupts during store execution
# Expected result: PASS
# =============================================================================

analyze -sva src/sodor2/sodor_2_stage.sv src/sodor2/two_copy_top_c3_secure.sv src/sodor2/param.vh

elaborate -top top -bbox_mul 256 -bbox_a 1024 -bbox_m plusarg_reader -bbox_m GenericDigitalInIOCell -bbox_m GenericDigitalOutIOCell -bbox_m ClockDividerN -bbox_m EICG_wrapper
clock clk
reset rst -non_resettable_regs 0

abstract -init_value {copy1.d.regfile}
abstract -init_value {copy2.d.regfile}

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

# Same program assumption (constant-time contract)
assume {!invalid_program}

# Security property
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# Covers
cover {sticky_dmem_wdata}
cover {allow_int_diff}
cover {commit_deviation}

# AM for unbounded proof
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d
prove -all

save -jdb results/my_jdb_sodor_s_cpu_c3 -capture_setup -capture_session_data -force
exit
