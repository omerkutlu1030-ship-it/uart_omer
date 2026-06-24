onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_aclk
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_aresetn
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_awaddr
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_awvalid
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_awready
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_wdata
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_wstrb
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_wvalid
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_wready
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_bresp
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_bvalid
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_bready
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_araddr
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_arvalid
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_arready
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_rdata
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_rresp
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_rvalid
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/s_axi_rready
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/rx
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/tx
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/reg_ctrl
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/core_tx_write
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/core_tx_byte_in
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/core_tx_full
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/core_rx_read
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/core_rx_byte_out
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/core_rx_empty
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/core_tx_done
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/core_rx_valid
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/wr_state
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/latched_awaddr
add wave -noupdate /tb_uart_axi_lite_uvvm/dut/rd_state
add wave -noupdate -expand -subitemconfig {/tb_uart_axi_lite_uvvm/axilite_if.write_address_channel -expand /tb_uart_axi_lite_uvvm/axilite_if.write_data_channel -expand /tb_uart_axi_lite_uvvm/axilite_if.write_response_channel -expand /tb_uart_axi_lite_uvvm/axilite_if.read_address_channel -expand /tb_uart_axi_lite_uvvm/axilite_if.read_data_channel -expand} /tb_uart_axi_lite_uvvm/axilite_if
add wave -noupdate /tb_uart_axi_lite_uvvm/aclk
add wave -noupdate /tb_uart_axi_lite_uvvm/aresetn
add wave -noupdate /tb_uart_axi_lite_uvvm/rx
add wave -noupdate /tb_uart_axi_lite_uvvm/tx
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_awaddr
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_awvalid
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_awready
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_wdata
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_wstrb
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_wvalid
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_wready
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_bready
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_bresp
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_bvalid
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_araddr
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_arvalid
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_arready
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_rready
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_rdata
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_rresp
add wave -noupdate /tb_uart_axi_lite_uvvm/s_axi_rvalid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10821831 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 321
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {10545040 ps} {11541728 ps}
