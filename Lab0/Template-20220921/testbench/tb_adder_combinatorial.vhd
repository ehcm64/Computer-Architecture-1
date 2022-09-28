library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_adder_combinatorial is
end tb_adder_combinatorial;

architecture test of tb_adder_combinatorial is

    constant TIME_DELTA : time := 100 ns;

    constant N_BITS : positive := 4;

    signal OP1 : std_logic_vector(N_BITS - 1 downto 0);
    signal OP2 : std_logic_vector(N_BITS - 1 downto 0);
    signal SUM : std_logic_vector(N_BITS downto 0);

begin

    dut : entity work.adder_combinatorial
        generic map(N_BITS => N_BITS)
        port map(OP1 => OP1,
                 OP2 => OP2,
                 SUM => SUM);

    simulation : process
        procedure check_add(constant in1 : in natural;
                            constant in2 : in natural) is

        begin
            OP1 <= std_logic_vector(to_unsigned(in1, OP1'length));
            OP2 <= std_logic_vector(to_unsigned(in2, OP2'length));

            wait for TIME_DELTA;
        end procedure check_add;

    begin
        check_add(12, 8);
        check_add(10, 6);
        check_add(4, 1);
        check_add(11, 7);
        check_add(10, 13);
        check_add(8, 7);
        check_add(1, 9);
        check_add(7, 3);
        check_add(1, 4);
        check_add(8, 0);

        wait;
    end process simulation;

end architecture test;
