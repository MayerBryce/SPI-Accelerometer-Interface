library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_fsm_toplevel is 
	port ( 
		  CPU_RESETN    : in  std_logic;
		  SYS_CLK       : in  std_logic;
		  SW            : in STD_LOGIC_VECTOR(15 downto 0);
		  SCK           : out std_logic;
		  CS            : out std_logic;
		  MOSI          : out std_logic;
		  MISO          : in  std_logic;
		  LED           : out STD_LOGIC_VECTOR(17 downto 0));

end spi_fsm_toplevel;

architecture structural of spi_fsm_toplevel is 

signal slck              : std_logic;
signal i_start_s         : std_logic;
signal tx_start_s        : std_logic;
signal tx_end_s          : std_logic;
signal o_data_ready_s    : std_logic;
signal o_data_parallel_s : std_logic_vector(15 downto 0);
signal i_data_parallel_s : std_logic_vector(15 downto 0);

component spi_controller
generic(
		N        : integer := 8;
		CLK_DIV  : integer := 100);
port( 
     i_clk            : in  std_logic;
	 i_rstb           : in  std_logic;
	 i_tx_start       : in  std_logic;
	 o_tx_end         : out std_logic;
	 i_data_parallel  : in  std_logic_vector(N-1 downto 0);
	 o_data_parallel  : out std_logic_vector(N-1 downto 0);
	 o_sclk           : out std_logic;
	 o_ss             : out std_logic;
	 o_mosi           : out std_logic;
	 i_miso           : in  std_logic);
end component;

component spi_readdata_fsm
port(
	 i_clk            : in  std_logic;                      -- system clock
	 i_rstb           : in  std_logic;                      -- system reset (active low)
	 i_start          : in  std_logic;                      -- start data read operation
     o_data_ready     : out std_logic;                      -- accelerometer data is ready (updated)
     o_xaxis_data     : out std_logic_vector(15 downto 0);  -- received xaxis data 
     o_yaxis_data     : out std_logic_vector(15 downto 0);  -- received yaxis data 
     o_zaxis_data     : out std_logic_vector(15 downto 0);  -- received zaxis data 
		  
     o_tx_start       : out std_logic;                      -- start spi cycle
     o_data_parallel  : out std_logic_vector(15 downto 0);  -- data to send on spi bus 
     i_tx_end         : in  std_logic;                      -- current spi transaction complete 
	 i_data_parallel  : in  std_logic_vector(15 downto 0));
end component;

-- constant CLOCK_FREQ : positive := 1_000_000;              -- value for simulation
constant CLOCK_FREQ : positive := 100_000_000;        -- value for synthesis
constant N       : integer := 16;
constant CLK_DIV : integer := 100;
signal x_sig : std_logic_vector(15 downto 0);
signal y_sig : std_logic_vector(15 downto 0);
signal z_sig : std_logic_vector(15 downto 0);

begin

-- LED_MUX : ENTITY work.LED_MUX(behavior)
          -- PORT MAP(X => x_sig,
                   -- Y => y_sig,
                   -- Z => z_sig,
                   -- S0 => SW(0),
                   -- S1 => SW(1),
                   -- Out_LED => LED(15 downto 0));

START_CLK : ENTITY work.clock_divider(behavior)
		    GENERIC MAP(CLK_FREQ => CLOCK_FREQ)
			PORT MAP(mclk => SYS_CLK, sclk => i_start_s);			
                     
u_spi_controller : spi_controller
generic map(N       => N,
			CLK_DIV => CLK_DIV)
port map(i_clk           => SYS_CLK,
		 i_rstb          => CPU_RESETN,
		 i_tx_start      => tx_start_s,
		 o_tx_end        => tx_end_s,
		 i_data_parallel => o_data_parallel_s,
		 o_data_parallel => i_data_parallel_s,
		 o_sclk          => SCK,
		 o_ss            => CS,
		 o_mosi          => MOSI,
		 i_miso          => MISO);
		 
u_spi_readdata_fsm : spi_readdata_fsm
port map( i_clk           => SYS_CLK,
		 i_rstb          => CPU_RESETN,
		 i_start         => i_start_s,
		 o_data_ready    => o_data_ready_s,
		 o_tx_start      => tx_start_s,
		 o_data_parallel => o_data_parallel_s,
		 i_tx_end        => tx_end_s,
		 i_data_parallel => i_data_parallel_s,
		 o_xaxis_data => x_sig,
		 o_yaxis_data => y_sig,
		 o_zaxis_data => z_sig);
		 
LED(17) <= i_start_s;
LED(16) <= NOT CPU_RESETN;
--LED(15 downto 0) <= x_sig(15 downto 0);


PHASE4 : PROCESS(SYS_CLK,x_sig,z_sig)
         variable ratio : integer;
         BEGIN
         
            -- determine if x is positive
            if (to_integer(signed(x_sig)) > 0) then
                if (to_integer(signed(x_sig)) < to_integer(signed(z_sig))) then
                    ratio := ((to_integer(signed(z_sig)))*10 / to_integer(signed(x_sig)));
                else
                    ratio := ((to_integer(signed(x_sig)))*10 / to_integer(signed(z_sig)));
                end if;
                
            -- angle between 0 and 45
            if (to_integer(signed(z_sig)) >= to_integer(signed(x_sig))) then
                if ((ratio < 57) AND (ratio > 28)) then
                    LED(15 downto 0) <= "0000000011000000";
                elsif ((ratio < 27) AND (ratio > 17)) then
                    LED(15 downto 0) <= "0000000010100000";
                elsif ((ratio < 16) AND (ratio > 12)) then
                    LED(15 downto 0) <= "0000000010010000";
                elsif ((ratio <= 11)) then
                    LED(15 downto 0) <= "0000000010001000";
                else
                    LED(15 downto 0) <= "0000000010000000";
                end if;
            end if;
            
            -- angle between 45 and 90
            if (to_integer(signed(z_sig)) <= to_integer(signed(x_sig))) then
                if ((ratio <= 11) AND (ratio >= 10)) then
                    LED(15 downto 0) <= "0000000010001000";
                elsif ((ratio < 16) AND (ratio > 12)) then
                    LED(15 downto 0) <= "0000000010000100";
                elsif ((ratio < 26) AND (ratio > 17)) then
                    LED(15 downto 0) <= "0000000010000010";
                elsif (ratio > 27) then
                    LED(15 downto 0) <= "0000000010000001";
                else
                    LED(15 downto 0) <= "0000000010000000";
                end if;
            end if;
            end if;
            
            -- determine if x is negative 
            if (to_integer(signed(x_sig)) < 0) then
            if ((abs(to_integer(signed(x_sig)))) < to_integer(signed(z_sig))) then
                    ratio := ((to_integer(signed(z_sig)))*10 / (abs(to_integer(signed(x_sig)))));
                else
                    ratio := ((abs(to_integer(signed(x_sig))))*10 / to_integer(signed(z_sig)));
                end if;
            
            -- angle between 0 and -45
            if (to_integer(signed(z_sig)) > (abs(to_integer(signed(x_sig))))) then
                if ((ratio < 57) AND (ratio > 27)) then
                    LED(15 downto 0) <= "0000000110000000";
                elsif ((ratio < 26) AND (ratio > 17)) then
                    LED(15 downto 0) <= "0000001010000000";
                elsif ((ratio < 16) AND (ratio > 12)) then
                    LED(15 downto 0) <= "0000010010000000";
                elsif ((ratio <= 11)) then
                    LED(15 downto 0) <= "0000100010000000";
                else
                    LED(15 downto 0) <= "0000000010000000";
                end if;
            end if;
            
            -- angle between -45 and -90
            if (to_integer(signed(z_sig)) < (abs(to_integer(signed(x_sig))))) then
                if ((ratio <= 11) AND (ratio >= 10)) then
                    LED(15 downto 0) <= "0000100010000000";
                elsif ((ratio < 16) AND (ratio > 12)) then
                    LED(15 downto 0) <= "0001000010000000";
                elsif ((ratio < 26) AND (ratio > 17)) then
                    LED(15 downto 0) <= "0010000010000000";
                elsif (ratio > 27) then
                    LED(15 downto 0) <= "0100000010000000";
                else
                    LED(15 downto 0) <= "0000000010000000";
                end if;
            end if;
            end if;
            
         END PROCESS PHASE4;

end structural;