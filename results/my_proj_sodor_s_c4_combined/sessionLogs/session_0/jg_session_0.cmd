# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 20:46:39 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3371884
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:36091' '-nowindow' '-exitonerror' '-data' 'AAABEnicjY5BCsIwEEVfRDfiVdSNy67FrScI1goq1UhaBVf2qL1J/I6gBDcOTGbezM9nHFA8UkpYuP5dKRx5vHiQT9ZdVmH0XQ6VE6aUbGjZshePxRcigaNoqW5Hw5VaioY5J+74j8JrFqiU0Xovl4W9QcqSA2f9r+S0+nG6iaMU/3rM7MbaLn8CLHonyA==' '-bridge_url' '172.28.176.73:34349' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_s_c4_combined/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_s_c4_combined/.tmp/.initCmds.tcl' 'results/veri_sodor_s_c4_combined.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_sodor_s_c4_combined/.tmp/.postCmds.tcl'
# =============================================================================
# Sodor-S + Interrupt Controller: Combined Verification
# =============================================================================
# Sodor Core + real interrupt controller + PMP constraint.
# Expected: PASS
# =============================================================================

analyze -sva src/sodor2/sodor_2_stage.sv src/sodor2/interrupt_controller.v src/sodor2/two_copy_top_c4_combined.sv src/sodor2/param.vh

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

# CT contract
assume {!invalid_program}

# PMP constraint: stores to periph_range must have same wdata
assume {(copy1.io_dmem_req_bits_fcn && copy1.io_dmem_req_bits_addr[31:2] < 1) -> (copy1.io_dmem_req_bits_data == copy2.io_dmem_req_bits_data)}

# Security property
assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

# Prove
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d
prove -all

save -jdb results/my_jdb_sodor_s_c4_combined -capture_setup -capture_session_data -force
exit
