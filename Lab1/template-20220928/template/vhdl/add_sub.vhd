library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add_sub is
    port(
        a        : in  std_logic_vector(31 downto 0);
        b        : in  std_logic_vector(31 downto 0);
        sub_mode : in  std_logic;
        carry    : out std_logic;
        zero     : out std_logic;
        r        : out std_logic_vector(31 downto 0)
    );
end add_sub;

architecture synth of add_sub is
    signal s_sub_mode1 : std_logic_vector(31 downto 0);
    signal s_sub_mode2 : std_logic_vector(32 downto 0);
    signal s_b         : std_logic_vector(32 downto 0);
    signal s_add_sub   : std_logic_vector(32 downto 0);
begin

    s_sub_mode1 <= (others => sub_mode);
    s_b         <= '0' & (b xor s_sub_mode1);
    s_sub_mode2 <= (32 downto 1 => '0') & sub_mode;
    s_add_sub   <= std_logic_vector(unsigned(a) + unsigned(s_b) + unsigned(s_sub_mode2));

    zero  <= '1' when unsigned(s_add_sub(31 downto 0)) = 0 else '0';
    r     <= s_add_sub(31 downto 0);
    carry <= s_add_sub(32);

end synth;
