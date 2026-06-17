library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_rate_gen is
    generic (
        CLK_FREQ : integer := 100000000
    );
    port (
        clk : in  std_logic;
        rst_n : in  std_logic;
        rx_enable : in  std_logic;
        tx_enable : in  std_logic;
        baud_sel : in  std_logic_vector(3 downto 0);
        rx_tick : out std_logic;
        tx_tick : out std_logic
    );
end entity baud_rate_gen;

architecture rtl of baud_rate_gen is

    constant OVERSAMPLE : integer := 16;

    constant Divisor_9600 : integer := CLK_FREQ / (9600 * OVERSAMPLE);
    constant Divisor_19200 : integer := CLK_FREQ / (19200 * OVERSAMPLE);
    constant Divisor_38400 : integer := CLK_FREQ / (38400 * OVERSAMPLE);
    constant Divisor_57600 : integer := CLK_FREQ / (57600 * OVERSAMPLE);
    constant Divisor_115200 : integer := CLK_FREQ / (115200 * OVERSAMPLE);
    constant Divisor_230400 : integer := CLK_FREQ / (230400 * OVERSAMPLE);
    constant Divisor_460800 : integer := CLK_FREQ / (460800  * OVERSAMPLE);
    constant Divisor_921600 : integer := CLK_FREQ / (921600  * OVERSAMPLE);
    constant Divisor_1000000 : integer := CLK_FREQ / (1000000 * OVERSAMPLE);
    constant Divisor_1500000 : integer := CLK_FREQ / (1500000 * OVERSAMPLE);
    constant Divisor_2000000 : integer := CLK_FREQ / (2000000 * OVERSAMPLE);
    constant Divisor_2500000 : integer := CLK_FREQ / (2500000 * OVERSAMPLE);
    constant Divisor_3000000 : integer := CLK_FREQ / (3000000 * OVERSAMPLE);
    constant Divisor_3500000 : integer := CLK_FREQ / (3500000 * OVERSAMPLE);
    constant Divisor_4000000 : integer := CLK_FREQ / (4000000 * OVERSAMPLE);
    constant Divisor_5000000 : integer := CLK_FREQ / (5000000 * OVERSAMPLE);

    signal max_count  : integer := Divisor_9600;
    signal rx_counter : integer := 0;
    signal tx_counter : integer := 0;

begin

    sel_proc : process(baud_sel)
    begin
        case baud_sel is
            when "0000" => max_count <= Divisor_9600;
            when "0001" => max_count <= Divisor_19200;
            when "0010" => max_count <= Divisor_38400;
            when "0011" => max_count <= Divisor_57600;
            when "0100" => max_count <= Divisor_115200;
            when "0101" => max_count <= Divisor_230400;
            when "0110" => max_count <= Divisor_460800;
            when "0111" => max_count <= Divisor_921600;
            when "1000" => max_count <= Divisor_1000000;
            when "1001" => max_count <= Divisor_1500000;
            when "1010" => max_count <= Divisor_2000000;
            when "1011" => max_count <= Divisor_2500000;
            when "1100" => max_count <= Divisor_3000000;
            when "1101" => max_count <= Divisor_3500000;
            when "1110" => max_count <= Divisor_4000000;
            when "1111" => max_count <= Divisor_5000000;
            when others => max_count <= Divisor_9600;
        end case;
    end process sel_proc;

    rx_gen : process(clk, rst_n)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                rx_counter <= 0;
                rx_tick    <= '0';
            elsif rx_enable = '1' then
                rx_counter <= 0;
                rx_tick    <= '0';
            elsif rx_counter >= max_count - 1 then
                rx_counter <= 0;
                rx_tick    <= '1';
            else
                rx_counter <= rx_counter + 1;
                rx_tick    <= '0';
            end if;
        end if;
    end process rx_gen;

    tx_gen : process(clk, rst_n)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tx_counter <= 0;
                tx_tick    <= '0';
            elsif tx_enable = '1' then
                tx_counter <= 0;
                tx_tick    <= '0';
            elsif tx_counter >= max_count - 1 then
                tx_counter <= 0;
                tx_tick    <= '1';
            else
                tx_counter <= tx_counter + 1;
                tx_tick    <= '0';
            end if;
        end if;
    end process tx_gen;

end architecture rtl;