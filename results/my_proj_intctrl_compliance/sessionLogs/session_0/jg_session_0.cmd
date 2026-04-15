# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------
# started   : 2026-03-24 19:47:57 +08
# hostname  : everest3.comp.nus.edu.sg.(none)
# pid       : 3359169
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:42175' '-nowindow' '-exitonerror' '-data' 'AAABDnicjY5BCsIwEEVfSt1Ir9L2Al2Ke09Q2iCopCptLXSlR/Um6TeCEtw4EGbe/3+GGKC6e+8JZZ7vTmWI68VJrOweUYfV10z1MnJaGkYsB/FafKXnwkm00bRn4IZTYqCkY6b+JGqOnMPuKMWJrfROvpPTyLPah+3PnUncK/PfhSIkXPj1ArATJ5o=' '-bridge_url' '172.28.176.73:34903' '-proj' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_intctrl_compliance/sessionLogs/session_0' '-init' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_intctrl_compliance/.tmp/.initCmds.tcl' 'results/veri_intctrl_compliance.tcl' '-hidden' '/home/zhenyu.lei/ShadowLogicArtifact/results/my_proj_intctrl_compliance/.tmp/.postCmds.tcl'
# =============================================================================
# Platform_C2 / Platform_C3: Interrupt Controller Compliance Verification
# =============================================================================
# Platform_C2: wdata must NOT affect int → expected FAIL
# Platform_C3: wdata CAN affect int → expected PASS (trivially)
# =============================================================================

analyze -sva src/sodor2/intctrl_miter_verify.v src/sodor2/interrupt_controller.v src/sodor2/param.vh

elaborate -top intctrl_compliance_top
clock clk
reset rst -non_resettable_regs 0

# Platform_C2: different wdata must NOT affect interrupt
assert -name c2_intctrl {c2_intctrl_pass}

# Platform_C3: trivially PASS (C3 allows wdata → int)
assert -name c3_intctrl {c3_intctrl_pass}

# Prove
set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 1h

prove -all
save -jdb results/my_jdb_intctrl_compliance -capture_setup -capture_session_data -force
exit
