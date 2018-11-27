library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use work.tools_pkg.ALL;

entity data_cache is
  generic(filename : string);
  port (
    clk, rst, load : in std_logic;
    we : in std_logic;
    -- program counter is 4-byte aligned
    a : in std_logic_vector(29 downto 0);
    wd : in std_logic_vector(31 downto 0);
    rd : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behavior of data_cache is
  -- The size of data cache assumes to be 1K-byte
  constant SIZE : natural := 256; -- 0x0100
  type ramtype is array(natural range<>) of std_logic_vector(31 downto 0);
  signal ram : ramtype(0 to SIZE-1);

begin
  process(clk, rst, a)
    file memfile : text open READ_MODE is filename;
    variable idx : integer;
    variable lin : line;
    variable ch : character;
   begin
    -- initialization
    if rst = '1' then
      -- initialize with zeros
      ram <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if load = '1' then
        idx := 0;
        while not endfile(memfile) loop
          readline(memfile, lin);
          for i in 0 to 7 loop
            read(lin, ch);
            ram(idx)(31-i*4 downto 28-i*4) <= char2bits(ch);
          end loop;
          idx := idx + 1;
        end loop;
        file_close(memfile);
      elsif we = '1' then
        if not is_X(a) then
          ram(to_integer(unsigned(a))) <= wd;
        end if;
      end if;
    end if;
  end process;

  process(a, we)
  begin
    -- read
    if is_X(a) then
      rd <= (others => '0');
    else
      if we = '0' then
        rd <= ram(to_integer(unsigned(a)));
      end if;
    end if;
  end process;
end architecture;
