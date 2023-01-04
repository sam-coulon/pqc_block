--------------------------------------------------------------------------------------------------------------------------
--  Project : pqc_block
--  File    : control_unit.vhd
--  Author  : Sam Coulon
--  Purpose : The purpose of this file is to...
--            1) Operate state machine and fsm counter to generate general enable signals for all elements of the design
--            2) Determine specific timing for err_ena & out_ena
--            3) Control testing modes (run fsm once or run fsm continuously)
--            4) Determine a_sel (index of a_vector to be inverted when creating circulant matrix)
--            5) Determine x_val_index (indices of input and output registers in Quartus)
--------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.globals_pkg.all;

entity control_unit is
    port ( 
        clk         : in    std_logic;
        rst         : in    std_logic;
        ena         : in    std_logic;
        mode        : in    std_logic;

        dso_count   : in    std_logic_vector(COUNTER_SIZE_B downto 0);

        a_sel_out   : out   std_logic_vector(COUNTER_SIZE_A_SEL-1 downto 0);

        dsi_ena     : out   std_logic;
        pe_ena      : out   std_logic;
        accum_ena   : out   std_logic;
        dso_ena     : out   std_logic;
        err_ena     : out   std_logic;
        out_ena     : out   std_logic;

        ab_val_index_out    : out   std_logic_vector(7 downto 0);
        z_val_index_out     : out   std_logic_vector(7 downto 0);
        w_val_index_out     : out   std_logic_vector(7 downto 0)
    );
end control_unit;

architecture rtl of control_unit is

    type fsm_state is (SETUP, DSI, B_LOAD, PE_PIPE, PE_ACCUM, DSO, ERR, SAVE);
    signal state            : fsm_state := SETUP;
    signal state_nxt        : fsm_state;
    
    signal fsm_count        : std_logic_vector(COUNTER_SIZE_A-1 downto 0);
    signal fsm_count_nxt    : std_logic_vector(COUNTER_SIZE_A-1 downto 0);

    signal run_one          : std_logic;

    signal count_a_sel      : std_logic_vector(COUNTER_SIZE_B-1 downto 0);
    signal count_a_sel_nxt  : std_logic_vector(COUNTER_SIZE_B-1 downto 0);
    signal a_sel            : std_logic_vector(COUNTER_SIZE_A_SEL-1 downto 0);
    signal a_sel_nxt        : std_logic_vector(COUNTER_SIZE_A_SEL-1 downto 0);

    signal dsi_ena_hold     : std_logic;
    signal dso_ena_hold     : std_logic;

    signal err_count        : std_logic_vector(COUNTER_SIZE_B downto 0);
    signal err_count_nxt    : std_logic_vector(COUNTER_SIZE_B downto 0);
    signal err_count_start  : std_logic;
    signal err_incr_ena     : std_logic;

    signal out_count        : std_logic_vector(COUNTER_SIZE_B downto 0);
    signal out_count_nxt    : std_logic_vector(COUNTER_SIZE_B downto 0);
    signal out_count_start  : std_logic;
    signal out_incr_ena     : std_logic;      

    signal ab_val_index      : std_logic_vector(7 downto 0);
    signal ab_val_index_nxt  : std_logic_vector(7 downto 0);
    
    signal z_val_index      : std_logic_vector(7 downto 0);
    signal z_val_index_nxt  : std_logic_vector(7 downto 0);
    signal err_ena_hold     : std_logic;

    signal w_val_index      : std_logic_vector(7 downto 0);
    signal w_val_index_nxt  : std_logic_vector(7 downto 0);
    signal out_ena_hold     : std_logic;

begin

--------------------------------------------------------------------------------------------------------------------------

--  Logic to combinatorially determine next fsm count

    fsm_count_nxt <= fsm_count + '1' when (state = DSI      and fsm_count < N_SIZE-1)
                                       or (state = PE_PIPE  and fsm_count < COLS-1)
                                       or (state = PE_ACCUM and fsm_count < NUM_A_SECTIONS-1)
                                       or (state = DSO      and fsm_count < ROWS-1)
                                     else (others => '0');

--  Logic to combinatorially determine next fsm state

    state_nxt <= SETUP      when (state = SAVE) 
            else DSI        when (state = SETUP and ena = '1' and rst = '0' and (mode = '0' or (mode = '1' and run_one = '0')))
            else PE_PIPE    when (state = DSI and fsm_count = N_SIZE-1)
            else PE_ACCUM   when (state = PE_PIPE and fsm_count = COLS-1)
            else DSO        when (state = PE_ACCUM and fsm_count = NUM_A_SECTIONS-1)
            else ERR        when (state = DSO and fsm_count = ROWS-1)
            else SAVE       when (state = ERR)
            else state;

--  Assign enable signals at output
--  Assign some intermedirary signals to be used for other logic 

    dsi_ena_hold    <= '1' when state = DSI else '0';
    dsi_ena         <= dsi_ena_hold;
    pe_ena          <= '1' when (state = PE_PIPE or state = PE_ACCUM) else '0';
    accum_ena       <= '1' when state = PE_ACCUM else '0';
    dso_ena_hold    <= '1' when (state = DSO or (state = PE_ACCUM and fsm_count > 0)) else '0';
    dso_ena         <= dso_ena_hold;

--  When reset, state = SETUP and fsm_count = 0
--  When enable, advance fsm state and count

    process (clk)
    begin
        if rising_edge(clk) then
            if (rst = '1' or ena = '0') then
                state <= SETUP;
                fsm_count <= (others => '0');
            else
                state <= state_nxt;
                fsm_count <= fsm_count_nxt;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------------------------------------------------

--  Logic to determine when to send z values to be appended to matrix mukltiplication result (add_error.vhd)
--  err_count_start is 1 cycle delayed from err_ena_hold & err_ena

--  Logic to determine when data is ready at the output to be saved
--  out_count_start is 1 cycle delayed from out_ena_hold & out_ena

err_count_nxt <= err_count + '1' when (err_count < NUM_B_SECTIONS-1 and err_count_start = '1') else (others=>'0');
err_incr_ena <= '1' when err_count_nxt < ROWS and err_ena_hold = '1' else '0';

out_count_nxt <= out_count + '1' when (out_count < NUM_B_SECTIONS-1 and out_count_start = '1') else (others=>'0');
out_incr_ena <= '1' when out_count_nxt < ROWS and out_ena_hold = '1' else '0';

process(clk)
begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            err_count <= (others=>'0');
            err_count_start <= '0';
            out_count <= (others=>'0');
            out_count_start <= '0';
        else
            if(err_count_start = '1') then
                err_count <= err_count_nxt;
            end if;
            if(out_count_start = '1') then
                out_count <= out_count_nxt;
            end if;
            if(err_ena_hold = '1') then
                err_count_start <= '1';
            end if;
            if(out_ena_hold = '1') then
                out_count_start <= '1';
            end if;
        end if;
    end if;
end process;

err_ena <= err_incr_ena;
out_ena <= out_incr_ena;

--------------------------------------------------------------------------------------------------------------------------

--  Logic to run fsm only once for testing
--  run_one used as condition for fsm to leave SETUP state

    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                run_one <= '0';
            else
                if (state = DSI) then
                    run_one <= '1';
                end if;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------------------------------------------------

--  Logic to determine index of a_vector (signed_shift_dynamic.vhd) to invert
--  If we were computing column-wise using entire a_vector's, we would simply invert a[n-1] to create circulant matrix
--  However, because we are rotating a_vector's to bring necessary elements to a[0..ROWS-1], we must keep track of which
--  element should be inverted (load_a.vhd)
 
    count_a_sel_nxt <= count_a_sel + '1' when (state = PE_PIPE or state = PE_ACCUM) 
                                          and (count_a_sel < NUM_B_SECTIONS-1)
                                         else (others => '0'); 
    a_sel_nxt <= a_sel - ROWS when (state = PE_PIPE or state = PE_ACCUM)
                               and (count_a_sel = NUM_B_SECTIONS-1)
                              else (a_sel);
    
    process (clk)
    begin
        if rising_edge(clk) then
            if (rst = '1' or ena = '0') then
                count_a_sel <= (others => '0');
                a_sel <= std_logic_vector(to_unsigned(N_SIZE-1, COUNTER_SIZE_A_SEL));
            else 
                count_a_sel <= count_a_sel_nxt;
                a_sel <= a_sel_nxt;
            end if;
        end if;
    end process;

    a_sel_out <= a_sel;

--------------------------------------------------------------------------------------------------------------------------

--  Logic to determine which a, b, z values to be sent to data shift-in 
--  Logic to determine where to save w, de, en values at output
--  Necessary for on-board testing where externals registers in Quartus are used for DSI and DSO 

    ab_val_index_nxt <= ab_val_index + '1' when dsi_ena_hold = '1' and fsm_count < N_SIZE-1 else (others=>'0');
    z_val_index_nxt <= z_val_index + '1' when err_incr_ena = '1' 
                  else z_val_index when err_ena_hold = '1'
                  else (others=>'0');
    w_val_index_nxt <= w_val_index + '1' when out_incr_ena = '1' 
                  else w_val_index when out_ena_hold = '1'
                  else (others=>'0');

    process (clk)
    begin
        if rising_edge(clk) then
            if(rst = '1') then
                ab_val_index <= (others=>'0');
                z_val_index <= (others=>'0');
                w_val_index <= (others=>'0');
                err_ena_hold <= '0';
                out_ena_hold <= '0';
            else
                if(ena = '1') then
                    if(dso_ena_hold = '1') then
                        if(dso_count = NUM_B_SECTIONS-1) then 
                            err_ena_hold <= '1';
                        end if;
                        if(err_ena_hold = '1') then
                            out_ena_hold <= '1';
                        end if;
                    else
                        if(err_ena_hold = '0') then
                            out_ena_hold <= '0';
                        end if;
                        err_ena_hold <= '0';
                    end if;
                    ab_val_index <= ab_val_index_nxt;
                    z_val_index <= z_val_index_nxt;
                    w_val_index <= w_val_index_nxt;
                end if;
            end if;
        end if;
    end process;

    ab_val_index_out <= ab_val_index;
    z_val_index_out <= z_val_index;
    w_val_index_out <= w_val_index;

--------------------------------------------------------------------------------------------------------------------------

end rtl;
