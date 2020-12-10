library IEEE;
use IEEE.std_logic_1164.all;

ENTITY clock_divider is
  GENERIC(CLK_FREQ : positive := 100_000_000);
          --DIVISOR : positive); -- input clock frequency in Hz
  PORT(mclk : IN  std_logic;
       sclk : OUT std_logic);
END clock_divider;

ARCHITECTURE behavior OF clock_divider IS

    CONSTANT SLOW_CLOCK_FREQ : positive := 5;                 -- slow clock frequency in Hz
    CONSTANT DIVISOR : positive := CLK_FREQ/SLOW_CLOCK_FREQ;  -- how much to divide clock by
    SIGNAL sclki : std_logic := '0';

  BEGIN

    div_clk : PROCESS(mclk)

      VARIABLE count : integer RANGE 0 to DIVISOR/2 := 0;

      BEGIN
        IF(rising_edge(mclk)) THEN
          IF(count = (DIVISOR/2)-1) THEN
            sclki <= not sclki;
            count := 0;
          ELSE
            count := count + 1;
          END IF;
        END IF;
    END PROCESS div_clk;

    sclk <= sclki;

END behavior;


