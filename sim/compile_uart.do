################################################################################
# compile_uart.do
#
# ModelSim / QuestaSim compile + simulate script for the UART IP.
#
# Usage from the ModelSim/QuestaSim console (in the directory that contains
# this file and the .vhd sources):
#
#     do compile_uart.do          ;# full clean build + launch sim + run
#     cmp                         ;# recompile only
#     simulate                    ;# (re)launch the simulator
#     rerun_all                   ;# restart and run again
#
################################################################################

# ------------------------------------------------------------------------------
# 0. Project paths
# ------------------------------------------------------------------------------
# SRC_DIR : where the RTL .vhd files live
# TB_DIR  : where the testbench lives (same dir in your case)
# WORK    : name of the working library
set SRC_DIR  "/home/intern/uart_omer/rtl"
set TB_DIR   "/home/intern/uart_omer/tb"
set WORK     work

# VHDL standard. The package uses to_string / std_logic_textio, so we need 2008.
set VHDL_STD "-2008"

# Top-level testbench entity (used by vsim)
set TB_TOP   tb_uart_top

# ------------------------------------------------------------------------------
# 1. (Re)create the work library
# ------------------------------------------------------------------------------
proc make_lib {} {
    global WORK
    # If the lib already exists, wipe it for a clean build
    if {[file isdirectory $WORK]} {
        vdel -all -lib $WORK
    }
    vlib  $WORK
    vmap  $WORK $WORK
}

# ------------------------------------------------------------------------------
# 2. Compile sources in dependency order
# ------------------------------------------------------------------------------
#   uart_pkg          -> needed by baudrategen
#   uart_fifo/tx/rx   -> leaf entities, no work-lib deps
#   baudrategen       -> uses uart_pkg
#   uart_top          -> uses all sub-blocks
#   tb_uart_top       -> uses uart_top
# ------------------------------------------------------------------------------
proc cmp {} {
    global SRC_DIR TB_DIR WORK VHDL_STD

    echo "==== Compiling package ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_pkg.vhd

    echo "==== Compiling leaf entities ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_fifo.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_tx.vhd
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_rx.vhd

    echo "==== Compiling baud rate generator (depends on uart_pkg) ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/baudrategen.vhd

    echo "==== Compiling top level ===="
    vcom $VHDL_STD -work $WORK $SRC_DIR/uart_top.vhd

    echo "==== Compiling testbench ===="
    vcom $VHDL_STD -work $WORK $TB_DIR/tb_uart_top.vhd

    echo "==== Compile finished OK ===="
}

# ------------------------------------------------------------------------------
# 3. Launch the simulator
# ------------------------------------------------------------------------------
proc simulate {} {
    global WORK TB_TOP
    # -voptargs=+acc keeps signals visible for waveform debugging
    vsim -voptargs=+acc -t ps -lib $WORK $WORK.$TB_TOP
    add_waves
    configure wave -namecolwidth  220
    configure wave -valuecolwidth 100
    configure wave -timelineunits ns
}

# ------------------------------------------------------------------------------
# 4. Waveform setup
# ------------------------------------------------------------------------------
proc add_waves {} {
    # Clean any leftover wave panes
    if {[catch {delete wave *} err]} {}

    # ----- Top-level interface -----
    add wave -divider "TB / Top-level I/O"
    add wave -radix binary  /tb_uart_top/clk
    add wave -radix binary  /tb_uart_top/rst_n
    add wave -radix binary  /tb_uart_top/baud_sel
    add wave -radix binary  /tb_uart_top/rx
    add wave -radix binary  /tb_uart_top/tx
    add wave -radix binary  /tb_uart_top/tx_write
    add wave -radix hex     /tb_uart_top/tx_byte_in
    add wave -radix binary  /tb_uart_top/tx_full
    add wave -radix binary  /tb_uart_top/rx_read
    add wave -radix hex     /tb_uart_top/rx_byte_out
    add wave -radix binary  /tb_uart_top/rx_empty
    add wave -radix binary  /tb_uart_top/tx_done
    add wave -radix binary  /tb_uart_top/rx_valid

    # ----- Baud rate generator -----
    add wave -divider "Baud rate generator"
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_baud_gen/max_count
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_baud_gen/rx_counter
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_baud_gen/tx_counter
    add wave -radix binary   /tb_uart_top/uart_top_inst/u_baud_gen/rx_tick
    add wave -radix binary   /tb_uart_top/uart_top_inst/u_baud_gen/tx_tick

    # ----- TX engine -----
    add wave -divider "TX engine"
    add wave                /tb_uart_top/uart_top_inst/u_tx/state
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_tx/bit_index
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_tx/tick_count
    add wave -radix hex     /tb_uart_top/uart_top_inst/u_tx/shift_reg
    add wave -radix binary  /tb_uart_top/uart_top_inst/u_tx/tx_serial
    add wave -radix binary  /tb_uart_top/uart_top_inst/u_tx/tx_active
    add wave -radix binary  /tb_uart_top/uart_top_inst/u_tx/tx_done_int

    # ----- RX engine -----
    add wave -divider "RX engine"
    add wave                /tb_uart_top/uart_top_inst/u_rx/state
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_rx/bit_count
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_rx/tick_count
    add wave -radix hex     /tb_uart_top/uart_top_inst/u_rx/shift_reg
    add wave -radix binary  /tb_uart_top/uart_top_inst/u_rx/rx_valid_int

    # ----- TX FIFO -----
    add wave -divider "TX FIFO"
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_tx_fifo/level
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_tx_fifo/wr_ptr
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_tx_fifo/rd_ptr
    add wave -radix binary   /tb_uart_top/uart_top_inst/u_tx_fifo/full_int
    add wave -radix binary   /tb_uart_top/uart_top_inst/u_tx_fifo/empty_int

    # ----- RX FIFO -----
    add wave -divider "RX FIFO"
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_rx_fifo/level
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_rx_fifo/wr_ptr
    add wave -radix unsigned /tb_uart_top/uart_top_inst/u_rx_fifo/rd_ptr
    add wave -radix binary   /tb_uart_top/uart_top_inst/u_rx_fifo/full_int
    add wave -radix binary   /tb_uart_top/uart_top_inst/u_rx_fifo/empty_int
}

# ------------------------------------------------------------------------------
# 5. Convenience: rebuild + relaunch
# ------------------------------------------------------------------------------
proc rerun_all {} {
    restart -force
    run -all
}

# ------------------------------------------------------------------------------
# 6. Default flow when the script is invoked with `do compile_uart.do`
# ------------------------------------------------------------------------------
make_lib
cmp
simulate

# Initial run length. The testbench has no end condition, so we run a
# bounded amount of time. Bump this up when you start driving stimulus.
run 80 us

# Zoom the waveform to fit the whole run
wave zoom full