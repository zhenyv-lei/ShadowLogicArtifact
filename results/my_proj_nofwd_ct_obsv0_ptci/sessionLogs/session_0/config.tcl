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

# The following script was created on Tue Mar 24 01:25:08 2026

# BEGIN ENV CONFIG COMMANDS
# Setup environment
set_engine_mode engineHt
# END ENV CONFIG COMMANDS
# BEGIN RTL COMMANDS
analyze -sv +define+RF_SIZE=4+RF_SIZE_LOG=2+MEMI_SIZE=16+MEMI_SIZE_LOG=4+MEMD_SIZE=4+MEMD_SIZE_LOG=2+ROB_SIZE=4+ROB_SIZE_LOG=2+BR_PREDICT=0+USE_DEFENSE_PARTIAL_STT=+PARTIAL_STT_USE_SPEC=+OBSV=0+INIT_VALUE=0+IMM_STALL= ./src/simpleooo/two_copy_top_ct_ptci.v
elaborate -top top -bbox_mul 256
# END RTL COMMANDS
# Setup global clocks
clock clk
# Setup global resets
reset -expression rst -non_resettable_regs 0
# Setup task <embedded>
task -set <embedded>
abstract -init_value copy1.memi_instance.array\[0]
abstract -init_value copy1.memi_instance.array\[10]
abstract -init_value copy1.memi_instance.array\[11]
abstract -init_value copy1.memi_instance.array\[12]
abstract -init_value copy1.memi_instance.array\[13]
abstract -init_value copy1.memi_instance.array\[14]
abstract -init_value copy1.memi_instance.array\[15]
abstract -init_value copy1.memi_instance.array\[1]
abstract -init_value copy1.memi_instance.array\[2]
abstract -init_value copy1.memi_instance.array\[3]
abstract -init_value copy1.memi_instance.array\[4]
abstract -init_value copy1.memi_instance.array\[5]
abstract -init_value copy1.memi_instance.array\[6]
abstract -init_value copy1.memi_instance.array\[7]
abstract -init_value copy1.memi_instance.array\[8]
abstract -init_value copy1.memi_instance.array\[9]
abstract -init_value copy2.memi_instance.array\[0]
abstract -init_value copy2.memi_instance.array\[10]
abstract -init_value copy2.memi_instance.array\[11]
abstract -init_value copy2.memi_instance.array\[12]
abstract -init_value copy2.memi_instance.array\[13]
abstract -init_value copy2.memi_instance.array\[14]
abstract -init_value copy2.memi_instance.array\[15]
abstract -init_value copy2.memi_instance.array\[1]
abstract -init_value copy2.memi_instance.array\[2]
abstract -init_value copy2.memi_instance.array\[3]
abstract -init_value copy2.memi_instance.array\[4]
abstract -init_value copy2.memi_instance.array\[5]
abstract -init_value copy2.memi_instance.array\[6]
abstract -init_value copy2.memi_instance.array\[7]
abstract -init_value copy2.memi_instance.array\[8]
abstract -init_value copy2.memi_instance.array\[9]
abstract -init_value memd_1\[0]
abstract -init_value memd_1\[1]
abstract -init_value memd_1\[2]
abstract -init_value memd_1\[3]
abstract -init_value memd_2\[0]
abstract -init_value memd_2\[1]
abstract -init_value memd_2\[2]
abstract -init_value memd_2\[3]
namespace eval ::post_setup {proc run_post_setup_script {} {}}

