library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    port (
        clk : in  std_logic;
        reset : in  std_logic;
        tx_tick : in  std_logic;
        tx_dv : in  std_logic;
        tx_data : in  std_logic_vector(7 downto 0);
        tx_enable : out std_logic;
        tx_active : out std_logic;
        tx_serial : out std_logic;
        tx_done : out std_logic
    );
end entity uart_tx;

architecture behavioral of uart_tx is

    type current_state is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : current_state := IDLE;
    signal bit_index : integer range 0 to 7  := 0;
    signal tick_count : integer range 0 to 15 := 0;
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_done_int : std_logic := '0';

begin

    tx_done <= tx_done_int; 

    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            bit_index <= 0;
            tick_count <= 0;
            shift_reg <= (others => '0');
            tx_done_int <= '0';
            tx_enable <= '0';
            tx_active <= '0';
            tx_serial <= '1';

        elsif rising_edge(clk) then
            tx_done_int <= '0';
            tx_enable <= '0';

            case state is

                when IDLE =>
                    tx_active <= '0';
                    tx_serial <= '1';
                    if tx_dv = '1' then
                        shift_reg <= tx_data;
                        state <= START_BIT;
                        tx_enable <= '1';
                        tx_active <= '1';
                        tick_count <= 0;
                        bit_index <= 0;
                    end if;

                when START_BIT =>
                    tx_active <= '1';
                    tx_serial <= '0';
                    if tx_tick = '1' then
                        if tick_count = 15 then
                            tick_count <= 0;
                            state <= DATA_BITS;
                        else
                            tick_count <= tick_count + 1;
                        end if;
                    end if;

                when DATA_BITS =>
                    tx_active <= '1';
                    tx_serial <= shift_reg(bit_index);
                    if tx_tick = '1' then
                        if tick_count = 15 then
                            tick_count <= 0;
                            if bit_index = 7 then
                                state <= STOP_BIT;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            tick_count <= tick_count + 1;
                        end if;
                    end if;

                when STOP_BIT =>
                    tx_active <= '1';
                    tx_serial <= '1';
                    if tx_tick = '1' then
                        if tick_count = 15 then
                            tick_count  <= 0;
                            tx_done_int <= '1';
                            state <= IDLE;
                        else
                            tick_count <= tick_count + 1;
                        end if;
                    end if;

            end case;
        end if;
    end process;

end architecture behavioral;