library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity uart_tx is
    port (
        clk : in  std_logic;
        reset : in  std_logic;
        baud_tick : in  std_logic;
        tx_dv     : in  std_logic;
        tx_data   : in  std_logic_vector(7 downto 0);
        tx_active : out std_logic;
        tx_serial : out std_logic;
        tx_done   : out std_logic
    );
end entity uart_tx;

architecture behavioral of uart_tx is

    type tx_state_t is (idle, start_bit, data_bits, stop_bit, cleanup);
    signal state       : tx_state_t := idle;
    signal bit_index   : integer range 0 to 7 := 0;
    signal shift_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_done_int : std_logic := '0';
    signal tick_count  : integer range 0 to 15 := 0;

begin
    tx_done <= tx_done_int;

    process(clk, reset)
    begin
        if reset = '1' then
            state <= idle;
            bit_index <= 0;
            tick_count <= 0;
            shift_reg <= (others => '0');
            tx_done_int <= '0';
            tx_active <= '0';
            tx_serial <= '1';
        elsif rising_edge(clk) then
            if baud_tick = '1' then
                case state is
                    when idle =>
                        tx_active <= '0';
                        tx_serial <= '1';
                        tx_done_int <= '0';
                        tick_count <= 0;
                        bit_index <= 0;
                        if tx_dv = '1' then
                            shift_reg <= tx_data;
                            state <= start_bit;
                        end if;

                    when start_bit =>
                        tx_active <= '1';
                        tx_serial <= '0';
                        if tick_count = 15 then
                            tick_count <= 0;
                            state <= data_bits;
                        else
                            tick_count <= tick_count + 1;
                        end if;

                    when data_bits =>
                        tx_active <= '1';
                        tx_serial <= shift_reg(bit_index);
                        if tick_count = 15 then
                            tick_count <= 0;
                            if bit_index = 7 then
                                bit_index <= 0;
                                state <= stop_bit;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            tick_count <= tick_count + 1;
                        end if;

                    when stop_bit =>
                        tx_active <= '1';
                        tx_serial <= '1';
                        if tick_count = 15 then
                            tick_count <= 0;
                            tx_done_int <= '1';
                            state <= cleanup;
                        else
                            tick_count <= tick_count + 1;
                        end if;

                    when cleanup =>
                        tx_active   <= '0';
                        tx_serial   <= '1';
                        tx_done_int <= '1';
                        state <= idle;

                    when others =>
                        state <= idle;
                end case;
            end if;
        end if;
    end process;

end architecture behavioral;
            