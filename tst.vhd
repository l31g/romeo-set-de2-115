--------------------------------------------------------------------
--TEST
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tst is

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
  
end tst;

architecture datapath of tst is

	signal sig				: unsigned(31 downto 0);
	
	begin

	LEDG(7 downto 0)		<= std_logic_vector(sig(31 downto 24));

	process (CLOCK_50)
	begin
		if rising_edge(CLOCK_50) then
			if sig = x"fffffff" then
			sig <= (others => '0');
			else
			sig <= sig + 1;
			end if;
		end if;
	end process;

	HEX7     <= "1100001"; -- J
	HEX6     <= "1000001"; -- U
	HEX5     <= "1000111"; -- L
	HEX4     <= "1111001"; -- I
	HEX3     <= "0001000"; -- A
	HEX2     <= "0010010"; -- S
	HEX1     <= "0000110"; -- E
	HEX0     <= "0000111"; -- t
end datapath;
