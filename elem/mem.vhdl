library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.tools_pkg.ALL;
use work.cache_pkg.ALL;

entity mem is
  generic(filename : string; BITS : natural);
  port (
    clk, rst, load : in std_logic;
    we : in std_logic;
    -- program counter is 4-byte aligned
    a : in std_logic_vector(CONST_CACHE_TAG_SIZE+CONST_CACHE_INDEX_SIZE-1 downto 0);
    wd1, wd2, wd3, wd4, wd5, wd6, wd7, wd8 : in std_logic_vector(31 downto 0);
    rd1, rd2, rd3, rd4, rd5, rd6, rd7, rd8 : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behavior of mem is
  constant SIZE : natural := 2**BITS;
  type ram_type is array(natural range<>) of std_logic_vector(31 downto 0);
  type addr30_type is array(natural range<>) of std_logic_vector(29 downto 0);
  signal ram : ram_type(0 to SIZE-1);
  signal stored_addr : addr30_type(0 to 2**CONST_CACHE_OFFSET_SIZE-1);
  signal test_vec : std_logic_vector(31 downto 0);

begin
  m : for i in 0 to 2**CONST_CACHE_OFFSET_SIZE-1 generate
    stored_addr(i) <= a & std_logic_vector(to_unsigned(i, 3));
  end generate;

  process(clk, rst, a)
    file memfile : text open READ_MODE is filename;
    variable idx : integer;
    variable lin : line;
    variable ch : character;
    variable res : std_logic_vector(3 downto 0);
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
          ram(to_integer(unsigned(stored_addr(0)))) <= wd1;
          ram(to_integer(unsigned(stored_addr(1)))) <= wd2;
          ram(to_integer(unsigned(stored_addr(2)))) <= wd3;
          ram(to_integer(unsigned(stored_addr(3)))) <= wd4;
          ram(to_integer(unsigned(stored_addr(4)))) <= wd5;
          ram(to_integer(unsigned(stored_addr(5)))) <= wd6;
          ram(to_integer(unsigned(stored_addr(6)))) <= wd7;
          ram(to_integer(unsigned(stored_addr(7)))) <= wd8;
        end if;
      end if;
    end if;
  end process;

  -- read block
  process(clk, rst, stored_addr, we)
  begin
    if is_X(stored_addr(0)) then
      rd1 <= (others => '0');
      rd2 <= (others => '0');
      rd3 <= (others => '0');
      rd4 <= (others => '0');
      rd5 <= (others => '0');
      rd6 <= (others => '0');
      rd7 <= (others => '0');
      rd8 <= (others => '0');
    elsif we = '0' then
      rd1 <= ram(to_integer(unsigned(stored_addr(0))));
      rd2 <= ram(to_integer(unsigned(stored_addr(1))));
      rd3 <= ram(to_integer(unsigned(stored_addr(2))));
      rd4 <= ram(to_integer(unsigned(stored_addr(3))));
      rd5 <= ram(to_integer(unsigned(stored_addr(4))));
      rd6 <= ram(to_integer(unsigned(stored_addr(5))));
      rd7 <= ram(to_integer(unsigned(stored_addr(6))));
      rd8 <= ram(to_integer(unsigned(stored_addr(7))));
    end if;
  end process;
end architecture;