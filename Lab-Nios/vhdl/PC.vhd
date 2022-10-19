library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC is
    port(
        clk     : in  std_logic;
        reset_n : in  std_logic;
        en      : in  std_logic;
        sel_a   : in  std_logic;
        sel_imm : in  std_logic;
        add_imm : in  std_logic;
        imm     : in  std_logic_vector(15 downto 0);
        a       : in  std_logic_vector(15 downto 0);
        addr    : out std_logic_vector(31 downto 0)
    );
end PC;

architecture synth of PC is
    signal s_addr : std_logic_vector(31 downto 0);
begin

    p_addr : process(reset_n, clk) is
    begin
        if (reset_n = '0') then
            s_addr <= (others => '0');
        elsif (rising_edge(clk)) then
            if (en = '1') then
                if (add_imm = '1') then
                    s_addr <= std_logic_vector(unsigned(s_addr) + signed(imm));
                elsif (sel_imm = '1') then
                    s_addr <= "00000000000000" & imm & "00";
                elsif (sel_a = '1') then
                    s_addr <= "0000000000000000" & a;
                else
                    s_addr <= std_logic_vector(unsigned(s_addr) + 4);
                end if;
            end if;
        end if;

    end process p_addr;
    addr <= s_addr;

end synth;
