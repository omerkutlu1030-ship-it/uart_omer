library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;


entity tb_uart_top is
end entity tb_uart_top;

architecture rtl of tb_uart_top is

  constant CLK_FREQ   : integer := 100000000;
  constant CLK_PERIOD : time    := 1 sec / CLK_FREQ;

  signal clk         : std_logic := '0';
  signal rst_n       : std_logic := '0';
  signal baud_sel    : std_logic_vector(3 downto 0) := (others => '0');
  signal rx          : std_logic := '1';
  signal tx          : std_logic := '1';
  signal tx_write    : std_logic := '0';
  signal tx_byte_in  : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_full     : std_logic;
  signal rx_read     : std_logic := '0';
  signal rx_byte_out : std_logic_vector(7 downto 0);
  signal rx_empty    : std_logic;
  signal tx_done     : std_logic;
  signal rx_valid    : std_logic;

begin

  uart_top_inst : entity uart_lib.uart_top
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
    wait for 100 ns;
    loop
      clk <= not clk;
      wait for CLK_PERIOD / 2;
    end loop;
  end process P_CLK_GEN;



  P_Measure : process
    variable tx_count : integer := 2;
    variable tx_start_time : time;
    variable tx_end_time   : time;
  begin
    if tx_count > 0 then
      wait until rising_edge(tx);
      report "TB: tx rising edge at " & time'image(now);
      tx_start_time := now;
      wait until falling_edge(tx);
      report "TB: tx falling edge at " & time'image(now);
      tx_end_time := now;
      report "TB: measured difference = " & time'image(tx_end_time - tx_start_time);
      tx_count := 0;
    else
      wait;
    end if;
  end process P_Measure;



  P_STIM : process
    constant DATA_BYTE : std_logic_vector(7 downto 0) := x"A5";
  begin

    tx_write <= '0';
    rx_read  <= '0';
    rst_n    <= '0';
    wait for 1 us;
    rst_n    <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);

    baud_sel <= "1111";

    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    
    loop


      report "TB: driving tx_write high at " & time'image(now);
      tx_byte_in <= DATA_BYTE;
      tx_write   <= '1';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      tx_write   <= '0';
      report "TB: tx_write released at " & time'image(now);

      wait until rx_valid = '1';
      report "TB: receiver reported rx_valid at " & time'image(now);

      wait until rising_edge(clk);
      if rx_byte_out = DATA_BYTE then
        report "TB: PASS - received 0x" & to_hstring(rx_byte_out) severity note;
      else
        report "TB: FAIL - received 0x" & to_hstring(rx_byte_out)
               severity error;
      end if;

      rx_read <= '1';
      wait until rising_edge(clk);
      rx_read <= '0';

      rst_n <= '0';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      rst_n <= '1';

      baud_sel <= "1111";
      wait until rising_edge(clk);
      wait until rising_edge(clk);
    end loop;
  end process P_STIM;

end architecture;