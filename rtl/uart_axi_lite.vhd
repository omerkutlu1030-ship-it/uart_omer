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

    rx : in  std_logic;
    tx : out std_logic
  );
end entity uart_axi_lite;

architecture rtl of uart_axi_lite is

  -- Register map
  --   0x00  CTRL     RW  [3:0] = baud_sel
  --   0x04  STATUS   RO  [1]   = rx_empty, [0] = tx_full
  --   0x08  TX_DATA  WO  [7:0] = byte to transmit
  --   0x0C  RX_DATA  RO  [7:0] = received byte
  constant ADDR_CTRL    : std_logic_vector(7 downto 0) := x"00";
  constant ADDR_STATUS  : std_logic_vector(7 downto 0) := x"04";
  constant ADDR_TX_DATA : std_logic_vector(7 downto 0) := x"08";
  constant ADDR_RX_DATA : std_logic_vector(7 downto 0) := x"0C";

  constant RESP_OKAY   : std_logic_vector(1 downto 0) := "00";
  constant RESP_SLVERR : std_logic_vector(1 downto 0) := "10";

  -- Internal register
  signal reg_ctrl : std_logic_vector(31 downto 0) := (others => '0');

  -- UART core interface
  signal core_tx_write    : std_logic := '0';
  signal core_tx_byte_in  : std_logic_vector(7 downto 0) := (others => '0');
  signal core_tx_full     : std_logic;
  signal core_rx_read     : std_logic := '0';
  signal core_rx_byte_out : std_logic_vector(7 downto 0);
  signal core_rx_empty    : std_logic;
  signal core_tx_done     : std_logic;
  signal core_rx_valid    : std_logic;

  -- Write channel FSM
  --   ADDR_WRITE : latch write address  (AW channel handshake)
  --   DATA_WRITE : latch write data, perform register write  (W channel handshake)
  --   RESP_WRITE : hold response until master accepts  (B channel handshake)
  type wr_state_t is (ADDR_WRITE, DATA_WRITE, RESP_WRITE);
  signal wr_state       : wr_state_t := ADDR_WRITE;
  signal latched_awaddr : std_logic_vector(7 downto 0) := (others => '0');

  -- Read channel FSM
  --   ADDR_READ : latch read address, decode register  (AR channel handshake)
  --   DATA_READ : hold read data until master accepts  (R channel handshake)
  type rd_state_t is (ADDR_READ, DATA_READ);
  signal rd_state : rd_state_t := ADDR_READ;

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

  -- ------------------------------------------------------------------
  -- Write FSM  :  ADDR_WRITE -> DATA_WRITE -> RESP_WRITE -> ADDR_WRITE
  -- ------------------------------------------------------------------
  p_write : process(s_axi_aclk, s_axi_aresetn)
  begin
    if s_axi_aresetn = '0' then
      wr_state        <= ADDR_WRITE;
      s_axi_awready   <= '0';
      s_axi_wready    <= '0';
      s_axi_bvalid    <= '0';
      s_axi_bresp     <= RESP_OKAY;
      reg_ctrl        <= (others => '0');
      core_tx_write   <= '0';
      core_tx_byte_in <= (others => '0');
      latched_awaddr  <= (others => '0');

    elsif rising_edge(s_axi_aclk) then
      -- Default: these are one-cycle pulses, cleared every cycle
      s_axi_awready <= '0';
      s_axi_wready  <= '0';
      core_tx_write <= '0';

      case wr_state is

        -- ---- Stage 1: capture write address -------------------------
        when ADDR_WRITE =>
          if s_axi_awvalid = '1' then
            s_axi_awready  <= '1';        -- one-cycle pulse, completes AW handshake
            latched_awaddr <= s_axi_awaddr;

            if s_axi_wvalid = '1' then
              -- AW and W arrived simultaneously (UVVM BFM drives both at once)
              s_axi_wready <= '1';        -- complete W handshake in the same cycle

              case s_axi_awaddr is        -- use direct input; latched_awaddr updates next cycle

                when ADDR_CTRL =>
                  for i in 0 to 3 loop
                    if s_axi_wstrb(i) = '1' then
                      reg_ctrl(8*i+7 downto 8*i) <= s_axi_wdata(8*i+7 downto 8*i);
                    end if;
                  end loop;
                  s_axi_bresp <= RESP_OKAY;

                when ADDR_TX_DATA =>
                  if core_tx_full = '0' then
                    core_tx_byte_in <= s_axi_wdata(7 downto 0);
                    core_tx_write   <= '1';
                    s_axi_bresp     <= RESP_OKAY;
                  else
                    s_axi_bresp <= RESP_SLVERR;
                  end if;

                when others =>
                  s_axi_bresp <= RESP_SLVERR;

              end case;

              s_axi_bvalid <= '1';
              wr_state     <= RESP_WRITE; -- skip DATA_WRITE entirely

            else
              -- Only address arrived; wait for data on next cycle
              wr_state <= DATA_WRITE;
            end if;
          end if;

        -- ---- Stage 2: capture write data, decode and write ----------
        -- (reached only when AW and W arrived on different cycles)
        when DATA_WRITE =>
          if s_axi_wvalid = '1' then
            s_axi_wready <= '1';          -- one-cycle pulse, completes W handshake

            case latched_awaddr is

              when ADDR_CTRL =>
                -- byte-lane strobes for partial writes
                for i in 0 to 3 loop
                  if s_axi_wstrb(i) = '1' then
                    reg_ctrl(8*i+7 downto 8*i) <= s_axi_wdata(8*i+7 downto 8*i);
                  end if;
                end loop;
                s_axi_bresp <= RESP_OKAY;

              when ADDR_TX_DATA =>
                if core_tx_full = '0' then
                  core_tx_byte_in <= s_axi_wdata(7 downto 0);
                  core_tx_write   <= '1'; -- one-cycle FIFO push pulse
                  s_axi_bresp     <= RESP_OKAY;
                else
                  s_axi_bresp <= RESP_SLVERR; -- TX FIFO full, reject write
                end if;

              when others =>
                s_axi_bresp <= RESP_SLVERR; -- read-only or invalid address

            end case;

            s_axi_bvalid <= '1';
            wr_state     <= RESP_WRITE;
          end if;

        -- ---- Stage 3: hold response until master accepts ------------
        when RESP_WRITE =>
          s_axi_bvalid <= '1';
          if s_axi_bready = '1' then
            s_axi_bvalid <= '0';          -- last assignment wins, clears bvalid
            wr_state     <= ADDR_WRITE;
          end if;

      end case;
    end if;
  end process p_write;

  -- ------------------------------------------------------------------
  -- Read FSM  :  ADDR_READ -> DATA_READ -> ADDR_READ
  -- ------------------------------------------------------------------
  p_read : process(s_axi_aclk, s_axi_aresetn)
  begin
    if s_axi_aresetn = '0' then
      rd_state      <= ADDR_READ;
      s_axi_arready <= '0';
      s_axi_rvalid  <= '0';
      s_axi_rdata   <= (others => '0');
      s_axi_rresp   <= RESP_OKAY;
      core_rx_read  <= '0';

    elsif rising_edge(s_axi_aclk) then
      -- Default: one-cycle pulses, cleared every cycle
      s_axi_arready <= '0';
      core_rx_read  <= '0';

      case rd_state is

        -- ---- Stage 1: capture read address, decode register ---------
        when ADDR_READ =>
          if s_axi_arvalid = '1' then
            s_axi_arready <= '1';         -- one-cycle pulse, completes AR handshake

            case s_axi_araddr is

              when ADDR_CTRL =>
                s_axi_rdata <= reg_ctrl;
                s_axi_rresp <= RESP_OKAY;

              when ADDR_STATUS =>
                -- bit 1 = rx_empty   bit 0 = tx_full
                s_axi_rdata <= (31 downto 2 => '0') & core_rx_empty & core_tx_full;
                s_axi_rresp <= RESP_OKAY;

              when ADDR_RX_DATA =>
                if core_rx_empty = '0' then
                  s_axi_rdata  <= (31 downto 8 => '0') & core_rx_byte_out;
                  core_rx_read <= '1';    -- one-cycle FIFO pop pulse
                  s_axi_rresp  <= RESP_OKAY;
                else
                  s_axi_rdata <= (others => '0');
                  s_axi_rresp <= RESP_SLVERR; -- RX FIFO empty, no data
                end if;

              when others =>
                s_axi_rdata <= (others => '0');
                s_axi_rresp <= RESP_SLVERR;   -- write-only or invalid address

            end case;

            s_axi_rvalid <= '1';
            rd_state     <= DATA_READ;
          end if;

        -- ---- Stage 2: hold read data until master accepts -----------
        when DATA_READ =>
          s_axi_rvalid <= '1';
          if s_axi_rready = '1' then
            s_axi_rvalid <= '0';          -- last assignment wins, clears rvalid
            rd_state     <= ADDR_READ;
          end if;

      end case;
    end if;
  end process p_read;

end architecture rtl;
