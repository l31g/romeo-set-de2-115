---------------------------------------------------------------------
--rammer.vhd
--
--This component reads the values to the hook from the RAM where the
--Nios writes the necessary 
--
--Author: Luis E. P.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rammer is
	port(
	clk						: in std_logic;
	compute					: in std_logic;
	read					: out std_logic;
	addressout				: out unsigned(3 downto 0);
	addressin				: in unsigned(3 downto 0);
	readdata				: in signed(17 downto 0);
	amin					: out signed(35 downto 0);
	bmin					: out signed(35 downto 0);
	adiff					: out signed(35 downto 0);
	bdiff					: out signed(35 downto 0);
	aleap					: out unsigned(9 downto 0);
	bleap					: out unsigned(9 downto 0);
	cro						: out signed(35 downto 0);
	cio						: out signed(35 downto 0)
	);
end rammer;

architecture compute of rammer is

	signal a_min			: signed(35 downto 0);
	signal b_min			: signed(35 downto 0);
	signal a_diff			: signed(35 downto 0);
	signal b_diff			: signed(35 downto 0);
	signal a_leap			: unsigned(9 downto 0);
	signal b_leap			: unsigned(9 downto 0);
	signal cr				: signed(35 downto 0);
	signal ci				: signed(35 downto 0);
	signal idx				: unsigned(3 downto 0);
	signal finish			: std_logic			:= '0';

	begin

	addressout		<= idx;
	amin			<= a_min;
	bmin			<= b_min;
	adiff			<= a_diff;
	bdiff			<= b_diff;
	aleap			<= a_leap;
	bleap			<= b_leap;
	cro				<= cr;
	cio				<= ci;
	read			<= compute;

	process(clk)
	begin
		if rising_edge(clk) then
			if compute = '1' and idx /= "1111" then
			case addressin is
				when "0000"		=>	a_min(35 downto 18)	<= readdata;
				when "0001"		=>	a_min(17 downto 0)	<= readdata;
				when "0010"		=>	b_min(35 downto 18)	<= readdata;
				when "0011"		=>	b_min(17 downto 0)	<= readdata;
				when "0100"		=>	a_diff(35 downto 18)<= readdata;
				when "0101"		=>	a_diff(17 downto 0)	<= readdata;
				when "0110"		=>	b_diff(35 downto 18)<= readdata;
				when "0111"		=>	b_diff(17 downto 0)	<= readdata;
				when "1000"		=>	a_leap				<= unsigned(readdata(9 downto 0));
				when "1001"		=>	b_leap				<= unsigned(readdata(9 downto 0));
				when "1010"		=>	cr(35 downto 18)	<= readdata;
				when "1011"		=>	cr(17 downto 0)		<= readdata;
				when "1100"		=>	ci(35 downto 18)	<= readdata;
				when "1101"		=>	ci(17 downto 0)		<= readdata;
				when others		=>	idx					<= idx + 1;
			end case;
			idx <= idx + 1;
			elsif compute = '0' and idx = "1111" then
				idx <= "0000";
			end if;
		end if;
	end process;
end compute;
