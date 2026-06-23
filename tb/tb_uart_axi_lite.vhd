library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_axi_lite is
end entity;

architecture rtl of tb_uart_axi_lite is
  constant CLK_PERIOD : time := 10 ns;

  signal aclk    : std_logic := '0';
  signal aresetn : std_logic := '0';

  signal awaddr  : std_logic_vector(7 downto 0)  := (others => '0');
  signal awvalid : std_logic := '0';
  signal awready : std_logic;
  signal wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal wstrb   : std_logic_vector(3 downto 0)  := "1111";
  signal wvalid  : std_logic := '0';
  signal wready  : std_logic;
  signal bresp   : std_logic_vector(1 downto 0);
  signal bvalid  : std_logic;
  signal bready  : std_logic := '0';

  signal araddr  : std_logic_vector(7 downto 0)  := (others => '0');
  signal arvalid : std_logic := '0';
  signal arready : std_logic;
  signal rdata   : std_logic_vector(31 downto 0);
  signal rresp   : std_logic_vector(1 downto 0);
  signal rvalid  : std_logic;
  signal rready  : std_logic := '0';

  signal rx, tx : std_logic := '1';

begin

  dut : entity uart_lib.uart_axi_lite
    port map (
      s_axi_aclk    => aclk,
      s_axi_aresetn => aresetn,
      s_axi_awaddr  => awaddr,
      s_axi_awvalid => awvalid,
      s_axi_awready => awready,
      s_axi_wdata   => wdata,
      s_axi_wstrb   => wstrb,
      s_axi_wvalid  => wvalid,
      s_axi_wready  => wready,
      s_axi_bresp   => bresp,
      s_axi_bvalid  => bvalid,
      s_axi_bready  => bready,
      s_axi_araddr  => araddr,
      s_axi_arvalid => arvalid,
      s_axi_arready => arready,
      s_axi_rdata   => rdata,
      s_axi_rresp   => rresp,
      s_axi_rvalid  => rvalid,
      s_axi_rready  => rready,
      rx => rx,
      tx => tx
    );

  rx <= tx;

  aclk    <= not aclk after CLK_PERIOD / 2;   -- clock
  



  p_reset : process
  begin
    aresetn <= '0';
    wait for 40 ns;
    aresetn <= '1';
    wait;
  end process;

  stim : process
  begin
    wait until aresetn = '1';
    wait until rising_edge(aclk);

    awaddr  <= x"00";
    awvalid <= '1';
    wdata   <= x"0000000F";
    wvalid <= '1';
    wait until rising_edge(aclk) and awready = '1' and wready = '1';
    
    awvalid <= '0'; 
    wvalid <= '0';
    bready <= '1';
    
    wait until rising_edge(aclk) and bvalid = '1';
    bready <= '0';
    araddr <= x"00";  arvalid <= '1';
    wait until rising_edge(aclk) and arready = '1';
    arvalid <= '0';
    rready <= '1';
    wait until rising_edge(aclk) and rvalid = '1';
    report "Read back: 0x" & to_hstring(rdata);
    rready <= '0';
    
    awaddr  <= x"08";  awvalid <= '1';
    wdata   <= x"00000041"; wvalid <= '1';
    wait until rising_edge(aclk) and awready = '1' and wready = '1';
    awvalid <= '0';  wvalid <= '0';
    bready  <= '1';
    wait until rising_edge(aclk) and bvalid = '1';
    bready  <= '0';
    
    wait for 200 ns;
    wait;
  end process;

end architecture;