library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use work.tools_pkg.ALL;
use work.cache_pkg.ALL;

entity mem is
  generic(filename : string; BITS : natural);
  port (
    clk, rst, load : in std_logic;
    -- we='1' when transport cache2mem
    we : in std_logic;
    tag : in std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
    index : in std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
    wd1, wd2, wd3, wd4, wd5, wd6, wd7, wd8 : in std_logic_vector(31 downto 0);
    rd1, rd2, rd3, rd4, rd5, rd6, rd7, rd8 : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behavior of mem is
  constant SIZE : natural := 2**BITS;
  type ram_type is array(natural range<>) of std_logic_vector(31 downto 0);
  type addr30_type is array(natural range<>) of std_logic_vector(29 downto 0);

  -- TODO: compatible with CONST_CACHE_OFFSET_SIZE
  signal ram1_datum, ram2_datum, ram3_datum, ram4_datum, ram5_datum, ram6_datum, ram7_datum, ram8_datum : std_logic_vector(31 downto 0);

begin
  process(clk, rst, load, tag, index, we, wd1, wd2, wd3, wd4, wd5, wd6, wd7, wd8)
    file memfile : text open READ_MODE is filename;
    variable idx : integer;
    variable lin : line;
    variable ch : character;
    variable res : std_logic_vector(3 downto 0);
    variable ram : ram_type(0 to SIZE-1);
    variable stored_addr : addr30_type(0 to 2**CONST_CACHE_OFFSET_SIZE-1);
  begin
    for i in 0 to 7 loop
      stored_addr(i) := tag & index & std_logic_vector(to_unsigned(i, 3));
    end loop;
    -- initialization
    if rst = '1' then
      -- initialize with zeros
      ram := (others => (others => '0'));
    elsif rising_edge(clk) then
      if load = '1' then
        -- load memory from file
        idx := 0;
        while not endfile(memfile) loop
          readline(memfile, lin);
          for i in 0 to 7 loop
            read(lin, ch);
            ram(idx)(31-i*4 downto 28-i*4) := char2bits(ch);
          end loop;
          idx := idx + 1;
        end loop;
        file_close(memfile);
      elsif we = '1' then
        if not is_X(stored_addr(0)) then
          ram(to_integer(unsigned(stored_addr(0)))) := wd1;
          ram(to_integer(unsigned(stored_addr(1)))) := wd2;
          ram(to_integer(unsigned(stored_addr(2)))) := wd3;
          ram(to_integer(unsigned(stored_addr(3)))) := wd4;
          ram(to_integer(unsigned(stored_addr(4)))) := wd5;
          ram(to_integer(unsigned(stored_addr(5)))) := wd6;
          ram(to_integer(unsigned(stored_addr(6)))) := wd7;
          ram(to_integer(unsigned(stored_addr(7)))) := wd8;
        end if;
      end if;
    end if;
    -- read
    if is_X(stored_addr(0)) then
      ram1_datum <= (others => '0');
      ram2_datum <= (others => '0');
      ram3_datum <= (others => '0');
      ram4_datum <= (others => '0');
      ram5_datum <= (others => '0');
      ram6_datum <= (others => '0');
      ram7_datum <= (others => '0');
      ram8_datum <= (others => '0');
    else
      ram1_datum <= ram(to_integer(unsigned(stored_addr(0))));
      ram2_datum <= ram(to_integer(unsigned(stored_addr(1))));
      ram3_datum <= ram(to_integer(unsigned(stored_addr(2))));
      ram4_datum <= ram(to_integer(unsigned(stored_addr(3))));
      ram5_datum <= ram(to_integer(unsigned(stored_addr(4))));
      ram6_datum <= ram(to_integer(unsigned(stored_addr(5))));
      ram7_datum <= ram(to_integer(unsigned(stored_addr(6))));
      ram8_datum <= ram(to_integer(unsigned(stored_addr(7))));
    end if;
  end process;

  rd1 <= ram1_datum;
  rd2 <= ram2_datum;
  rd3 <= ram3_datum;
  rd4 <= ram4_datum;
  rd5 <= ram5_datum;
  rd6 <= ram6_datum;
  rd7 <= ram7_datum;
  rd8 <= ram8_datum;
end architecture;
