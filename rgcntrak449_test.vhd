Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY rgctrak449_test IS
END rgctrak449_test;

ARCHITECTURE rgctrak449_test_bench OF rgctrak449_test IS

COMPONENT rgctrak449
PORT(RESET,CLK,XDSD,DIF0,DIF1,DIF2,SMUTE,DEM0,DEM1 : IN std_logic;
		DZFM,DZFE,SD,SLOW,MONO,DSDSEL0,DSDSEL1 : IN std_logic;
		SSLOW,DSDD,SC0,SC1,DDM,DMC,DMRE : IN std_logic;
		A,B : IN std_logic;
		AK4490,AKWM : IN std_logic;
		DISPSW : IN std_logic;
		CSN,CCLK,CDTI : OUT std_logic;
		COMSEL : OUT std_logic_vector(3 downto 0);
		LED : OUT std_logic_vector(6 downto 0));
END COMPONENT;
	
constant cycle	: Time := 100ns;
constant	half_cycle : Time := 50ns;

constant stb	: Time := 2ns;

signal reset,clk,clk_msec,xdsd,dif0,dif1,dif2,smute,dem0,dem1:std_logic;
signal dzfm,dzfe,sd,slow,sellr,mono,dp,dsdsel0,dsdsel1 : std_logic;
signal sslow,dsdd,sc0,sc1,ddm,dmc,dmre,a,b,ak4490,akwm : std_logic;
signal dispsw : std_logic;
signal csn,cclk,cdti : std_logic;
signal comsel : std_logic_vector(3 downto 0);
signal led : std_logic_vector(6 downto 0);

BEGIN

	U1: rgctrak449 port map (RESET=>reset,CLK=>clk,XDSD=>xdsd,DIF0=>dif0,DIF1=>dif1,DIF2=>dif2,
	SMUTE=>smute,DEM0=>dem0,DEM1=>dem1,DZFM=>dzfm,DZFE=>dzfe,SD=>sd,SLOW=>slow,MONO=>mono,
	DSDSEL0=>dsdsel0,DSDSEL1=>dsdsel1,SSLOW=>sslow,DSDD=>dsdd,SC0=>sc0,SC1=>sc1,DDM=>ddm,
	DMC=>dmc,DMRE=>dmre,A=>a,B=>b,AK4490=>ak4490,AKWM=>akwm,DISPSW=>dispsw,
	CSN=>csn,CCLK=>cclk,CDTI=>cdti,COMSEL=>comsel,LED=>led);
	 
	PROCESS BEGIN
		clk <= '0';
		wait for half_cycle;
		clk <= '1';
		wait for half_cycle;
	end PROCESS;
	

	PROCESS BEGIN
		reset <= '0';
		xdsd <= '0';

		dif0 <= '1';
		dif1 <= '1';
		dif2 <= '1';
		smute <= '0';
		dem0 <= '1';
		dem1 <= '0';
		dzfm <= '0';
		dzfe <= '0';
		sd <= '0';
		slow <= '0';
		--sellr <= '0';
		mono <= '0';
		dsdsel0 <= '0';
		dsdsel1 <= '0';
		sslow <= '0';
		dsdd <= '0';
		sc0 <= '0';
		sc1 <= '0';
		ddm <= '0';
		dmc <= '0';
		dmre <= '0';
		a <= '1';
		b <= '1';
		
		wait for cycle*10;
		wait for stb;
		reset <= '1';
		
		wait for cycle*10;
		wait for stb;
		xdsd <= '1';
		
		wait for cycle*1500;
		mono <= '0';
		
		wait for cycle*100;
		xdsd <= '0';
		
		wait for cycle*900;
		xdsd <= '1';

		wait for cycle*300;
		xdsd <= '0';

		wait for cycle*680;
		xdsd <= '1';

		wait for cycle*1500;
		xdsd <= '0';
		
		wait;
	end PROCESS;
end rgctrak449_test_bench;

CONFIGURATION cfg_test of rgctrak449_test IS
	for rgctrak449_test_bench
	end for;
end cfg_test;