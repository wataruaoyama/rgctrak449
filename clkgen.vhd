Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY clkgen IS
PORT(RESET,CLK : IN std_logic;
		CLK_MSEC : OUT std_logic;
		CLK_FIL : OUT std_logic;
		ENDIVCLK : OUT std_logic);
END clkgen;

ARCHITECTURE RTL OF clkgen IS

SIGNAL counter_msec : std_logic_vector(17 downto 0);

BEGIN

--Generate 100msec timer
process(RESET,CLK) BEGIN
	if(RESET = '0') then
		counter_msec <= "000000000000000000";
	elsif(CLK'event and CLK='1') then
		counter_msec <= counter_msec + '1';
	end if;
end process;

CLK_MSEC <= counter_msec(17);	-- about 25msec. Change 100ms to 25ms  at revision1.3
-- CLK_MSEC <= counter_msec(13);	-- For simulation only
CLK_FIL <= counter_msec(17);	-- Clock for chattering canceller: about 25ms
ENDIVCLK <= counter_msec(14);	-- about 610Hz

end RTL;