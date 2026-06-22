
catch {rename compile ""}
catch {rename sim     ""}
catch {rename rerun   ""}
catch {rename cmp        ""}
catch {rename simulate   ""}
catch {rename rerun_all  ""}
catch {rename make_lib   ""}
catch {rename add_waves  ""}

set SRC_DIR  "/home/intern/uart_omer/rtl"
set TB_DIR   "/home/intern/uart_omer/tb"
set WORK     work
set VHDL_STD "-2008"
set TB_TOP   tb_uart_axi_lite

proc make_lib {} {
    global WORK
    if {[file isdirectory $WORK]} { vdel -all -lib $WORK }
    vlib $WORK
    vmap $WORK $WORK
}

proc cmp {} {
    global SRC_DIR TB_DIR WORK VHDL_STD

    echo "==== Compiling package ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_pkg.vhd

    echo "==== Compiling leaf entities ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_fifo.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_tx.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_rx.vhd

    echo "==== Compiling baud rate generator ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/baudrategen.vhd

    echo "==== Compiling uart_top ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_top.vhd

    echo "==== Compiling AXI-Lite wrapper ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_axi_lite.vhd

    echo "==== Compiling AXI testbench ===="
    vcom $VHDL_STD -work $WORK $TB_DIR/tb_uart_axi_lite.vhd

    echo "==== Compile finished OK ===="
}

proc simulate {} {
    global WORK TB_TOP
    vsim -voptargs=+acc -t ps -lib $WORK $WORK.$TB_TOP
    add_waves
}

proc add_waves {} {
    if {[catch {delete wave *} err]} {}

    add wave -divider "Clock / Reset"
    add wave /tb_uart_axi_lite/aclk
    add wave /tb_uart_axi_lite/aresetn

    add wave -divider "AW channel"
    add wave -radix hex /tb_uart_axi_lite/awaddr
    add wave /tb_uart_axi_lite/awvalid
    add wave /tb_uart_axi_lite/awready

    add wave -divider "W channel"
    add wave -radix hex /tb_uart_axi_lite/wdata
    add wave /tb_uart_axi_lite/wstrb
    add wave /tb_uart_axi_lite/wvalid
    add wave /tb_uart_axi_lite/wready

    add wave -divider "B channel"
    add wave /tb_uart_axi_lite/bresp
    add wave /tb_uart_axi_lite/bvalid
    add wave /tb_uart_axi_lite/bready

    add wave -divider "AR channel"
    add wave -radix hex /tb_uart_axi_lite/araddr
    add wave /tb_uart_axi_lite/arvalid
    add wave /tb_uart_axi_lite/arready

    add wave -divider "R channel"
    add wave -radix hex /tb_uart_axi_lite/rdata
    add wave /tb_uart_axi_lite/rresp
    add wave /tb_uart_axi_lite/rvalid
    add wave /tb_uart_axi_lite/rready

    add wave -divider "DUT internal"
    add wave /tb_uart_axi_lite/dut/w_state
    add wave /tb_uart_axi_lite/dut/r_state
    add wave -radix hex /tb_uart_axi_lite/dut/reg_ctrl
    add wave /tb_uart_axi_lite/dut/core_tx_write
    add wave -radix hex /tb_uart_axi_lite/dut/core_tx_byte_in
    add wave /tb_uart_axi_lite/dut/core_rx_read
    add wave -radix hex /tb_uart_axi_lite/dut/core_rx_byte_out

    add wave -divider "UART pins"
    add wave /tb_uart_axi_lite/tx
    add wave /tb_uart_axi_lite/rx
}

proc rerun_all {} {
    restart -force
    run -all
}

make_lib
cmp
simulate
run 20 us
wave zoom full