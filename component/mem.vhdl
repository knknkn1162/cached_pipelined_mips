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
    rd1, rd2, rd3, rd4, rd5, rd6, rd7, rd8 : out std_logic_vector(31 downto 0);
    rd_en : out std_logic
  );
end entity;

architecture behavior of mem is
  component flopr8_en
    generic(N : natural);
    port (
      clk, rst, en : in std_logic;
      a1, a2, a3, a4, a5, a6, a7, a8 : in std_logic_vector(N-1 downto 0);
      y1, y2, y3, y4, y5, y6, y7, y8 : out std_logic_vector(N-1 downto 0)
    );
  end component;

  constant SIZE : natural := 2**BITS;
  type ram_type is array(natural range<>) of std_logic_vector(31 downto 0);
  type addr30_type is array(natural range<>) of std_logic_vector(29 downto 0);
  signal rd_en0 : std_logic;

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
          rd_en0 <= '0';
        end if;
      end if;
    end if;
    if we = '0' then
      if is_X(stored_addr(0)) then
        ram1_datum <= (others => '0');
        ram2_datum <= (others => '0');
        ram3_datum <= (others => '0');
        ram4_datum <= (others => '0');
        ram5_datum <= (others => '0');
        ram6_datum <= (others => '0');
        ram7_datum <= (others => '0');
        ram8_datum <= (others => '0');
        rd_en0 <= '0';
      else
        ram1_datum <= ram(to_integer(unsigned(stored_addr(0))));
        ram2_datum <= ram(to_integer(unsigned(stored_addr(1))));
        ram3_datum <= ram(to_integer(unsigned(stored_addr(2))));
        ram4_datum <= ram(to_integer(unsigned(stored_addr(3))));
        ram5_datum <= ram(to_integer(unsigned(stored_addr(4))));
        ram6_datum <= ram(to_integer(unsigned(stored_addr(5))));
        ram7_datum <= ram(to_integer(unsigned(stored_addr(6))));
        ram8_datum <= ram(to_integer(unsigned(stored_addr(7))));
        rd_en0 <= '1';
      end if;
    end if;
  end process;
  rd_en <= rd_en0;

  -- transport rds to cache
  reg_d : flopr8_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => rd_en0,
    a1 => ram1_datum, a2 => ram2_datum, a3 => ram3_datum, a4 => ram4_datum,
    a5 => ram5_datum, a6 => ram6_datum, a7 => ram7_datum, a8 => ram8_datum,
    y1 => rd1, y2 => rd2, y3 => rd3, y4 => rd4,
    y5 => rd5, y6 => rd6, y7 => rd7, y8 => rd8
  );
end architecture;
