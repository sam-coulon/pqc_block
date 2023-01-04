--------------------------------------------------------------------------------------------------------------------------
--  Project : pqc_block
--  File    : globals_pkg.vhd
--  Author  : Sam Coulon
--  Purpose : The purpose of this file is to...
--            1) Adjust global design constraints (i.e. N_SIZE, ROWS, COLS, and E) which shape the design at compilation
--            2) Establish other global constants to be used at lower levels of the design
--            3) Establish global types to be instantiated at lower levels of the design
--------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.log2;

package globals_pkg is

    -- N_SIZE -> Size of initial A vector 
    constant N_SIZE : integer := 256;
    
    -- ROWS/COLS -> Section size to process (Power of 2)
    constant ROWS   : integer := 64;
    constant COLS   : integer := 4;

    -- E -> CONSTANT ERROR VALUE (8-bit)
    constant E      : integer := 1;

    -- NUM_X_SECTIONS -> Number of sections to be processed
    constant NUM_A_SECTIONS : integer := (N_SIZE*N_SIZE)/(ROWS*COLS);
    constant NUM_B_SECTIONS : integer := (N_SIZE/COLS);

    -- COUNTER_SIZE -> Bit length of counters
    constant COUNTER_SIZE_FSM   : integer := integer(log2(real(N_SIZE)));
    constant COUNTER_SIZE_A     : integer := integer(log2(real(NUM_A_SECTIONS)));
    constant COUNTER_SIZE_B     : integer := integer(log2(real(NUM_B_SECTIONS)));
    constant COUNTER_SIZE_A_SEL : integer := integer(log2(real(N_SIZE)));

    -- "vector" -> 1 signed A column
    type a_vector   is array (0 to N_SIZE-1) of std_logic_vector(1 downto 0);
    type b_vector   is array (0 to N_SIZE-1) of std_logic_vector(7 downto 0);

    -- "section" -> 1 block used for PE operation
    type a_section  is array (0 to ROWS-1) of std_logic_vector(1 downto 0);
    type b_section  is array (0 to COLS-1) of std_logic_vector(7 downto 0);
    type c_section  is array (0 to ROWS-1) of std_logic_vector(7 downto 0);

end package;