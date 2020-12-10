library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_readdata_fsm is
	port (
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
		  i_data_parallel  : in  std_logic_vector(15 downto 0));  -- data from current transaction 
end spi_readdata_fsm;

architecture rtl of spi_readdata_fsm is

constant N            : integer := 16;
constant NO_VECTORS   : integer := 8;

type t_output_value_array is array (1 to NO_VECTORS) of std_logic_vector(N-1 downto 0);

constant o_data_values : t_output_value_array := (std_logic_vector(to_unsigned(16#2C08#,N)),
                                                  std_logic_vector(to_unsigned(16#2D08#,N)),
                                                  std_logic_vector(to_unsigned(16#B201#,N)),
                                                  std_logic_vector(to_unsigned(16#B302#,N)),
                                                  std_logic_vector(to_unsigned(16#B403#,N)),
                                                  std_logic_vector(to_unsigned(16#B504#,N)),
                                                  std_logic_vector(to_unsigned(16#B605#,N)),
                                                  std_logic_vector(to_unsigned(16#B706#,N)));
                                                  
type t_spi_readdata_fsm is (WaitToStart, StartTransactionOne, StartTransactionTwo, StartTransactionThree,
                            StartTransactionFour, StartTransactionFive, StartTransactionSix,
                            StartTransactionSeven, StartTransactionEight, EndTransaction, EndTransactionWait,
                            EndTransactionWait1to7, WaitToStartTransOne, WaitToStartTransTwo, WaitToStartTransThree, 
                            WaitToStartTransFour, WaitToStartTransFive, WaitToStartTransSix, WaitToStartTransSeven,
                            WaitToStartTransEight);

SIGNAL present_state : t_spi_readdata_fsm;
SIGNAL next_state    : t_spi_readdata_fsm;
SIGNAL present_count : integer range 0 to NO_VECTORS;
SIGNAL increment_count : std_logic;
SIGNAL count_reset : std_logic;


begin
 clocked : PROCESS(i_clk,i_rstb)
   BEGIN
     IF(i_rstb='0') THEN 
       present_state <= WaitToStart;
    ELSIF(rising_edge(i_clk)) THEN
       present_state <= next_state;
       if(increment_count = '1') then
        present_count <= present_count + 1;
       elsif(count_reset = '1') then
        present_count <= 0;
       end if;
    END IF;
 END PROCESS clocked;

nextstate : PROCESS(present_state,i_start, i_tx_end, i_clk)
BEGIN
     increment_count <= '0';
     count_reset <= '0';
     CASE present_state IS
       WHEN WaitToStart  =>
            if(i_start = '0') then
                next_state <= WaitToStart;
            elsif(i_start = '1') then
                increment_count <= '1';
                if(present_count = 0) then
                next_state <= WaitToStartTransOne;
                elsif(present_count = 1) then
            next_state <= WaitToStartTransTwo;
                elsif(present_count = 2) then
            next_state <= WaitToStartTransThree;
                elsif(present_count = 3) then
            next_state <= WaitToStartTransFour;
                elsif(present_count = 4) then
            next_state <= WaitToStartTransFive;
                elsif(present_count = 5) then
            next_state <= WaitToStartTransSix;
                elsif(present_count = 6) then
            next_state <= WaitToStartTransSeven;
                elsif(present_count = 7) then
            next_state <= WaitToStartTransEight;
                elsif(present_count = 8) then
                increment_count <= '0';
                end if;
            end if;
            
       WHEN WaitToStartTransOne =>
            next_state <= StartTransactionOne;
            
       WHEN WaitToStartTransTwo =>
            next_state <= StartTransactionTwo;
            
       WHEN WaitToStartTransThree =>
            next_state <= StartTransactionThree;
            
       WHEN WaitToStartTransFour =>
            next_state <= StartTransactionFour;
            
       WHEN WaitToStartTransFive =>
            next_state <= StartTransactionFive;
            
       WHEN WaitToStartTransSix =>
            next_state <= StartTransactionSix;
            
       WHEN WaitToStartTransSeven =>
            next_state <= StartTransactionSeven;
            
       WHEN WaitToStartTransEight =>
            next_state <= StartTransactionEight;
            
       WHEN StartTransactionOne  =>
            if(i_tx_end = '1') then
            next_state <= EndTransaction;
            else
            next_state <= StartTransactionOne;
            end if;       
            
       WHEN StartTransactionTwo  =>
            if(i_tx_end = '1') then
            next_state <= EndTransaction;
            else
            next_state <= StartTransactionTwo;
            end if;
            
       WHEN StartTransactionThree  =>
            if(i_tx_end = '1') then
            next_state <= EndTransaction;
            else
            next_state <= StartTransactionThree;
            end if;
            
       WHEN StartTransactionFour  =>
            if(i_tx_end = '1') then
            next_state <= EndTransaction;
            else
            next_state <= StartTransactionFour;
            end if;
            
       WHEN StartTransactionFive  =>
            if(i_tx_end = '1') then
            next_state <= EndTransaction;
            else
            next_state <= StartTransactionFive;
            end if;
            
       WHEN StartTransactionSix  =>
            if(i_tx_end = '1') then
            next_state <= EndTransaction;
            else
            next_state <= StartTransactionSix;
            end if;
            
       WHEN StartTransactionSeven  =>
            if(i_tx_end = '1') then
            next_state <= EndTransaction;
            else
            next_state <= StartTransactionSeven;
            end if;
            
       WHEN StartTransactionEight  =>
            if(i_tx_end = '1') then
            next_state <= EndTransactionWait;
            else
            next_state <= StartTransactionEight;
            end if;
            
       WHEN EndTransactionWait =>
            if(i_start = '1') then
            count_reset <= '1';
            next_state <= EndTransactionWait;
            else
            next_state <= EndTransaction;
            end if;
            
       WHEN EndTransactionWait1to7 =>
            next_state <= WaitToStart;
            
       WHEN EndTransaction  =>
            if(i_tx_end = '0') then
            next_state <= EndTransactionWait1to7;
            else
            next_state <= EndTransaction;
            end if;
     END CASE;
END PROCESS nextstate;

 output : PROCESS(present_state,i_clk)
   BEGIN
     CASE present_state IS
       WHEN WaitToStart  =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '0';
       WHEN WaitToStartTransOne =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '1';     
       WHEN WaitToStartTransTwo =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '1';      
       WHEN WaitToStartTransThree =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '1'; 
       WHEN WaitToStartTransFour =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '1'; 
       WHEN WaitToStartTransFive =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '1'; 
       WHEN WaitToStartTransSix =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '1'; 
       WHEN WaitToStartTransSeven =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '1'; 
       WHEN WaitToStartTransEight =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '1'; 
       WHEN StartTransactionOne  =>
       o_data_parallel <= x"2c08";
       o_tx_start <= '0';
       WHEN StartTransactionTwo  =>
       o_data_parallel <= x"2d08";
       o_tx_start <= '0';
       WHEN StartTransactionThree  =>
       o_data_parallel <= x"B200";
       o_tx_start <= '0';
       WHEN StartTransactionFour  =>
       o_data_parallel <= x"B300";
       o_tx_start <= '0';
       WHEN StartTransactionFive  =>
       o_data_parallel <= x"B400";
       o_tx_start <= '0';
       WHEN StartTransactionSix  =>
       o_data_parallel <= x"B500";
       o_tx_start <= '0';
       WHEN StartTransactionSeven  =>
       o_data_parallel <= x"B600";
       o_tx_start <= '0';
       WHEN StartTransactionEight  =>
       o_data_parallel <= x"B700";
       o_tx_start <= '0';
       WHEN EndTransactionWait1to7 =>
       o_data_parallel <= x"B700";
       o_tx_start <= '0';
       WHEN EndTransactionWait =>
       o_data_parallel <= x"B700";
       o_tx_start <= '0';
       WHEN EndTransaction  =>
       o_data_parallel <= x"B700";
       o_tx_start <= '0';
       
     END CASE;
 END PROCESS output;
 
data_out : process(i_clk)
 begin
    IF(rising_edge(i_clk)) THEN
       if(present_state = EndTransaction or present_state = EndTransactionWait) then
           CASE present_count is
          when 0 =>
          null;
          when 1 =>
          null;
          when 2 =>
          null;
          when 3 => 
            o_xaxis_data(7 downto 0) <= i_data_parallel(7 downto 0);
          when 4 =>
            o_xaxis_data(15 downto 8) <= i_data_parallel(7 downto 0);
          when 5 =>
            o_yaxis_data(7 downto 0) <= i_data_parallel(7 downto 0);
          when 6 => 
            o_yaxis_data(15 downto 8) <= i_data_parallel(7 downto 0);
          when 7 =>
            o_zaxis_data(7 downto 0) <= i_data_parallel(7 downto 0);
          when 8 =>
            o_zaxis_data(15 downto 8) <= i_data_parallel(7 downto 0);
       END CASE;
      end if;
     end if;
    --check to see if you are in end transaction state
    --if so, then create case statement based on present out
    --output data to o_axis_data
 end process data_out;
 END rtl;