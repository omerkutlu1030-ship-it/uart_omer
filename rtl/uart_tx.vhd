library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity uart_tx is
    port (
        clk : in  std_logic;
        reset : in  std_logic;
        tx : out std_logic;
        baud_tick : in  std_logic;
        tx_data  : in std_logic_vector(7 downto 0);
        tx_valid: in std_logic
    );