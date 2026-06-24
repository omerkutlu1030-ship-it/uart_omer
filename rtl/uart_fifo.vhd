library ieee;
use ieee.std_logic_1164.all;    
use ieee.numeric_std.all;

entity uart_fifo is
    generic (
        WIDTH : integer := 8;
        DEPTH : integer := 16
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        
        wr_en : in  std_logic;
        wr_data : in  std_logic_vector(WIDTH-1 downto 0);
        full : out std_logic;

        rd_en : in  std_logic;
        rd_data : out std_logic_vector(WIDTH-1 downto 0);
        empty : out std_logic
    );
end entity uart_fifo;

architecture behavioral of uart_fifo is

    type mem_t is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
    signal mem : mem_t := (others => (others => '0'));

    signal wr_ptr : integer range 0 to DEPTH-1 := 0;
    signal rd_ptr : integer range 0 to DEPTH-1 := 0;
    signal level  : integer range 0 to DEPTH   := 0;

    signal full_int : std_logic;
    signal empty_int : std_logic;
    signal do_wr : std_logic;
    signal do_rd : std_logic;

begin

    full_int <= '1' when level = DEPTH else '0';
    empty_int <= '1' when level = 0 else '0';
    do_wr <= wr_en and not full_int;
    do_rd <= rd_en and not empty_int;
    full <= full_int;
    empty <= empty_int;
    rd_data <= mem(rd_ptr);

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            wr_ptr <= 0;
            rd_ptr <= 0;
            level  <= 0;

        elsif rising_edge(clk) then

            if do_wr = '1' then
                mem(wr_ptr) <= wr_data;
                if wr_ptr = DEPTH - 1 then
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
                end if;
            end if;

            -- Read pointer advance (data itself is combinational)
            if do_rd = '1' then
                if rd_ptr = DEPTH - 1 then
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;
                end if;
            end if;

            if do_wr = '1' and do_rd = '1' then
                level <= level;
            elsif do_wr = '1' then
                level <= level + 1;
            elsif do_rd = '1' then
                level <= level - 1;
            end if;

        end if;
    end process;

end architecture behavioral;