library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_top is
    generic (
        CLK_FREQ : integer := 100_000_000
    );
    port (
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        baud_sel    : in  std_logic_vector(3 downto 0);
        rx          : in  std_logic;
        tx          : out std_logic;

        tx_write    : in  std_logic;                       -- 1-clk pulse to push
        tx_byte_in  : in  std_logic_vector(7 downto 0);
        tx_full     : out std_logic;                       -- TX FIFO is full

        -- host-side RX interface (pop received bytes)
        rx_read     : in  std_logic;                       -- 1-clk pulse to pop
        rx_byte_out : out std_logic_vector(7 downto 0);
        rx_empty    : out std_logic;                       -- RX FIFO is empty

        -- optional status pulses (useful for IRQ later)
        tx_done     : out std_logic;
        rx_valid    : out std_logic
    );
end entity uart_top;

architecture behavioral of uart_top is

    -- 2-FF synchronizer on the external rx pin
    signal rx_sync1, rx_sync2 : std_logic := '1';

    -- baud_gen ↔ engines
    signal rx_tick    : std_logic;
    signal tx_tick    : std_logic;
    signal rx_enable  : std_logic;
    signal tx_enable  : std_logic;

    -- TX FIFO ↔ TX engine
    signal tx_fifo_full      : std_logic;
    signal tx_fifo_empty     : std_logic;
    signal tx_fifo_pop       : std_logic;
    signal tx_byte_to_engine : std_logic_vector(7 downto 0);
    signal tx_dv             : std_logic;
    signal tx_active         : std_logic;
    signal tx_serial         : std_logic;
    signal tx_done_int       : std_logic;

    -- RX engine ↔ RX FIFO
    signal rx_data_int  : std_logic_vector(7 downto 0);
    signal rx_valid_int : std_logic;
    signal rx_fifo_full : std_logic;

begin

    -- ====================================================================
    -- 2-FF synchronizer for the asynchronous rx input
    -- ====================================================================
    sync_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            rx_sync1 <= '1';
            rx_sync2 <= '1';
        elsif rising_edge(clk) then
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end if;
    end process sync_proc;

    -- ====================================================================
    -- TX FIFO → TX engine glue
    -- Pop the FIFO when it has a byte AND the TX engine is idle.
    -- The same pulse acts as tx_dv to start a frame.
    -- ====================================================================
    tx_fifo_pop <= '1' when (tx_fifo_empty = '0' and tx_active = '0') else '0';
    tx_dv       <= tx_fifo_pop;

    -- ====================================================================
    -- Output assignments
    -- ====================================================================
    tx       <= tx_serial;
    tx_full  <= tx_fifo_full;
    tx_done  <= tx_done_int;
    rx_valid <= rx_valid_int;

    -- ====================================================================
    -- Module instantiations
    -- ====================================================================

    u_baud_gen : entity work.baud_rate_gen
        generic map (
            CLK_FREQ => CLK_FREQ
        )
        port map (
            clk       => clk,
            rst_n     => rst_n,
            rx_enable => rx_enable,
            tx_enable => tx_enable,
            baud_sel  => baud_sel,
            rx_tick   => rx_tick,
            tx_tick   => tx_tick
        );

    u_tx_fifo : entity work.uart_fifo
        generic map (
            WIDTH => 8,
            DEPTH => 16
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            wr_en   => tx_write,
            wr_data => tx_byte_in,
            full    => tx_fifo_full,
            rd_en   => tx_fifo_pop,
            rd_data => tx_byte_to_engine,
            empty   => tx_fifo_empty
        );

    u_tx : entity work.uart_tx
        port map (
            clk       => clk,
            rst_n     => rst_n,
            tx_tick   => tx_tick,
            tx_dv     => tx_dv,
            tx_data   => tx_byte_to_engine,
            tx_enable => tx_enable,
            tx_active => tx_active,
            tx_serial => tx_serial,
            tx_done   => tx_done_int
        );

    u_rx : entity work.uart_rx
        port map (
            clk       => clk,
            rst_n     => rst_n,
            rx        => rx_sync2,                -- synchronized input
            rx_tick   => rx_tick,
            rx_data   => rx_data_int,
            rx_valid  => rx_valid_int,
            rx_enable => rx_enable
        );

    u_rx_fifo : entity work.uart_fifo
        generic map (
            WIDTH => 8,
            DEPTH => 16
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            wr_en   => rx_valid_int,
            wr_data => rx_data_int,
            full    => rx_fifo_full,
            rd_en   => rx_read,
            rd_data => rx_byte_out,
            empty   => rx_empty                   -- direct connection now
        );

end architecture behavioral;