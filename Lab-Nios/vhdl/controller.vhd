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
    type state is (FETCH1, FETCH2, DECODE, R_OP, I_OP, STORE, BREAK, LOAD1, LOAD2);
    signal s_current_state, s_next_state : state;

begin
    state_proc : process(clk, reset_n)
    begin
        if (reset_n = '0') then
            s_current_state <= FETCH1;
        elsif (rising_edge(clk)) then
            s_current_state <= s_next_state;
        end if;
    end process state_proc;

    op_alu_proc : process(op)
    begin
        case op is
            when "111010" =>

                op_alu(2 downto 0) <= opx(5 downto 3);
                case opx(3 downto 0) is
                    when x"6" =>
                        op_alu(5 downto 3) <= "100";
                    when x"e" =>
                        op_alu(5 downto 3) <= "100";
                    when x"1" =>
                        op_alu(5 downto 3) <= "000";
                    when x"9" =>
                        op_alu(5 downto 3) <= "001";
                    when x"8" =>
                        op_alu(5 downto 3) <= "011";
                    when x"0" =>
                        op_alu(5 downto 3) <= "011";
                    when others =>
                        op_alu(5 downto 3) <= "110";
                end case;

            when "010111" =>
                op_alu <= "000000";
            when "010101" =>
                op_alu <= "000000";
            when others =>
                op_alu(2 downto 0) <= op(5 downto 3);
                case op(3 downto 0) is
                    when x"C" =>
                        op_alu(5 downto 3) <= "100";
                    when x"4" =>
                        if (op(5 downto 4) = "00") then
                            op_alu(5 downto 3) <= "000";
                        else
                            op_alu(5 downto 3) <= "100";
                        end if;
                    when others =>
                        op_alu(5 downto 3) <= "011";
                end case;
        end case;
    end process op_alu_proc;

    comb_proc : process(s_current_state)
    begin
        s_next_state <= s_current_state;
        case s_current_state is
            when FETCH1 =>
                read         <= '1';
                branch_op    <= '0';
                imm_signed   <= '0';
                ir_en        <= '0';
                pc_add_imm   <= '0';
                pc_en        <= '0';
                pc_sel_a     <= '0';
                pc_sel_imm   <= '0';
                rf_wren      <= '0';
                sel_addr     <= '0';
                sel_b        <= '0';
                sel_mem      <= '0';
                sel_pc       <= '0';
                sel_ra       <= '0';
                sel_rC       <= '0';
                write        <= '0';
                s_next_state <= FETCH2;

            when FETCH2 =>
                read         <= '0';
                pc_en        <= '1';
                ir_en        <= '1';
                s_next_state <= DECODE;

            when DECODE =>
                pc_en <= '0';
                ir_en <= '0';
                if (op = "111010" AND opx = "110100") then
                    s_next_state <= BREAK;
                elsif (op = "010111") then
                    s_next_state <= LOAD1;
                elsif (op = "010101") then
                    s_next_state <= STORE;
                elsif (op = "111010") then
                    s_next_state <= R_OP;
                else
                    s_next_state <= I_OP;
                end if;

            when R_OP =>
                rf_wren      <= '1';
                sel_rC       <= '1';
                sel_b        <= '1';
                s_next_state <= FETCH1;

            when I_OP =>
                imm_signed   <= '1';
                rf_wren      <= '1';
                s_next_state <= FETCH1;

            when STORE =>
                imm_signed   <= '1';
                sel_b        <= '0';
                sel_addr     <= '1';
                write        <= '1';
                s_next_state <= FETCH1;

            when BREAK =>               -- @suppress "Dead state 'BREAK': state does not have outgoing transitions"
                s_next_state <= BREAK;

            when LOAD1 =>
                imm_signed   <= '1';
                sel_addr     <= '1';
                read         <= '1';
                s_next_state <= LOAD2;

            when LOAD2 =>
                sel_mem      <= '1';
                rf_wren      <= '1';
                s_next_state <= FETCH1;
        end case;

    end process comb_proc;
end synth;
