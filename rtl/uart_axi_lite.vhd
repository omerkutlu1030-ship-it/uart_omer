library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uart_lib;
use uart_lib.all;


entity uart_axi_lite is
  generic (
    CLK_FREQ : integer := 100000000
  );
  port (
    -- Clock & reset
    s_axi_aclk    : in  std_logic;
    s_axi_aresetn : in  std_logic;

    -- Write address channel (AW)
    s_axi_awaddr  : in  std_logic_vector(7 downto 0);
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;

    -- Write data channel (W)
    s_axi_wdata   : in  std_logic_vector(31 downto 0);
    s_axi_wstrb   : in  std_logic_vector(3 downto 0);
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;

    -- Write response channel (B)
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;

    -- Read address channel (AR)
    s_axi_araddr  : in  std_logic_vector(7 downto 0);
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;

    -- Read data channel (R)
    s_axi_rdata   : out std_logic_vector(31 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic;

    rx : in std_logic;
    tx : out std_logic
  );
end entity uart_axi_lite;

architecture rtl of uart_axi_lite is

  constant ADDR_CTRL    : std_logic_vector(7 downto 0) := x"00";
  constant ADDR_STATUS  : std_logic_vector(7 downto 0) := x"04";
  constant ADDR_TX_DATA : std_logic_vector(7 downto 0) := x"08";
  constant ADDR_RX_DATA : std_logic_vector(7 downto 0) := x"0C";

  signal reg_ctrl : std_logic_vector(31 downto 0) := (others => '0');

  signal core_tx_write    : std_logic := '0';
  signal core_tx_byte_in  : std_logic_vector(7 downto 0) := (others => '0');
  signal core_tx_full     : std_logic;
  signal core_rx_read     : std_logic := '0';
  signal core_rx_byte_out : std_logic_vector(7 downto 0);
  signal core_rx_empty    : std_logic;
  signal core_tx_done     : std_logic;
  signal core_rx_valid    : std_logic;

  signal aw_done         : std_logic := '0';
  signal w_done          : std_logic := '0';
  signal latched_awaddr  : std_logic_vector(7 downto 0)  := (others => '0');
  signal latched_wdata   : std_logic_vector(31 downto 0) := (others => '0');


  type write_state_t is (W_IDLE, W_ADDR, W_DATA, W_RESP);
  signal w_state : write_state_t := W_IDLE;

  type read_state_t is (R_IDLE, R_ADDR, R_DATA, R_RESP);
  signal r_state : read_state_t := R_IDLE;

begin

  -- ------------------------------------------------------------------
  -- UART core instantiation
  -- ------------------------------------------------------------------
  u_uart_core : entity uart_lib.uart_top
    generic map (
      CLK_FREQ => CLK_FREQ
    )
    port map (
      clk         => s_axi_aclk,
      rst_n       => s_axi_aresetn,
      baud_sel    => reg_ctrl(3 downto 0),
      rx          => rx,
      tx          => tx,
      tx_write    => core_tx_write,
      tx_byte_in  => core_tx_byte_in,
      tx_full     => core_tx_full,
      rx_read     => core_rx_read,
      rx_byte_out => core_rx_byte_out,
      rx_empty    => core_rx_empty,
      tx_done     => core_tx_done,
      rx_valid    => core_rx_valid
    );


    p_write : process(s_axi_aclk, s_axi_aresetn)
    variable v_awaddr : std_logic_vector(7  downto 0);
    variable v_wdata  : std_logic_vector(31 downto 0);
  begin
    if s_axi_aresetn = '0' then
      w_state         <= W_IDLE;
      aw_done         <= '0';
      w_done          <= '0';
      s_axi_awready   <= '0';
      s_axi_wready    <= '0';
      s_axi_bvalid    <= '0';
      s_axi_bresp     <= "00";
      reg_ctrl        <= (others => '0');
      core_tx_write   <= '0';
      core_tx_byte_in <= (others => '0');
      latched_awaddr  <= (others => '0');
      latched_wdata   <= (others => '0');
 
    elsif rising_edge(s_axi_aclk) then
      -- default: tx_write is a one-cycle pulse
      core_tx_write <= '0';
 
      case w_state is
 
        when W_IDLE =>
          -- AW handshake (independent)
          if aw_done = '0' and s_axi_awvalid = '1' then
            s_axi_awready <= '1';
            if s_axi_awvalid = '1' then
              aw_done        <= '1';
              latched_awaddr <= s_axi_awaddr;
              s_axi_awready  <= '0';
            end if;
          end if;
 
          -- W handshake (independent)
          if w_done = '0' and s_axi_wvalid = '1' then
            s_axi_wready <= '1';
            if s_axi_wvalid = '1' then
              w_done        <= '1';
              latched_wdata <= s_axi_wdata;
              s_axi_wready  <= '0';
            end if;
          end if;
 
          -- When both have been collected, do the write and respond.
          -- Use the value being received this cycle if not yet latched.
          if (aw_done = '1' or s_axi_awvalid = '1') and
             (w_done  = '1' or s_axi_wvalid  = '1') then
 
            if aw_done = '1' then
              v_awaddr := latched_awaddr;
            else
              v_awaddr := s_axi_awaddr;
            end if;
 
            if w_done = '1' then
              v_wdata := latched_wdata;
            else
              v_wdata := s_axi_wdata;
            end if;
 
            -- Address decode
            if v_awaddr = ADDR_CTRL then
              reg_ctrl    <= v_wdata;
              s_axi_bresp <= "00";
 
            elsif v_awaddr = ADDR_TX_DATA then
              core_tx_byte_in <= v_wdata(7 downto 0);
              core_tx_write   <= '1';
              s_axi_bresp     <= "00";
 
            else
              s_axi_bresp <= "10";   -- SLVERR
            end if;
 
            -- Clear handshake flags, issue response
            aw_done      <= '0';
            w_done       <= '0';
            s_axi_bvalid <= '1';
            w_state      <= W_RESP;
          end if;
 
        when W_RESP =>
          s_axi_bvalid <= '1';
          if s_axi_bready = '1' then
            s_axi_bvalid <= '0';
            w_state      <= W_IDLE;
          end if;
 
      end case;
    end if;
  end process p_write;


  p_read : process(s_axi_aclk, s_axi_aresetn)
  begin
    if s_axi_aresetn = '0' then
      r_state       <= R_IDLE;
      s_axi_arready <= '0';
      s_axi_rvalid  <= '0';
      s_axi_rdata   <= (others => '0');
      s_axi_rresp   <= "00";
      core_rx_read  <= '0';

    elsif rising_edge(s_axi_aclk) then
      core_rx_read <= '0';

      case r_state is

        when R_IDLE =>
          s_axi_arready <= '1';
          s_axi_rvalid  <= '0';

          if s_axi_arvalid = '1' then
            s_axi_arready <= '0';
            s_axi_rresp   <= "00";

            -- address decode
            if s_axi_araddr = ADDR_CTRL then
              s_axi_rdata <= reg_ctrl;

            elsif s_axi_araddr = ADDR_STATUS then
              s_axi_rdata <= (31 downto 2 => '0') & core_rx_empty & core_tx_full;

            elsif s_axi_araddr = ADDR_RX_DATA then
              -- FIFO presents rd_data combinatorially; latch it and pop
              s_axi_rdata  <= (31 downto 8 => '0') & core_rx_byte_out;
              core_rx_read <= '1';

            else
              s_axi_rdata <= (others => '0');
              s_axi_rresp <= "10";
            end if;

            s_axi_rvalid <= '1';
            r_state      <= R_RESP;
          end if;

        when R_RESP =>
          s_axi_rvalid <= '1';
          if s_axi_rready = '1' then
            s_axi_rvalid  <= '0';
            s_axi_arready <= '1';
            r_state       <= R_IDLE;
          end if;

      end case;
    end if;
  end process p_read;

end architecture rtl;
