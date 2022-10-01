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

begin

    process(a, b, sub_mode) is
        variable s_sub_mode1 : std_logic_vector(31 downto 0);
        variable s_sub_mode2 : std_logic_vector(32 downto 0);
        variable s_b         : std_logic_vector(32 downto 0);
        variable s_add_sub   : std_logic_vector(32 downto 0);
    begin
        s_sub_mode1 := (others => sub_mode);
        s_b         := '0' & (b xor s_sub_mode1);
        s_sub_mode2 := (32 downto 1 => '0') & sub_mode;
        s_add_sub   := std_logic_vector(unsigned(a) + unsigned(s_b) + unsigned(s_sub_mode2));
        carry       <= s_add_sub(32);
        if (unsigned(s_add_sub(31 downto 0)) = 0) then
            zero <= '1'; 
        else
            zero <= '0';
        end if;
        r           <= s_add_sub(31 downto 0);

    end process;
end synth;
