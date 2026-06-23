################################################################################
# compile_axi_uvvm.do
#
# Compile the UART + AXI-Lite wrapper, map to the pre-compiled UVVM libraries,
# and run the UVVM-based testbench.
#
# Prerequisite: UVVM must already be compiled. Run these ONCE:
#   cd ~/UVVM/uvvm_util/script;             do compile_src.do
#   cd ~/UVVM/bitvis_vip_scoreboard/script; do compile_src.do
#   cd ~/UVVM/bitvis_vip_axilite/script;    do compile_src.do
################################################################################

catch {rename compile  ""}
catch {rename sim      ""}
catch {rename rerun    ""}
catch {rename cmp      ""}
catch {rename simulate ""}
catch {rename rerun_all ""}
catch {rename make_lib ""}
catch {rename add_waves ""}

# ---- Project paths ----
set SRC_DIR  "/home/intern/uart_omer/rtl"
set TB_DIR   "/home/intern/uart_omer/tb"
set WORK     work
set VHDL_STD "-2008"
set TB_TOP   tb_uart_axi_lite_uvvm

# ---- UVVM install path ----
set UVVM_DIR "/home/intern/UVVM"

proc make_lib {} {
    global WORK
    if {[file isdirectory $WORK]} { vdel -all -lib $WORK }
    vlib $WORK
    vmap $WORK $WORK
}

# Map to the pre-compiled UVVM libraries so the testbench can see them
proc map_uvvm {} {
    global UVVM_DIR
    vmap uvvm_util              $UVVM_DIR/uvvm_util/sim/uvvm_util
    vmap bitvis_vip_scoreboard  $UVVM_DIR/bitvis_vip_scoreboard/sim/bitvis_vip_scoreboard
    vmap bitvis_vip_axilite     $UVVM_DIR/bitvis_vip_axilite/sim/bitvis_vip_axilite
}

proc cmp {} {
    global SRC_DIR TB_DIR WORK VHDL_STD

    echo "==== Compiling RTL ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_pkg.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_fifo.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_tx.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_rx.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/baudrategen.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_top.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_axi_lite.vhd

    echo "==== Compiling UVVM testbench ===="
    vcom $VHDL_STD -work $WORK $TB_DIR/tb_uart_axi_lite_uvvm.vhd

    echo "==== Compile finished OK ===="
}

proc simulate {} {
    global WORK TB_TOP
    vsim -voptargs=+acc -t ps -lib $WORK $uart_lib.$TB_TOP
}

make_lib
map_uvvm
cmp
simulate
run -all
