library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_unit is
    port(
        a  : in  std_logic_vector(31 downto 0);
        b  : in  std_logic_vector(4 downto 0);
        op : in  std_logic_vector(2 downto 0);
        r  : out std_logic_vector(31 downto 0)
    );
end shift_unit;

architecture synth of shift_unit is
    signal s_r : std_logic_vector(31 downto 0);
    signal s_b : integer;
begin
    s_b <= To_integer(signed(b)-1);

    with op select r <=
    a(31 - s_b downto 0) & a(31 downto 32 - s_b) when "000", -- rotate left
    a(s_b-1 downto 0) & a(31 downto s_b) when "001",           --rotate right
    a(31 - s_b downto 0) & (s_b-1 downto 0 => '0') when "010", --shift left logical
    (s_b-1 downto 0 => '0') & a(31 downto s_b) when "011",     --shift right logical
    (s_b-1 downto 0 => a(31)) & a(31 downto s_b) when "111",   --shift right aritmetic
    a when others;


    --s_r <= a(31 - s_b downto 0) & (s_b downto 0 => '0'); shift left
    --s_r <= a(31 downto s_b) & (s_b downto 0 => '0'); shift right
    --s_r <= a(31 - s_b downto 0) & a(31 downto 31 - s_b); rotate left
    --s_r <= a(31 downto s_b) & a(s_b downto 0); rotate right

end synth;
