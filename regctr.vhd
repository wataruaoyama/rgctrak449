Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY regctr IS
PORT(
		RESET : IN std_logic;
		CLK : IN std_logic;
		CLK_MSEC : IN std_logic;
		XDSD : IN std_logic;
		DIF0 : IN std_logic;
		DIF1 : IN std_logic;
		DIF2 : IN std_logic;
		SMUTE : IN std_logic;
		DEM0 : IN std_logic;
		DEM1 : IN std_logic;
		DZFM : IN std_logic;
		DZFE : IN std_logic;
		SD : IN std_logic;
		SLOW : IN std_logic;
		MONO : IN std_logic;
		DSDSEL0 : IN std_logic;
		DSDSEL1 : IN std_logic;
		SSLOW : IN std_logic;
		DSDD : IN std_logic;
		SC0 : IN std_logic;
		SC1 : IN std_logic;
		AK4490 : IN std_logic;
		ATTCOUNT : IN std_logic_vector(7 downto 0);
		CSN : OUT std_logic;
		CCLK : OUT std_logic;
		CDTI : OUT std_logic);
END regctr;

ARCHITECTURE RTL OF regctr IS


signal icclk,d_csn,cen,edge_timer,rstn,ddp,delay_clk_msec : std_logic;
signal attenup,attendwn,endivclk,enatt3rddig,enatt4thdig,regaddrcnt_en : std_logic;
signal dcounter_sys5,icsn,rstdp,chipaddr,sellr,vlmbp : std_logic;
SIGNAL counter_sys : std_logic_vector(10 downto 0);
signal delay,detswdwn,detswup : std_logic_vector(1 downto 0);
signal regaddrcnt : std_logic_vector(3 downto 0);
signal regd : std_logic_vector(7 downto 0);
signal siftreg : std_logic_vector(15 downto 0);

type states IS ( clear,count1,count2);
signal present_state: states;
signal next_state: states;

BEGIN

CCLK <= icclk;
CSN <= icsn;

--Generate CSN
process(RESET,CLK) BEGIN
	if(RESET = '0') then
		counter_sys <= "01111111111";
	elsif(CLK'event and CLK='1') then
		if(cen = '1') then
			if(AK4490 = '1') then	-- AK4490/95
				if(MONO = '0' and counter_sys = "01001100000") then	-- Stereo mode
					counter_sys <= counter_sys;
				elsif(MONO = '1' and counter_sys = "10011100000") then	-- Mono mode
					counter_sys <= counter_sys;
				else
					counter_sys <= counter_sys + '1';
				end if;
			else	-- AK4497
				if(MONO = '0' and counter_sys = "01111100000") then	-- Stereo mode
					counter_sys <= counter_sys;
				elsif(MONO = '1' and counter_sys = "11111100000") then	-- Mono mode
					counter_sys <= counter_sys;
				else
					counter_sys <= counter_sys + '1';
				end if;
			end if;
		else
			counter_sys <= "11111111111";
		end if;
	end if;
end process;

process(RESET,CLK) begin
	if(RESET = '0') then
		dcounter_sys5 <= '1';
	elsif(CLK'event and CLK = '1') then
		dcounter_sys5 <= counter_sys(5);
	end if;
end process;

icsn <= counter_sys(5) and dcounter_sys5;

--Generate ICCLK
process(RESET,CLK) begin
	if(RESET = '0') then
		icclk <= '1';
	elsif(CLK'event and CLK='1') then
		if(cen = '1' and counter_sys(5) = '0') then
			icclk <= not icclk;
		else
			icclk <= '1';
		end if;
	end if;
end process;

process(CLK) begin
	if(CLK'event and CLK='1') then
		delay(1) <= delay(0);
		delay(0) <= XDSD;
	end if;
end process;

ddp <= delay(1) xor delay(0);

process(CLK) begin
	if(CLK'event and CLK='1') then
		delay_clk_msec <= clk_msec;
	end if;
end process;

edge_timer <= clk_msec and not delay_clk_msec;

--State machime to generate count enable signal for counter_sys
process(CLK,RESET) begin
	if (RESET = '0') then
		present_state <= clear;
	elsif (CLK'event and CLK = '1') then
		present_state <= next_state;
	end if;
end process;

process(present_state,ddp,delay_clk_msec,counter_sys,edge_timer,AK4490,MONO) begin

	case present_state is
		when clear => 
			cen <= '0';
			rstn <= '1';
			if(ddp = '1' and delay_clk_msec = '1') then
				next_state <= count1;
			elsif(ddp = '0' and edge_timer = '1') then
				next_state <= count2;
			elsif(ddp = '1' and edge_timer = '0') then
				next_state <= count1;
			else
				next_state <= present_state;
			end if;
		when count1 => 
			cen <= '1';
			rstn <= '0';
			if(AK4490 = '1') then	--AK4490/95
				if(MONO = '0' and counter_sys ="01001100000") then	--CLK*2*32*10-32=608
					next_state <= clear;
				elsif(MONO = '1' and counter_sys = "10011100000") then	--608*2
					next_state <= clear;
				else
					next_state <= present_state;
				end if;
			else	--AK4497
				if(MONO = '0' and counter_sys = "01111100000") then	--CLK*2*32*16-32=992
					next_state <= clear;
				elsif(MONO = '1' and counter_sys = "11111100000") then	--992*2
					next_state <= clear;
				else
					next_state <= present_state;
				end if;
			end if;
		when count2 =>
			cen <= '1';
			rstn <= '1';
			if(AK4490 = '1') then
				if(MONO = '0' and counter_sys = "01001100000") then
					next_state <= clear;
				elsif(MONO = '1' and counter_sys = "10011100000") then
					next_state <= clear;
				else
					next_state <= present_state;
				end if;
			else
				if(MONO = '0' and counter_sys = "01111100000") then
					next_state <= clear;
				elsif(MONO = '1' and counter_sys = "11111100000") then
					next_state <= clear;
				else
					next_state <= present_state;
				end if;
			end if;
	end case;
end process;

process(regaddrcnt,rstn) begin
	if(regaddrcnt = "0000") then
		rstdp <= rstn;
	else
		rstdp <= '1';
	end if;
end process;

--Resister address counter enable signal
Process(counter_sys(5 downto 0),MONO) begin
--	if(MONO = '0') then
		if(counter_sys(5 downto 0) = "100000") then
			regaddrcnt_en <= '1';
		else
			regaddrcnt_en <= '0';
		end if;
--	elsif(MONO = '1') then
--		if(counter_sys(5 downto 0) = "100000") then
--			regaddrcnt_en <= '1';
--		else
--			regaddrcnt_en <= '0';
--		end if;
--	end if;
end process;

--Resister address counter
process(RESET,CLK) begin
	if(RESET = '0') then
		regaddrcnt <= "0000";
	elsif(CLK'event and CLK = '1') then
		if(regaddrcnt_en = '1' and cen = '1') then
			if(AK4490 = '1' and regaddrcnt = "1001") then	--AK4490/95
				regaddrcnt <= "0000";
			elsif(AK4490 = '0' and regaddrcnt = "1111") then	--AK4497
				regaddrcnt <= "0000";
			else
				regaddrcnt <= regaddrcnt + '1';
			end if;
		else
			regaddrcnt <= regaddrcnt;
		end if;
	end if;
end process;

-- channel select for MONO mode
process (chipaddr) begin
	if(chipaddr = '0') then
		sellr <= '0';	-- Device 0 is L channel
	else
		sellr <= '1';	-- Device 1 is R channel
	end if;
end process;

process (XDSD,DSDD) begin
	if(XDSD = '1') then
		vlmbp <= '0';
	else
		vlmbp <= DSDD;
	end if;
end process;
			
--Select external jumper status
process(regaddrcnt,DIF2,DIF1,DIF0,rstdp,DZFE,DZFM,SD,DEM1,DEM0,SMUTE,
		XDSD,MONO,sellr,SLOW,ATTCOUNT,SSLOW,DSDD,DSDSEL0,SC0,SC1,DSDSEL1,vlmbp) begin
	if(regaddrcnt = "0000") then
		regd(7) <= '1';	--ACKS ;Auto mode
		regd(6) <= '0';	--EXDF
		regd(5) <= '0';	--ECS
		regd(4) <= '0';
		regd(3) <= DIF2;	--DIF2
		regd(2) <= DIF1;	--DIF1
		regd(1) <= DIF0;	--DIF0
		regd(0) <= rstdp;	--RSTN
	elsif(regaddrcnt = "0001") then
		regd(7) <= DZFE;	--DZFE
		regd(6) <= DZFM;	--DZFM
		regd(5) <= SD;		--SD
		regd(4) <= '0';	--DFS1
		regd(3) <= '1';	--DFS0
		regd(2) <= DEM1;	--DEM1 ;Default off '0'
		regd(1) <= DEM0;	--DEM0 ;Default off '1'
		regd(0) <= SMUTE;	--SMUTE
	elsif(regaddrcnt = "0010") then
		regd(7) <= not XDSD;	--DP
		regd(6) <= '0';
		regd(5) <= '0';		--DCKS
		regd(4) <= '0';		--DCKB
		regd(3) <= MONO;		--MONO
		regd(2) <= '0';		--DZFB
		regd(1) <= sellr;		--SELLR
		regd(0) <= SLOW;		--SLOW
	elsif(regaddrcnt = "0011") then
		regd <= ATTCOUNT;	--ATT(7:0)
	elsif(regaddrcnt = "0100") then
		regd <= ATTCOUNT;	--ATT(7:0)
	elsif(regaddrcnt = "0101") then
		regd(7) <= MONO;	--INVL
		regd(6) <= '0';	--INVR
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '1';	--DFS2
		regd(0) <= SSLOW;	--SSLOW
	elsif(regaddrcnt = "0110") then
		regd(7) <= '1';--DDM;		--DDM  Change "0" to "1" at Revision 1.1
		regd(6) <= '0';		--DML
		regd(5) <= '0';		--DMR
		regd(4) <= '0';		--DMC
		regd(3) <= '0';		--DMRE
		regd(2) <= '0';
		regd(1) <= vlmbp;		--DSDD
		regd(0) <= DSDSEL0;	--DSDSEL0
	elsif(regaddrcnt = "0111") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';	--SYNCE
	elsif(regaddrcnt = "1000") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';	--HLOAD at ak4497
		regd(2) <= '0';	--SC2 at ak4495/97
		regd(1) <= SC1;	--SC1
		regd(0) <= SC0;	--SC0
	elsif(regaddrcnt = "1001") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';		--DSDPATH at ak4497
		regd(1) <= '1';		--DSDF
		regd(0) <= DSDSEL1;	--DSDSEL1
-- From resister address "0AH" to "15H" is about for ak4497
-- Added in the revision 1.2
		elsif(regaddrcnt = "1010") then
		regd(7) <= '0';	--TDM1
		regd(6) <= '0';	--TDM0
		regd(5) <= '0';	--SDS1
		regd(4) <= '0';	--SDS2
		regd(3) <= '0';
		regd(2) <= '1';	--PW
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = "1011") then
		regd(7) <= '0';	--ATS1
		regd(6) <= '0';	--ATS0
		regd(5) <= '0';
		regd(4) <= '0';	--SDS0
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '1';	--DCHAIN
		regd(0) <= '0';	--TEST
	elsif(regaddrcnt = "1100") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = "1101") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = "1110") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = "1111") then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';	--ADFS2
		regd(1) <= '0';	--ADFS1
		regd(0) <= '0';	--ADFS0
		else
--		regd <= regd;
		regd <= "11111111";
	end if;
end process;

process(RESET,CLK) begin
	if(RESET = '0') then
		chipaddr <= '0';
	elsif(CLK'event and CLK = '1') then
		if(cen = '1') then
			if(AK4490 = '1' and counter_sys ="01001100000") then
				chipaddr <= '1';
			elsif(AK4490 ='0' and counter_sys = "01111100000") then
				chipaddr <= '1';
			else
				chipaddr <= chipaddr;
			end if;
		else
			chipaddr <= '0';
		end if;
	end if;
end process;

--Parallel to serial convetor to generate CDTI
process(RESET,CLK) begin
	if(RESET = '0') then
		siftreg <= "1111111111111111";
	elsif(CLK'event and CLK = '1') then
		if(counter_sys(5) = '1') then
			siftreg(15) <= chipaddr;
			siftreg(14) <= '0';
			siftreg(13) <= '1';
			siftreg(12) <= '0';
			siftreg(11) <= regaddrcnt(3);
			siftreg(10) <= regaddrcnt(2);
			siftreg(9) <= regaddrcnt(1);
			siftreg(8) <= regaddrcnt(0);
			siftreg(7) <= regd(7);
			siftreg(6) <= regd(6);
			siftreg(5) <= regd(5);
			siftreg(4) <= regd(4);
			siftreg(3) <= regd(3);
			siftreg(2) <= regd(2);
			siftreg(1) <= regd(1);
			siftreg(0) <= regd(0);
		else
			if(icclk = '1') then
				siftreg(1) <= siftreg(0);
				siftreg(2) <= siftreg(1);
				siftreg(3) <= siftreg(2);
				siftreg(4) <= siftreg(3);
				siftreg(5) <= siftreg(4);
				siftreg(6) <= siftreg(5);
				siftreg(7) <= siftreg(6);
				siftreg(8) <= siftreg(7);
				siftreg(9) <= siftreg(8);
				siftreg(10) <= siftreg(9);
				siftreg(11) <= siftreg(10);
				siftreg(12) <= siftreg(11);
				siftreg(13) <= siftreg(12);
				siftreg(14) <= siftreg(13);
				siftreg(15) <= siftreg(14);
				CDTI <= siftreg(15);
			else
				siftreg <= siftreg;
			end if;
		end if;
	end if;
end process;

end RTL;