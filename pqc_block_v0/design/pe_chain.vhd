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

            a_wire(0),
            a_sel_wire(0),
            B(0),

            a_sel_wire(1),
            a_wire(1),
            c_wire(0)
        );

--------------------------------------------------------------------------------------------------------------------------

--  Logic to create all processing elements between PE(0) and PE(N-1)

    PE_I_GEN : for i in 1 to COLS-2 generate

        type reg_link_i_wire is array (0 to i) of std_logic_vector(7 downto 0);
        signal reg_link_i   : reg_link_i_wire := (others=>(others=>'0'));

    begin

    --  Assign B(i) input to first element of reg_link_i (Which connects q of one register to d of next register) 

        reg_link_i(0) <= B(i);

    --  For PE(i) create a chain of i-number registers to create an i-cycle delay
    --  Example: When generating PE(2), generate chain of 2 registers to create a 2-cycle delay

        REG_FEED_GEN_I : for j in 0 to i-1 generate
            REG_8 : entity work.reg_8bit(rtl)
                port map(
                    clk,
                    rst,
                    ena,

                    reg_link_i(j),

                    reg_link_i(j+1)
                );
        end generate REG_FEED_GEN_I;

        PE : entity work.processing_element_i(rtl)
            port map(
                clk,
                rst,
                ena,

                a_wire(i),
                a_sel_wire(i),
                reg_link_i(i),
                c_wire(i-1),

                a_sel_wire(i+1),
                a_wire(i+1),
                c_wire(i)
            );
    end generate PE_I_GEN;

--------------------------------------------------------------------------------------------------------------------------

--  Logic to create last procesing element

    PE_N_GEN : for i in 1 to 1 generate

        type reg_link_n_wire is array (0 to COLS-1) of std_logic_vector(7 downto 0);
        signal reg_link_n   : reg_link_n_wire := (others=>(others=>'0'));

    begin

    --  Assign last B input to first element of reg_link_n (which connects q of one register to d of next register)

        reg_link_n(0) <= B(COLS-1);

    --  For PE(N-1) create a chain of N-1-number registers to create a N-1-cycle delay
    --  Example: For N=16, when generating PE(15), generate chain of 15 registers to create a 15-cycle delay

        REG_FEED_GEN_N : for j in 0 to COLS-2 generate
            REG_8 : entity work.reg_8bit(rtl)
                port map(
                    clk,
                    rst,
                    ena,

                    reg_link_n(j),

                    reg_link_n(j+1)
                );
        end generate REG_FEED_GEN_N;

    --  NOTE: a_sel not necessary as an input because this is the final PE and therefore a_vector does not need to be
    --  rotated to be passed to a proceeding PE

        PE_N :   entity work.processing_element_n(rtl)
            port map(
                clk,
                rst,
                ena,

                a_wire(COLS-1),
                reg_link_n(COLS-1),
                c_wire(COLS-2),

                c_wire(COLS-1)
            );

    end generate PE_N_GEN;

--  Assign output of final register to output of the pe_chain

    C_out <= c_wire(COLS-1);

--------------------------------------------------------------------------------------------------------------------------

end rtl;