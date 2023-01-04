--------------------------------------------------------------------------------------------------------------------------
--  Project : pqc_block
--  File    : pe_chain.vhd
--  Author  : Sam Coulon
--  Purpose : The purpose of this file is to...
--            1) Serve as top level for the processing element pipeline
--            2) Instantiate and link together all processing elements
--            3) Instantiate and link together delay register chains for each PE
--------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.globals_pkg.all;

entity pe_chain is
    port(
        clk     : in    std_logic;
        rst     : in    std_logic;
        ena     : in    std_logic;

        a_sel   : in    std_logic_vector(COUNTER_SIZE_A_SEL-1 downto 0);
        A       : in    a_vector;
        B       : in    b_section;

        C_out   : out   c_section
    );
end entity;

architecture rtl of pe_chain is

    type a_sel_array is array (0 to COLS-1) of std_logic_vector(COUNTER_SIZE_A_SEL-1 downto 0);
    type a_array is array (0 to COLS-1) of a_vector;
    type c_array is array (0 to COLS-1) of c_section;

    -- "wire" denotes array structure that links values between PEs
    signal a_sel_wire   : a_sel_array; 
    signal a_wire       : a_array;
    signal c_wire       : c_array;

begin

--------------------------------------------------------------------------------------------------------------------------

--  Logic to create initial processing element
--  Assign A input to first elemnt of a_wire (which connects A_out of one PE to A_in of next PE)
--  Assign a_sel input to first elemnt of a_sel_wire (which connects a_sel_out of one PE to a_sel_in of next PE)

    a_wire(0) <= A;
    a_sel_wire(0) <= a_sel;

--  NOTE: C_in not necessary because this is the first PE, and therefore there are no prior c values to accumulate

    PE_0 :   entity work.processing_element_0(rtl)
        port map(
            clk,
            rst,
            ena,

            a_sel_wire(0),
            a_wire(0),
            B(0),

            a_sel_wire(1),
            a_wire(1),
            c_wire(0)
        );

--------------------------------------------------------------------------------------------------------------------------

--  Logic to create all processing elements between PE(0) and PE(N-1)

    PE_I_GEN_GATE : if COLS > 3 generate
        PE_I_GEN : for i in 1 to COLS-3 generate

            PE : entity work.processing_element_i(rtl)
                port map(
                    clk,
                    rst,
                    ena,

                    a_sel_wire(i),
                    a_wire(i),
                    B(i),
                    c_wire(i-1),

                    a_sel_wire(i+1),
                    a_wire(i+1),
                    c_wire(i)
                );

        end generate PE_I_GEN;
    end generate PE_I_GEN_GATE;

--------------------------------------------------------------------------------------------------------------------------

--  Logic to create second to last (n-2) processing element
    PE_N_2_GEN_GATE : if COLS > 2 generate

    --  NOTE: a_sel not necessary as an output because in the final PE a_vector does not need to be
    --  rotated to be passed to a proceeding PE

        PE_N_2 :   entity work.processing_element_n_2(rtl)
            port map(
                clk,
                rst,
                ena,

                a_sel_wire(COLS-2),
                a_wire(COLS-2),
                B(COLS-2),
                c_wire(COLS-3),

                a_wire(COLS-1),
                c_wire(COLS-2)
            );

    end generate PE_N_2_GEN_GATE;

--------------------------------------------------------------------------------------------------------------------------

--  Logic to create last (n-1) procesing element
    PE_N_1_GEN_GATE : if COLS > 1 generate

    --  NOTE: a_sel not necessary as an input because this is the final PE and therefore a_vector does not need to be
    --  rotated to be passed to a proceeding PE

        PE_N_1 :   entity work.processing_element_n_1(rtl)
            port map(
                clk,
                rst,
                ena,

                a_wire(COLS-1),
                B(COLS-1),
                c_wire(COLS-2),

                c_wire(COLS-1)
            );

    end generate PE_N_1_GEN_GATE;

--  Assign output of final register to output of the pe_chain

    C_out <= c_wire(COLS-1);

--------------------------------------------------------------------------------------------------------------------------

end rtl;