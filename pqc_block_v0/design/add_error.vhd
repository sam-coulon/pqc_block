--------------------------------------------------------------------------------------------------------------------------
--  Project : pqc_block
--  File    : add_error.vhd
--  Author  : Sam Coulon
--  Purpose : The purpose of this file is to...
--            1) Accept C_out values
--            2) Add Z (from input) & E (const error) errors
--            3) Register W_out, EN_out, and DE_out
--------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.globals_pkg.all;

entity add_error is
    port(
        clk     : in    std_logic;
        rst     : in    std_logic;
        ena     : in    std_logic;
        show_ena: in    std_logic;

        W       : in    std_logic_vector(7 downto 0);
        Z       : in    std_logic;

        C_out   : out   std_logic_vector(7 downto 0);
        EN_out  : out   std_logic_vector(7 downto 0);
        DE_out  : out   std_logic
    );
end add_error;

architecture rtl of add_error is

    signal sum_z        : std_logic_vector(7 downto 0);
    signal sum_e        : std_logic_vector(7 downto 0);
    signal de_nxt       : std_logic;

    signal c_hold       : std_logic_vector(7 downto 0);
    signal en_hold      : std_logic_vector(7 downto 0);
    signal de_hold      : std_logic;

    signal count        : std_logic_vector(COUNTER_SIZE_B downto 0);
    signal count_nxt    : std_logic_vector(COUNTER_SIZE_B downto 0);

begin

    sum_z <= W + Z;
    sum_e <= sum_z + E;
    de_nxt <= sum_e(0) XOR sum_e(1);

    -- W + Z (8-bit)
    REG_COUT : entity work.reg_8bit(rtl)
        port map(
            clk,
            rst,
            ena,

            sum_z,
            c_hold
        );

    -- W + Z + E (8-bit)
    REG_EN : entity work.reg_8bit(rtl)
        port map(
            clk,
            rst,
            ena,

            sum_e,
            en_hold
        );

    -- sum_e(0) XOR sum_e(1) (1-bit)
    REG_DE : entity work.reg_1bit(rtl)
        port map(
            clk,
            rst,
            ena,

            de_nxt,
            de_hold
        );

    C_out <= c_hold when show_ena = '1' else (others=>'0');
    EN_out <= en_hold when show_ena = '1' else (others=>'0');
    DE_out <= de_hold when show_ena = '1' else '0';

end rtl;