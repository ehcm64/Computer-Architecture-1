library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
    port(
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        -- instruction opcode
        op         : in  std_logic_vector(5 downto 0);
        opx        : in  std_logic_vector(5 downto 0);
        -- activates branch condition
        branch_op  : out std_logic;
        -- immediate value sign extention
        imm_signed : out std_logic;
        -- instruction register enable
        ir_en      : out std_logic;
        -- PC control signals
        pc_add_imm : out std_logic;
        pc_en      : out std_logic;
        pc_sel_a   : out std_logic;
        pc_sel_imm : out std_logic;
        -- register file enable
        rf_wren    : out std_logic;
        -- multiplexers selections
        sel_addr   : out std_logic;
        sel_b      : out std_logic;
        sel_mem    : out std_logic;
        sel_pc     : out std_logic;
        sel_ra     : out std_logic;
        sel_rC     : out std_logic;
        -- write memory output
        read       : out std_logic;
        write      : out std_logic;
        -- alu op
        op_alu     : out std_logic_vector(5 downto 0)
    );
end controller;

architecture synth of controller is
    type state is (FETCH1, FETCH2, DECODE, R_OP, STORE, BREAK, LOAD1, I_OP, LOAD2);
    signal s_current_state : state;
    signal s_next_state    : state;
begin
    state_proc : process(clk, reset_n)
    begin
        if (reset_n = '0') then
            s_current_state <= FETCH1;
        end if;
        if (rising_edge(clk)) then
            s_current_state <= s_next_state;
        end if;
    end process state_proc;

    op_alu_proc : process(op)
    begin
        case op is
            when x"3A" =>
                op_alu <= opx;
            when others =>
                op_alu <= op;
        end case;
    end process op_alu_proc;

    comb_proc : process(state)
    begin
        s_next_state <= s_current_state;
        case s_current_state is

            when FETCH1 =>

                read         <= '1';
                s_next_state <= FETCH2;

            when FETCH2 =>

                pc_en        <= '1';
                s_next_state <= DECODE;

            when DECODE =>

                if (op = x"3A" AND opx = x"34") then
                    s_next_state <= BREAK;
                elsif (op = x"17") then
                    s_next_state <= LOAD1;
                elsif (op = x"15") then
                    s_next_state <= STORE;
                elsif (op = x"3A") then
                    s_next_state <= R_OP;
                else
                    s_next_state <= I_OP;
                end if;

            when R_OP =>

                s_next_state <= FETCH1;

            when STORE =>

                imm_signed <= '1';
                sel_b      <= '0';

                sel_addr     <= '1';
                write        <= '1';
                s_next_state <= FETCH1;

            when BREAK =>

                s_next_state <= BREAK;

            when LOAD1 =>

                imm_signed <= '1';

                sel_addr     <= '1';
                read         <= '1';
                s_next_state <= LOAD2;

            when I_OP =>

                if (op = "011001" OR op = "011010") then
                    imm_signed <= '1';
                else
                    imm_signed <= '0';
                end if;
                rf_wren      <= '1';
                s_next_state <= FETCH1;

            when LOAD2 =>
                sel_mem      <= '1';
                rf_wren      <= '1';
                s_next_state <= FETCH1;
        end case;

    end process comb_proc;
end synth;
