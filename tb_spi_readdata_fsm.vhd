library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spi_readdata_fsm is
end tb_spi_readdata_fsm;

architecture rtl of tb_spi_readdata_fsm is

component spi_fsm_toplevel is
port(     CPU_RESETN    : in  std_logic;
		  SYS_CLK       : in  std_logic;
		  SW            : in STD_LOGIC_VECTOR(15 downto 0);
		  SCK           : out std_logic;
		  CS            : out std_logic;
		  MOSI          : out std_logic;
		  MISO          : in  std_logic;
		  LED           : out STD_LOGIC_VECTOR(15 downto 0));
end component;

constant N		:integer := 16;
constant NO_VECTORS : integer := 8;

type output_value_array is array (1 to NO_VECTORS) of std_logic_vector(N-1 downto 0);

constant i_data_values : output_value_array := (std_logic_vector(to_unsigned(16#2C08#,N)),
                                                std_logic_vector(to_unsigned(16#2D08#,N)),
                                                std_logic_vector(to_unsigned(16#B201#,N)),
                                                std_logic_vector(to_unsigned(16#B302#,N)),
                                                std_logic_vector(to_unsigned(16#B403#,N)),
                                                std_logic_vector(to_unsigned(16#B504#,N)),
                                                std_logic_vector(to_unsigned(16#B605#,N)),
                                                std_logic_vector(to_unsigned(16#B706#,N)));

constant o_data_values : output_value_array := (std_logic_vector(to_unsigned(16#00A1#,N)),
                                                std_logic_vector(to_unsigned(16#00B2#,N)),
                                                std_logic_vector(to_unsigned(16#0032#,N)),
                                                std_logic_vector(to_unsigned(16#0033#,N)),
                                                std_logic_vector(to_unsigned(16#0034#,N)),
                                                std_logic_vector(to_unsigned(16#0035#,N)),
                                                std_logic_vector(to_unsigned(16#0036#,N)),
                                                std_logic_vector(to_unsigned(16#0037#,N)));
												
signal o_data_index 	: integer := 1;
signal i_data_index		: integer := 1;
signal count_fall		: integer := 0;
signal count_rise		: integer := 0;
signal sys_clk_sig		:std_logic := '0';
signal cpu_resetn_sig   :std_logic;
signal sck_sig			:std_logic;
signal cs_sig			:std_logic;
signal mosi_sig         :std_logic;
signal miso_sig  		:std_logic;
signal LED_S            :std_logic_vector(15 downto 0);
signal SW_s             :std_logic_vector(15 downto 0);

signal master_data_received : std_logic_vector(N-1 downto 0);
signal slave_data_sent      : std_logic_vector(N-1 downto 0);


begin

DUT: spi_fsm_toplevel
	port map(CPU_RESETN => cpu_resetn_sig,
			 SYS_CLK => sys_clk_sig,
			 sck => sck_sig,
             SW => SW_s,
			 CS => cs_sig,
			 MOSI => mosi_sig,
			 MISO => miso_sig,
			 LED => LED_S);
			 
sys_clk_sig <= not sys_clk_sig after 5 ns;
cpu_resetn_sig <= '1', '0' after 163 ns, '1' after 263 ns;


spi_slave_sim : process(sck_sig, cpu_resetn_sig)
begin
	if(cpu_resetn_sig='0') then
		o_data_index      <= 1;			-- initialize to first input vector
		slave_data_sent   <= o_data_values(1);
		miso_sig      <= '0';
		count_fall  <= 0;
	else
		if(falling_edge(sck_sig)) then
			if(cs_sig='0') then
				count_fall     <= count_fall+1;
				slave_data_sent   <= std_logic_vector(shift_left(unsigned(slave_data_sent),1));
				miso_sig      <= slave_data_sent(N-1) after 63 ns;
			else
				count_fall     <= 0;
			end if;
			if(count_fall = 16) then
			  count_fall <= 1;
			  if(o_data_index = NO_VECTORS) then
			    o_data_index <= 1;
			    slave_data_sent <= std_logic_vector(shift_left(unsigned(o_data_values(1)),1));
				miso_sig      <= o_data_values(1)(N-1) after 63 ns;
			  else
			    o_data_index <= o_data_index + 1;
			    slave_data_sent   <= std_logic_vector(shift_left(unsigned(o_data_values(o_data_index+1)),1));
				miso_sig      <= o_data_values(o_data_index+1)(N-1) after 63 ns;
			  end if;
			end if;
		end if;
	end if;
end process spi_slave_sim;

-- this process monitors the SPI master to ensure that its sending out
-- the proper values on mosi_sig on the rising edge of sck_sig

spi_master_monitor : process(sck_sig, cpu_resetn_sig)
  begin
	if(cpu_resetn_sig='0') then
		i_data_index      <= 1;			-- initialize to first input vector
		master_data_received   <= std_logic_vector(to_unsigned(16#00#,N));
		count_rise  <= 0;
    else
		if(rising_edge(sck_sig)) then
			if(cs_sig='0' and count_rise < 16) then
				master_data_received   <= master_data_received(N-2 downto 0)&mosi_sig;
				count_rise     <= count_rise+1;
		    elsif(cs_sig='0' and count_rise = 16) then
			   assert master_data_received(14 downto 0) = i_data_values(i_data_index)(14 downto 0)
               report "ERROR - incorrect value on master_data_received"
               severity error;
               count_rise <= 1;
               master_data_received   <= std_logic_vector(to_unsigned(16#00#,N));
               if(i_data_index < NO_VECTORS) then
                 i_data_index <= i_data_index+1;                 -- point to next vector
               else
                 i_data_index <= 1;                              -- point to first vector
               end if;
			else
				count_rise     <= 1;
			end if;
		end if;
	end if;
end process spi_master_monitor;  
end rtl;
			   
