--------------------------------------------------------------------------------------------------------------------------
--  Project : pqc_block
--  File    : reg_c_sec.vhd
--  Author  : Sam Coulon
--  Purpose : The purpose of this file is to...
--            1) Accept and register c_section values (ROWS*8-bit values)
--------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.globals_pkg.all;

entity reg_c_sec is
    port (
        clk : in    std_logic;
        rst : in    std_logic;
        ena : in    std_logic;
        
        d   : in    c_section;

        q   : out   c_section
    );
end entity;

architecture rtl of reg_c_sec is 
begin
    process(clk)
	begin
        if (rst = '1') then
            q <= (others=>(others=>'0'));
		else		
			if (rising_edge(clk) and ena = '1') then             
		  		q <= d;		 
            end if;
	  	end if;
	end process;
end rtl;