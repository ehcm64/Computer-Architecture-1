library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity extend is
    port(
        imm16  : in  std_logic_vector(15 downto 0);
        signed : in  std_logic;
        imm32  : out std_logic_vector(31 downto 0)
    );
end extend;

architecture synth of extend is
    signal s_concat : std_logic_vector(15 downto 0);
begin
    s_concat <= (others => imm16(15)) when signed = '1' else (others => '0');
    imm32    <= s_concat & imm16;
end synth;
