# 
#
# Any disclosure about the Cadence Design Systems software or its use
# model to any third party violates the written Non-Disclosure Agreement
# between Cadence Design Systems, Inc. and the customer.
#
# THIS SOFTWARE CONTAINS CONFIDENTIAL INFORMATION AND TRADE SECRETS OF
# CADENCE DESIGN SYSTEMS, INC. USE, DISCLOSURE, OR REPRODUCTION IS
# PROHIBITED WITHOUT THE PRIOR EXPRESS WRITTEN PERMISSION OF CADENCE
# DESIGN SYSTEMS, INC.
#
# Copyright (C) 2000-2025 Cadence Design Systems, Inc. All Rights
# Reserved.  Unpublished -- rights reserved under the copyright laws of
# the United States.
#
# This product includes software developed by others and redistributed
# according to license agreement. See doc/third_party_readme.txt for
# further details.
#
# RESTRICTED RIGHTS LEGEND
#
# Use, duplication, or disclosure by the Government is subject to
# restrictions as set forth in subparagraph (c) (1) (ii) of the Rights in
# Technical Data and Computer Software clause at DFARS 252.227-7013 or
# subparagraphs (c) (1) and (2) of Commercial Computer Software -- Restricted
# Rights at 48 CFR 52.227-19, as applicable.
#
#
#                           Cadence Design Systems, Inc.
#                           2655 Seely Avenue
#                           San Jose, CA 95134
#                           Phone: 408.943.1234
#
# For technical assistance visit http://support.cadence.com.

# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 4.18.0-477.15.1.el8_8.x86_64
# version   : 2025.06 FCS 64 bits
# build date: 2025.06.25 13:01:28 UTC
# ----------------------------------------

# The following script was created on Tue Mar 24 20:46:43 2026

# BEGIN ENV CONFIG COMMANDS
# Setup environment
set_engine_mode engineAM
# END ENV CONFIG COMMANDS
# BEGIN RTL COMMANDS
analyze -sv src/sodor2/sodor_2_stage.sv src/sodor2/interrupt_controller.v src/sodor2/two_copy_top_c4_combined.sv src/sodor2/param.vh
elaborate -top top -bbox_a 1024 -bbox_mul 256 -bbox_m plusarg_reader -bbox_m GenericDigitalInIOCell -bbox_m GenericDigitalOutIOCell -bbox_m ClockDividerN -bbox_m EICG_wrapper
# END RTL COMMANDS
# Setup global clocks
clock clk
# Setup global resets
reset -expression rst -non_resettable_regs 0
# Setup task <embedded>
task -set <embedded>
abstract -init_value copy1.d.regfile\[0]
abstract -init_value copy1.d.regfile\[1]
abstract -init_value copy1.d.regfile\[2]
abstract -init_value copy1.d.regfile\[3]
abstract -init_value copy2.d.regfile\[0]
abstract -init_value copy2.d.regfile\[1]
abstract -init_value copy2.d.regfile\[2]
abstract -init_value copy2.d.regfile\[3]
namespace eval ::post_setup {proc run_post_setup_script {} {}}

