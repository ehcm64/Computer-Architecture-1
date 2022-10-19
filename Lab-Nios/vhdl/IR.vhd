library ieee;
use ieee.std_logic_1164.all;

entity IR is
    port(
        clk    : in  std_logic;
        enable : in  std_logic;
        D      : in  std_logic_vector(31 downto 0);
        Q      : out std_logic_vector(31 downto 0)
    );
end IR;

architecture synth of IR is
    signal s_Q : std_logic_vector(31 downto 0);
begin
    flip_flop : process(clk) is
    begin
        if (rising_edge(clk) and enable = '1') then
            s_Q <= D;
        end if;
    end process flip_flop;
    Q <= s_Q;

end synth;
