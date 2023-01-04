--------------------------------------------------------------------------------------------------------------------------
--  Project : pqc_block
--  File    : shift_an.vhd
--  Author  : Sam Coulon
--  Purpose : The purpose of this file is to...
--            1) Accept an a_vector and jump ahead in circulant matrix for pipelining purposes
--            2) Example) When COLS=4, a_in=A0, then a_out=A4
--------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.globals_pkg.all;

entity shift_an is
    port(
        a_sel       : in    std_logic_vector(COUNTER_SIZE_A_SEL-1 downto 0);
        a_in        : in    a_vector;

        a_out       : out   a_vector
    );
end entity;

architecture rtl of shift_an is

    signal a_wire : a_array;
    signal a_nxt  : a_vector;

begin

    -- Create shift chain to generate AN
    SHIFT0 : entity work.signed_shift_dynamic(rtl)
        port map(
            a_sel,
            a_in,
            a_wire(0)
        );
    A_SHIFT_GEN : for i in 0 to COLS-2 generate
        SHIFT : entity work.signed_shift_dynamic(rtl)
            port map(
                a_sel,
                a_wire(i),
                a_wire(i+1)
            );
    end generate A_SHIFT_GEN;

    a_out <= a_wire(COLS-1);

end rtl;