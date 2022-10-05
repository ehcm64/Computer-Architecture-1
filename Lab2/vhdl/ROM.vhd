library ieee;
use ieee.std_logic_1164.all;

entity ROM is
    port(
        clk     : in  std_logic;
        cs      : in  std_logic;
        read    : in  std_logic;
        address : in  std_logic_vector(9 downto 0);
        rddata  : out std_logic_vector(31 downto 0)
    );
end ROM;

architecture synth of ROM is
    signal s_address    : std_logic_vector(9 downto 0);
    signal s_cs, s_read : std_logic;
begin
    p_buff : process(clk, address, cs, read) is
    begin
        if (rising_edge(clk)) then
            s_address <= address;
            s_cs      <= cs;
            s_read    <= read;
        end if;
    end process p_buff;

    write_read : process(clk, s_cs, s_address, s_read) is
    begin
        rddata <= (others => 'Z');
        if (rising_edge(clk)) then
            if (s_cs = '1') then
                if (s_read = '1') then

                end if;
            end if;
        end if;
    end process write_read;
end synth;
