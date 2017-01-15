Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY clkdiv IS
PORT(RESET,CLK_40M : IN std_logic;
		CLK : OUT std_logic);
END clkdiv;

ARCHITECTURE RTL OF clkdiv IS

signal cnt_clk : std_logic_vector(1 downto 0);

BEGIN

--Generate system clock
process(RESET,CLK_40M) BEGIN
	if(RESET = '0') then
		cnt_clk <= "00";
	elsif(CLK_40M'event and CLK_40M='1') then
		cnt_clk <= cnt_clk + '1';
	end if;
end process;

CLK <= cnt_clk(1);

end RTL;