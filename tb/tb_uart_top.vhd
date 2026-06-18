library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_uart_top is
end entity tb_uart_top;

architecture rtl of tb_uart_top is

  constant CLK_FREQ   : integer := 100000000;
  constant CLK_PERIOD : time    := 1 sec / CLK_FREQ;

  signal clk         : std_logic := '0';
  signal rst_n       : std_logic := '0';
  signal baud_sel    : std_logic_vector(3 downto 0) := (others => '0');
  signal rx          : std_logic := '1';
  signal tx          : std_logic := '0';
  signal tx_write    : std_logic := '0';
  signal tx_byte_in  : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_full     : std_logic := '0';
  signal rx_read     : std_logic := '0';
  signal rx_byte_out : std_logic_vector(7 downto 0) := (others => '0');
  signal rx_empty    : std_logic := '0';
  signal tx_done     : std_logic := '0';
  signal rx_valid    : std_logic := '0';

begin

  uart_top_inst : entity work.uart_top
    generic map (
      CLK_FREQ => CLK_FREQ
    )
    port map (
      clk         => clk,
      rst_n       => rst_n,
      baud_sel    => baud_sel,
      rx          => rx,
      tx          => tx,
      tx_write    => tx_write,
      tx_byte_in  => tx_byte_in,
      tx_full     => tx_full,
      rx_read     => rx_read,
      rx_byte_out => rx_byte_out,
      rx_empty    => rx_empty,
      tx_done     => tx_done,
      rx_valid    => rx_valid
    );


  rx <= tx;


  P_CLK_GEN : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    

    loop
      clk <= not clk;
      wait for CLK_PERIOD / 2;
    end loop;
  end process P_CLK_GEN;

  P_RSTN_GEN : process
  begin
    rst_n <= '0';
    wait for 10 * 100 ns;     -- 1 us
    rst_n <= '1';
    wait;
  end process P_RSTN_GEN;

  P_TX_RX_DATA_GEN : process
    constant DATA : std_logic_vector(7 downto 0) := x"A5";
  begin
    wait until rst_n = '1';
    wait until rising_edge(clk);

    baud_sel <= "1111";
    wait for 5 * CLK_PERIOD;

    report "TB: writing 0xA5 into TX FIFO";
    tx_byte_in <= DATA;
    tx_write   <= '1';
    wait until rising_edge(clk);
    tx_write   <= '0';


    wait until rx_valid = '1';
    report "receiver reported rx_valid";
 
    wait until rising_edge(clk);
    rx_read <= '1';
    wait until rising_edge(clk);
    rx_read <= '0';

    if rx_byte_out = DATA then
      report "TB: PASS - received 0xA5" severity note;
    else
      report "TB: FAIL - received " & to_hstring(rx_byte_out) severity error;
    end if;

    wait for 2 us;
    report "TB: end of test" severity note;
    wait;

  end process P_TX_RX_DATA_GEN;

end architecture;