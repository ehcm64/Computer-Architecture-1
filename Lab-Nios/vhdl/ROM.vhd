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
    COMPONENT ROM_Block IS
        PORT(
            address : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
            clock   : IN  STD_LOGIC;
            q       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT ROM_Block;

    signal s_address    : std_logic_vector(9 downto 0);
    signal s_cs, s_read : std_logic;
    signal s_q     : std_logic_vector(31 downto 0);
begin
    ROM_b : ROM_Block
        PORT MAP(
            address => address,
            clock   => clk,
            q       => s_q
        );

    p_buff : process(clk, address, cs, read) is
    begin
        if (rising_edge(clk)) then
            s_address <= address;
            s_cs      <= cs;
            s_read    <= read;
        end if;
    end process p_buff;

    p_read : process(clk, s_cs, s_address, s_read) is
    begin
       if (s_cs = '1' and s_read = '1') then
            rddata <= s_q;
        else
            rddata <= (others => 'Z');
        end if;
       
    end process p_read;
end synth;
