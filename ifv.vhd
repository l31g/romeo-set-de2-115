--------------------------------------------------------------------
-- DE2 top-level module for the IFV
--
-- Nathan Hwang, Richard Nwaobasi, Luis E. P. & Stephen Pratt
--
-- From an original by Terasic Technology, Inc.
-- (DE2_TOP.v, part of the DE2 system board CD supplied by Altera)
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ifv is

	port (
	CLOCK_50	: in std_logic;                    -- 50 MHz

	-- LED displays
	HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 -- 7-segment displays
	: out std_logic_vector(6 downto 0);
	LEDG : out std_logic_vector(8 downto 0);       -- Green LEDs

	-- SDRAM
	DRAM_DQ : inout std_logic_vector(15 downto 0); -- Data Bus
	DRAM_ADDR : out std_logic_vector(11 downto 0); -- Address Bus    
	DRAM_LDQM,                                     -- Low-byte Data Mask 
	DRAM_UDQM,                                     -- High-byte Data Mask
	DRAM_WE_N,                                     -- Write Enable
	DRAM_CAS_N,                                    -- Column Address Strobe
	DRAM_RAS_N,                                    -- Row Address Strobe
	DRAM_CS_N,                                     -- Chip Select
	DRAM_BA_0,                                     -- Bank Address 0
	DRAM_BA_1,                                     -- Bank Address 0
	DRAM_CLK,                                      -- Clock
	DRAM_CKE : out std_logic;                      -- Clock Enable

	-- SRAM   
	SRAM_DQ : inout std_logic_vector(15 downto 0); -- Data bus 16 Bits
	SRAM_ADDR : out std_logic_vector(17 downto 0); -- Address bus 18 Bits
	SRAM_UB_N,                                     -- High-byte Data Mask 
	SRAM_LB_N,                                     -- Low-byte Data Mask 
	SRAM_WE_N,                                     -- Write Enable
	SRAM_CE_N,                                     -- Chip Enable
	SRAM_OE_N : out std_logic;                     -- Output Enable	

	-- PS/2 port
	PS2_DAT,                    -- Data
	PS2_CLK : inout std_logic;     -- Clock

	-- VGA output
	VGA_CLK,                                            -- Clock
	VGA_HS,                                             -- H_SYNC
	VGA_VS,                                             -- V_SYNC
	VGA_BLANK,                                          -- BLANK
	VGA_SYNC : out std_logic;                           -- SYNC
	VGA_R,                                              -- Red[9:0]
	VGA_G,                                              -- Green[9:0]
	VGA_B : out unsigned(9 downto 0)                   -- Blue[9:0]
);
  
end ifv;

architecture datapath of ifv is

	signal clk_25			: std_logic;
	signal clk_50			: std_logic;
	signal clk_sdram		: std_logic;

	signal cread			: unsigned(7 downto 0);
	signal xread			: unsigned(9 downto 0);
	signal yread			: unsigned(8 downto 0);
	signal re				: std_logic;
	signal we				: std_logic;
	signal cwrite			: unsigned(7 downto 0);
	signal xwrite			: unsigned(9 downto 0);
	signal ywrite			: unsigned(8 downto 0);

	signal a_min			: signed(35 downto 0)		:= X"F80000000";
	signal b_min			: signed(35 downto 0)		:= X"FA0000000";
	signal a_diff			: signed(35 downto 0)		:= X"000666666";
	signal b_diff			: signed(35 downto 0)		:= X"000666666";
	signal cr   			: signed(35 downto 0)		:= X"FCA8F5C29";
	signal ci   			: signed(35 downto 0)		:= X"FF125460B";
	signal a_leap			: unsigned(9 downto 0)		:= "0000000010";
	signal b_leap			: unsigned(9 downto 0)		:= "0000000010";
	signal reset_n			: std_logic							:='1';

	signal a_mine			: signed(35 downto 0)		;
	signal b_mine			: signed(35 downto 0)		;
	signal a_diffe			: signed(35 downto 0)		;
	signal b_diffe			: signed(35 downto 0)		;
	signal cre   			: signed(35 downto 0)		;
	signal cie   			: signed(35 downto 0)		;
	signal a_leape			: unsigned(9 downto 0)		;
	signal b_leape			: unsigned(9 downto 0)		;

	signal DRAM_BA			: std_logic_vector(1 downto 0);
	signal DRAM_DQM			: std_logic_vector(1 downto 0);

	signal ram_read			: std_logic;
	signal ram_data			: signed(17 downto 0);
	signal ram_address		: unsigned(3 downto 0);
	signal ram_addr			: unsigned(3 downto 0);

	signal iterate			: std_logic;
	signal reset			: std_logic;
	signal color			: std_logic_vector(2 downto 0);
	signal refresh			: std_logic;
	signal fract			: std_logic_vector(1 downto 0);
	signal sig				: std_logic_vector(7 downto 0);
	begin

	reset					<= sig(0);
	iterate					<= sig(1);
	color					<= sig(4 downto 2);
	refresh					<= sig(5);
	fract					<= sig(7 downto 6);
	LEDG(7 downto 0)		<= sig;

	process (clk_25)
	begin
		if rising_edge(clk_25) then

			if fract = "00" then
				a_min		<= a_mine;
				b_min		<= b_mine;
				a_diff		<= a_diffe;
				b_diff		<= b_diffe;
				cr			<= cre;
				ci			<= cie;
				a_leap		<= a_leape;
				b_leap		<= b_leape;
			elsif fract = "01" then
				a_min		<= X"F80000000";
				b_min		<= X"FA0000000";
				a_diff		<= X"000666666";
				b_diff		<= X"000666666";
				cr			<= X"000000000";
				ci			<= X"000000000";
				a_leap		<= "0000000010";
				b_leap		<= "0000000010";
			elsif fract = "10" then
				a_min		<= X"F80000000";
				b_min		<= X"FA0000000";
				a_diff		<= X"000666666";
				b_diff		<= X"000666666";
				cr			<= X"FCA8F5C29";
				ci			<= X"FF125460B";
				a_leap		<= "0000000010";
				b_leap		<= "0000000010";
			else
				a_min		<= X"F80000000";
				b_min		<= X"FA0000000";
				a_diff		<= X"000666666";
				b_diff		<= X"000666666";
				cr			<= X"FCA8F5C29";
				ci			<= X"FFF25460B";
				a_leap		<= "0000000010";
				b_leap		<= "0000000010";
			end if;
		end if;
	end process;

	VGA_CLK   <= clk_25;
	DRAM_BA_1 <= DRAM_BA(1);
	DRAM_BA_0 <= DRAM_BA(0);
	DRAM_UDQM <= DRAM_DQM(1);
	DRAM_LDQM <= DRAM_DQM(0);
	DRAM_CLK  <= clk_sdram;

CLK5025: entity work.pll5025 port map(
	inclk0	=> CLOCK_50,
	c0		=> clk_50,
	c1		=> clk_25,
	c2		=> clk_sdram
	);

IFM: entity work.hook port map(
	clk25		=> clk_25,
	reset		=> reset,
	a_min		=> a_min,
	a_diff		=> a_diff,
	a_leap		=> a_leap,
	b_min		=> b_min,
	b_diff		=> b_diff,
	b_leap		=> b_leap,
	cr			=> cr,
	ci			=> ci,
	std_logic_vector(xout)		=> xwrite,
	std_logic_vector(yout)		=> ywrite,
	count		=> cwrite,
	we			=> we
	);

NIOS: entity work.nios port map (
 -- 1) global signals:
	clk								=> clk_50,
	clk_25							=> clk_25,
	reset_n							=> '1',

	PS2_CLK_to_and_from_the_ps2_0	=> PS2_CLK,
	PS2_DAT_to_and_from_the_ps2_0	=> PS2_DAT,
	irq_from_the_ps2_0				=> LEDG(8),

 -- the_ram
	addressout_to_the_ram			=> std_logic_vector(ram_address),
	read_to_the_ram					=> ram_read,
	std_logic_vector(readdata_from_the_ram)		=> ram_data,
	std_logic_vector(readaddr_from_the_ram)		=> ram_addr,
	
 -- the sram signal
	read_addr_to_the_ram_signal		=> '0',
	read_data_from_the_ram_signal 	=> sig,

 -- the_sdram
	zs_addr_from_the_sdram		=> DRAM_ADDR,
	zs_ba_from_the_sdram		=> DRAM_BA,
	zs_cas_n_from_the_sdram		=> DRAM_CAS_N,
	zs_cke_from_the_sdram		=> DRAM_CKE,
	zs_cs_n_from_the_sdram		=> DRAM_CS_N,
	zs_dq_to_and_from_the_sdram	=> DRAM_DQ,
	zs_dqm_from_the_sdram		=> DRAM_DQM,
	zs_ras_n_from_the_sdram		=> DRAM_RAS_N,
	zs_we_n_from_the_sdram		=> DRAM_WE_N
 );

RMR: entity work.rammer port map(
	clk				=> clk_25,
	compute			=> refresh,
	read			=> ram_read,
	addressout		=> ram_address,
	addressin		=> ram_addr,
	readdata		=> ram_data,
	amin			=> a_mine,
	bmin			=> b_mine,
	adiff			=> a_diffe,
	bdiff			=> b_diffe,
	aleap			=> a_leape,
	bleap			=> b_leape,
	cro				=> cre,
	cio				=> cie
	);

VGA: entity work.vga_mod port map (
	clk			=> clk_25,
	reset		=> '0',
	switch		=> color,
	count		=> cread,--EXTERNAL SIGNALS
	VGA_HS		=> VGA_HS,
	VGA_VS		=> VGA_VS,
	VGA_BLANK	=> VGA_BLANK,
	VGA_SYNC	=> VGA_SYNC,
	VGA_R		=> VGA_R,
	VGA_G		=> VGA_G,
	VGA_B		=> VGA_B,
	xout		=> xread,--EXTERNAL SIGNALS
	yout		=> yread,--EXTERNAL SIGNALS
	re  		=> re,--EXTERNAL SIGNALS
	ce  		=> iterate
	);

SRAM: entity work.sram port map(
	sram_data	=> SRAM_DQ,
	sram_addr	=> SRAM_ADDR,
	sram_ub_n	=> SRAM_UB_N,
	sram_lb_n	=> SRAM_LB_N,
	sram_we_n	=> SRAM_WE_N,
	sram_ce_n	=> SRAM_CE_N,
	sram_oe_n	=> SRAM_OE_N,
	rx			=> std_logic_vector(xread),
	ry			=> std_logic_vector(yread),
	wx			=> std_logic_vector(xwrite),
	wy			=> std_logic_vector(ywrite),
	std_logic_vector(rv)	=> cread,
	wv			=> std_logic_vector(cwrite),
	re			=> re,
	we			=> we
	);
  
	HEX7     <= "1100001"; -- J
	HEX6     <= "1000001"; -- U
	HEX5     <= "1000111"; -- L
	HEX4     <= "1111001"; -- I
	HEX3     <= "0001000"; -- A
	HEX2     <= "0010010"; -- S
	HEX1     <= "0000110"; -- E
	HEX0     <= "0000111"; -- t
end datapath;
