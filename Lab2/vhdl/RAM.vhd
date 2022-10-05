library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    port(
        clk     : in  std_logic;
        cs      : in  std_logic;
        read    : in  std_logic;
        write   : in  std_logic;
        address : in  std_logic_vector(9 downto 0);
        wrdata  : in  std_logic_vector(31 downto 0);
        rddata  : out std_logic_vector(31 downto 0));
end RAM;

architecture synth of RAM is
    type reg_type is array (0 to 1023) of std_logic_vector(31 downto 0);
    signal reg                   : reg_type;
    signal s_address             : std_logic_vector(9 downto 0);
    signal s_cs, s_read, s_write : std_logic;
    --signal s_rddata              : std_logic_vector(31 downto 0) := (others => '0');

begin
    p_buff : process(clk,address,cs,read,write) is
    begin
        if (rising_edge(clk)) then
            s_address <= address;
            s_cs      <= cs;
            s_read    <= read;
            s_write   <= write;
        
        end if;
    end process p_buff;

    write_read : process(clk,s_cs,s_address,s_read,s_write,wrdata) is
    begin
        rddata <= (others => 'Z');
        if (rising_edge(clk)) then
            if (s_cs = '1') then
                if (s_read = '1') then
                    rddata <= reg(to_integer(unsigned(s_address)));
                end if;
            
                if (s_write = '1') then
                    reg(to_integer(unsigned(s_address))) <= wrdata;
                end if;
            end if;
        end if;
    end process write_read;
end synth;
