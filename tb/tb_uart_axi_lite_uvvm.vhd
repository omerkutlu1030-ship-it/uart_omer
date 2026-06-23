library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_axilite;
use bitvis_vip_axilite.axilite_bfm_pkg.all;

library uart_lib;
use uart_lib.all;

entity tb_uart_axi_lite_uvvm is
end entity;

architecture sim of tb_uart_axi_lite_uvvm is

  constant CLK_PERIOD : time := 10 ns;


  -- All AXI-Lite signals bundled into the UVVM record type
  signal axilite_if : t_axilite_if(
    write_address_channel(awaddr(7 downto 0)),
    write_data_channel(wdata(31 downto 0), wstrb(3 downto 0)),
    read_address_channel(araddr(7 downto 0)),
    read_data_channel(rdata(31 downto 0))
  );

  signal aclk    : std_logic := '0';
  signal aresetn : std_logic := '0';
  signal rx, tx  : std_logic := '1';

  -- Intermediate signals bridging axilite_if <-> DUT ports
  signal s_axi_awaddr  : std_logic_vector(7 downto 0) := (others => '0');
  signal s_axi_awvalid : std_logic := '0';
  signal s_axi_awready : std_logic := '0';
  signal s_axi_wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal s_axi_wstrb   : std_logic_vector(3 downto 0) := (others => '0');
  signal s_axi_wvalid  : std_logic := '0';
  signal s_axi_wready  : std_logic := '0';
  signal s_axi_bready  : std_logic := '0';
  signal s_axi_bresp   : std_logic_vector(1 downto 0) := (others => '0');
  signal s_axi_bvalid  : std_logic := '0';
  signal s_axi_araddr  : std_logic_vector(7 downto 0) := (others => '0');
  signal s_axi_arvalid : std_logic := '0';
  signal s_axi_arready : std_logic := '0';
  signal s_axi_rready  : std_logic := '0';
  signal s_axi_rdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal s_axi_rresp   : std_logic_vector(1 downto 0);
  signal s_axi_rvalid  : std_logic := '0';

begin
s_axi_awaddr <= axilite_if.write_address_channel.awaddr(7 downto 0);
s_axi_awvalid <= axilite_if.write_address_channel.awvalid;
axilite_if.write_address_channel.awready <= s_axi_awready;
s_axi_wdata <= axilite_if.write_data_channel.wdata(31 downto 0);
s_axi_wstrb <= axilite_if.write_data_channel.wstrb(3 downto 0);
s_axi_wvalid <= axilite_if.write_data_channel.wvalid;
axilite_if.write_data_channel.wready <= s_axi_wready;
s_axi_bready <= axilite_if.write_response_channel.bready;
axilite_if.write_response_channel.bresp <= s_axi_bresp;
axilite_if.write_response_channel.bvalid <= s_axi_bvalid;
s_axi_araddr <= axilite_if.read_address_channel.araddr(7 downto 0);
s_axi_arvalid <= axilite_if.read_address_channel.arvalid;
axilite_if.read_address_channel.arready <= s_axi_arready;
s_axi_rready <= axilite_if.read_data_channel.rready;
axilite_if.read_data_channel.rdata <= s_axi_rdata(31 downto 0);
axilite_if.read_data_channel.rresp <= s_axi_rresp;
axilite_if.read_data_channel.rvalid <= s_axi_rvalid;
  -- ------------------------------------------------------------------
  -- DUT
  -- ------------------------------------------------------------------
  dut : entity uart_lib.uart_axi_lite
    port map (
      s_axi_aclk    => aclk,
      s_axi_aresetn => aresetn,

      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,

      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,

      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,

      s_axi_araddr  => s_axi_araddr,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,

      s_axi_rdata   => s_axi_rdata,
      s_axi_rresp   => s_axi_rresp,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready,

      rx => rx,
      tx => tx
    );

  rx      <= tx;
  aclk    <= not aclk after CLK_PERIOD / 2;
  aresetn <= '0', '1' after 1 us;

  -- ------------------------------------------------------------------
  -- Main test sequencer
  -- ------------------------------------------------------------------
  p_main : process
  begin
    log(ID_LOG_HDR, "Smoke test: UVVM + AXI-Lite + UART");

    wait until aresetn = '1';
    wait for 100 ns;

    log(ID_LOG_HDR, "Write 0x0000000F to CTRL");
    axilite_write(x"00", x"0000000F",
                  "write CTRL = baud_sel 1111",
                  aclk, axilite_if);

    log(ID_LOG_HDR, "Read CTRL back and check");
    axilite_check(x"00", x"0000000F",
                  "CTRL must read back as written",
                  aclk, axilite_if);

    report_alert_counters(FINAL);
    log(ID_LOG_HDR, "Test complete");
    std.env.stop;
  end process p_main;

end architecture;