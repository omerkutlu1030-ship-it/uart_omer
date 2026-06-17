library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity uart_rx is
    port (
        clk : in  std_logic;
        rst_n : in  std_logic;
        rx : in  std_logic;
        rx_tick : in  std_logic;
        rx_data  : out std_logic_vector(7 downto 0);
        rx_valid: out std_logic;
        rx_enable : out std_logic
    );
end entity uart_rx;

architecture behavioral of uart_rx is

    type current_state is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : current_state := IDLE;
    signal bit_count : integer range 0 to 7  := 0;
    signal tick_count : integer range 0 to 15 := 0;
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_valid_int : std_logic := '0';

begin

    rx_valid <= rx_valid_int;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            bit_count <= 0;
            tick_count <= 0;
            shift_reg <= (others => '0');
            rx_valid_int <= '0';
            rx_enable <= '0';

        elsif rising_edge(clk) then
            rx_valid_int <= '0';
            rx_enable <= '0';

            case state is

                when IDLE =>
                    tick_count <= 0;
                    if rx = '0' then
                        state <= START_BIT;
                        rx_enable <= '1';
                    end if;

                when START_BIT =>
                    if rx_tick = '1' then
                        if tick_count = 7 then
                            if rx = '0' then
                                state <= DATA_BITS;
                                tick_count <= 0;
                                bit_count <= 0;
                            else
                                state <= IDLE;
                                tick_count <= 0;
                            end if;
                        else
                            tick_count <= tick_count + 1;
                        end if;
                    end if;

                when DATA_BITS =>
                    if rx_tick = '1' then
                        if tick_count = 15 then
                            tick_count           <= 0;
                            shift_reg(bit_count) <= rx;
                            if bit_count = 7 then
                                state <= STOP_BIT;
                            else
                                bit_count <= bit_count + 1;
                            end if;
                        else
                            tick_count <= tick_count + 1;
                        end if;
                    end if;

                when STOP_BIT =>
                    if rx_tick = '1' then
                        if tick_count = 15 then
                            if rx = '1' then
                                rx_valid_int <= '1';
                                rx_data      <= shift_reg;
                            end if;
                            state      <= IDLE;
                            tick_count <= 0;
                        else
                            tick_count <= tick_count + 1;
                        end if;
                    end if;

            end case;
        end if;
    end process;

end architecture behavioral;