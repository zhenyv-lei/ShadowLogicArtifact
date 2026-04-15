# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 12:22:03 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3327698
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:41907' '-nowindow' '-exitonerror' '-data' 'AAAA9nicfY5RCoJQEEXPC/0Jt5KBXxFuwhVIWaBhGM8U/KqltpPX9QXFQ2hguHPuzIUxQP5wzuHLvD5Kbghr5lXoFM9AIf4tI3XChiMH7lTU4rX4hqXjItppOtMz0OqiZ8uVifJ7UcrrOKmt5kr+4DVTdr/IjmJL8yeV+j9a/90b8osiEg==' '-bridge_url' '172.28.176.73:43247' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_cpu_c2/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_cpu_c2/.tmp/.initCmds.tcl' 'results/veri_sodor_cpu_c2.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_cpu_c2/.tmp/.postCmds.tcl'
# =============================================================================
# Sodor CPU_C2: C2 Platform Timing Contract Verification
# =============================================================================
# C2: addr can affect gnt, but wdata does NOT affect gnt or int
# Expected result: PASS (Sodor has no speculative execution)
# =============================================================================

analyze -sva src/sodor2/sodor_2_stage.sv src/sodor2/two_copy_top_c2.sv src/sodor2/param.vh

elaborate -top top -bbox_mul 256 -bbox_a 1024 -bbox_m plusarg_reader -bbox_m GenericDigitalInIOCell -bbox_m GenericDigitalOutIOCell -bbox_m ClockDividerN -bbox_m EICG_wrapper
clock clk
reset rst -non_resettable_regs 0

abstract -init_value {copy1.d.regfile}
abstract -init_value {copy2.d.regfile}

get_design_info -list undriven

# ---------------------------------------------------------------------------
# Address range constraints
# ---------------------------------------------------------------------------
assume {(copy1.io_imem_req_bits_addr >> 2) < `IMEM_SIZE}
assume {(copy2.io_imem_req_bits_addr >> 2) < `IMEM_SIZE}
assume {(mem_addr_1>>2 < `MEM_SIZE && mem_addr_1>>2 >= `DMEM_SIZE) || mem_addr_1 == 0}
assume {(mem_addr_2>>2 < `MEM_SIZE && mem_addr_2>>2 >= `DMEM_SIZE) || mem_addr_2 == 0}

# ---------------------------------------------------------------------------
# Legal instructions
# ---------------------------------------------------------------------------
assume {copy1.d.regfile_exe_rs1_data_MPORT_addr < `RF_SIZE && copy1.d.regfile_exe_rs2_data_MPORT_addr < `RF_SIZE}
assume {copy2.d.regfile_exe_rs1_data_MPORT_addr < `RF_SIZE && copy2.d.regfile_exe_rs2_data_MPORT_addr < `RF_SIZE}
assume {copy1.d.regfile_MPORT_1_addr < `RF_SIZE}
assume {copy2.d.regfile_MPORT_1_addr < `RF_SIZE}
assume {!copy1.c.illegal && !copy2.c.illegal}
assume {!copy1.c.io_dat_inst_misaligned && !copy2.c.io_dat_inst_misaligned}
assume {!copy1.c.io_dat_data_misaligned && !copy2.c.io_dat_data_misaligned}

# ---------------------------------------------------------------------------
# Same program assumption (constant-time contract)
# ---------------------------------------------------------------------------
assume {!invalid_program}

# ---------------------------------------------------------------------------
# Security property: no timing leakage
# ---------------------------------------------------------------------------
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# ---------------------------------------------------------------------------
# Prove configuration (AM for unbounded proof)
# ---------------------------------------------------------------------------
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d
prove -all

save -jdb results/my_jdb_sodor_cpu_c2 -capture_setup -capture_session_data -force

exit
