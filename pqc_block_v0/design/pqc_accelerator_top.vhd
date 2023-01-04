--------------------------------------------------------------------------------------------------------------------------
--  Project : pqc_block
--  File    : pqc_accelerator_top.vhd
--  Author  : Sam Coulon
--  Purpose : The purpose of this file is to...
--            1) Serve as top level of design for instantiation in Quartus for on-board testing
--            2) Instantiate and link together all lower level components
--------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.globals_pkg.all;

entity pqc_accelerator_top is
    port(
        clk     : in    std_logic;
        rst     : in    std_logic;
        ena     : in    std_logic;
        mode    : in    std_logic;

        A_in    : in    std_logic;
        B_in    : in    std_logic_vector(7 downto 0);
        Z_in    : in    std_logic;

        W_out   : out   std_logic_vector(7 downto 0);
        EN_out  : out   std_logic_vector(7 downto 0);
        DE_out  : out   std_logic;

        ab_val_index    : out   std_logic_vector(7 downto 0);
        z_val_index     : out   std_logic_vector(7 downto 0);
        w_val_index     : out   std_logic_vector(7 downto 0);

        save_ena        : out   std_logic
    );
end entity;

architecture rtl of pqc_accelerator_top is

    signal a_sel        : std_logic_vector(COUNTER_SIZE_A_SEL-1 downto 0);

    signal a_dsi2pe     : a_vector; 
    signal b_dsi2pe     : b_section;

    signal c_pe2accum   : c_section;
    signal c_accum2dso  : c_section;

    signal dsi_ena      : std_logic;
    signal pe_ena       : std_logic;
    signal accum_ena    : std_logic;
    signal dso_ena      : std_logic;
    signal err_ena      : std_logic;
    signal out_ena      : std_logic;

    signal dso_count    : std_logic_vector(COUNTER_SIZE_B downto 0);
    signal C_out        : std_logic_vector(7 downto 0);

begin

    FSM : entity work.control_unit(rtl)
        port map(
            clk,
            rst,
            ena,
            mode,

            dso_count,

            a_sel,

            dsi_ena,
            pe_ena,
            accum_ena,
            dso_ena,
            err_ena,
            out_ena,

            ab_val_index,
            z_val_index,
            w_val_index
        );

    save_ena <= out_ena;

    -- Shift in a & b values
    -- Rotate a & b values as needed by pe_chain
    DSI : entity work.data_shift_in(rtl)
        port map(
            clk,
            rst,
            dsi_ena,
            pe_ena,

            a_sel,
            A_in,
            B_in,

            a_dsi2pe,
            b_dsi2pe
        );

    -- Pipeline processing, A x B = C
    PE_CHAIN : entity work.pe_chain(rtl)
        port map(
            clk,
            rst,
            pe_ena,

            a_sel,
            a_dsi2pe,
            b_dsi2pe,

            c_pe2accum
        );

    -- For given rows in processing, accumulate results until section complete
    PE_ACCUM : entity work.pe_accum(rtl)
        port map(
            clk,
            rst,
            accum_ena,

            c_pe2accum,
            c_accum2dso
        );

    -- Shift out c values
    DSO : entity work.data_shift_out(rtl)
        port map(
            clk,
            rst,
            dso_ena,

            dso_count,

            c_accum2dso,
            C_out
        );
    
    -- Append z & e error values to c values
    -- Output W, EN, and DE
    ERR : entity work.add_error(rtl)
        port map(
            clk,
            rst,
            err_ena,
            out_ena,

            C_out,
            Z_in,

            W_out,
            EN_out,
            DE_out
        );

end architecture;