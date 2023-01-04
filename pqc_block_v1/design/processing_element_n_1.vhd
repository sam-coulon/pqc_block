--------------------------------------------------------------------------------------------------------------------------
--  Project : pqc_block
--  File    : processing_element_n_1.vhd
--  Author  : Sam Coulon
--  Purpose : The purpose of this file is to...
--            1) Accept a_vector and C_in from previous PE
--            2) Accept B value from register delay chain
--            3) Multiply a_vector(0..ROWS-1) and B value to produce new C value
--            4) Add C_in and new C value to produce C_out
--            5) Register C_out
--------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.globals_pkg.all;

entity processing_element_n_1 is
    port (
        clk     : in    std_logic;
        rst     : in    std_logic;
        ena     : in    std_logic;
        
        A_in    : in    a_vector;
        B_in    : in    std_logic_vector(7 downto 0);
        C_in    : in    c_section;

        C_out   : out   c_section
    );
end entity;

architecture rtl of processing_element_n_1 is

    signal a_col    : a_section;
    signal c_mult   : c_section;
    signal c_sum    : c_section;

begin

    -- Select top ROWS number elements for MULT
    A_COL_GEN : for i in 0 to ROWS-1 generate
        a_col(i) <= A_in(i);
    end generate A_COL_GEN;

    -- Multiply AxB -> c_mult
    MULT :      entity work.multiplier(rtl)
        port map(
            a_col,
            B_in,

            c_mult
        );

    -- Sum AxB + C_in -> c_sum
    SUM : for i in 0 to ROWS-1 generate
        c_sum(i) <= c_mult(i) + C_in(i);
    end generate SUM;

    -- Register C output -> c_out
    REG_C_OUT :   entity work.reg_c_sec(rtl)
        port map(
            clk,
            rst,
            ena,

            c_sum,

            C_out
        );

end rtl;