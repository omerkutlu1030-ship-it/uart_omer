################################################################################
# compile_uvvm.do
#
# Compile the UART project (RTL + AXI-Lite wrapper) and run the UVVM-based
# testbench.
#
# Usage:
#   cd /home/intern/uart_omer
#   do compile_uvvm.do
#
# Prerequisite (one-time UVVM setup, already done):
#   compile uvvm_util, uvvm_vvc_framework, bitvis_vip_scoreboard,
#   bitvis_vip_axilite, bitvis_vip_uart  (see UVVM docs / supervisor's notes).
################################################################################

# ---- Defensive cleanup of stale Tcl procs from previous runs --------------
catch {rename compile  ""}
catch {rename sim      ""}
catch {rename cmp      ""}
catch {rename simulate ""}
catch {rename make_lib ""}

# ---- Paths ----------------------------------------------------------------
set SRC_DIR   "/home/intern/uart_omer/rtl"
set TB_DIR    "/home/intern/uart_omer/tb"
set UVVM_DIR  "/home/intern/UVVM"

set WORK      uart_lib
set VHDL_STD  "-2008"
set TB_TOP    tb_uart_axi_lite_uvvm

# ---- Recreate a clean work library ----------------------------------------
if {[file isdirectory $WORK]} { vdel -all -lib $WORK }
vlib $WORK
vmap $WORK $WORK

# ---- Map the pre-compiled UVVM libraries ----------------------------------
echo "==== Mapping UVVM libraries ===="
vmap uvvm_util             $UVVM_DIR/uvvm_util/sim/uvvm_util
vmap uvvm_vvc_framework    $UVVM_DIR/uvvm_vvc_framework/sim/uvvm_vvc_framework
vmap bitvis_vip_scoreboard $UVVM_DIR/bitvis_vip_scoreboard/sim/bitvis_vip_scoreboard
vmap bitvis_vip_axilite    $UVVM_DIR/bitvis_vip_axilite/sim/bitvis_vip_axilite
vmap bitvis_vip_uart       $UVVM_DIR/bitvis_vip_uart/sim/bitvis_vip_uart

# ---- Compile RTL (order matters: leaf modules first, then top, then AXI) --
echo "==== Compiling RTL ===="
vcom $VHDL_STD -work $WORK $SRC_DIR/uart_pkg.vhd
vcom $VHDL_STD -work $WORK $SRC_DIR/uart_fifo.vhd
vcom $VHDL_STD -work $WORK $SRC_DIR/uart_tx.vhd
vcom $VHDL_STD -work $WORK $SRC_DIR/uart_rx.vhd
vcom $VHDL_STD -work $WORK $SRC_DIR/baudrategen.vhd
vcom $VHDL_STD -work $WORK $SRC_DIR/uart_top.vhd
vcom $VHDL_STD -work $WORK $SRC_DIR/uart_axi_lite.vhd

# ---- Compile testbench ----------------------------------------------------
echo "==== Compiling testbench ===="
vcom $VHDL_STD -work $WORK $TB_DIR/tb_uart_axi_lite_uvvm.vhd

# ---- Launch the simulator -------------------------------------------------
echo "==== Launching simulator ===="
vsim -voptargs=+acc -t ps -lib $WORK $WORK.$TB_TOP

run -all