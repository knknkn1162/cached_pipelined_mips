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

  component flopr_en
    generic(N : natural);
    port (
      clk, rst, en: in std_logic;
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;
  constant SIZE : natural := 2**BITS;
  type ram_type is array(natural range<>) of std_logic_vector(31 downto 0);
  type addr30_type is array(natural range<>) of std_logic_vector(29 downto 0);
  signal ram : ram_type(0 to SIZE-1);
  signal stored_addr : addr30_type(0 to 2**CONST_CACHE_OFFSET_SIZE-1);
  signal rd_en0 : std_logic;

  -- TODO: compatible with CONST_CACHE_OFFSET_SIZE
  signal ram1_datum : std_logic_vector(31 downto 0);
  signal ram2_datum : std_logic_vector(31 downto 0);
  signal ram3_datum : std_logic_vector(31 downto 0);
  signal ram4_datum : std_logic_vector(31 downto 0);
  signal ram5_datum : std_logic_vector(31 downto 0);
  signal ram6_datum : std_logic_vector(31 downto 0);
  signal ram7_datum : std_logic_vector(31 downto 0);
  signal ram8_datum : std_logic_vector(31 downto 0);

begin
  m : for i in 0 to 2**CONST_CACHE_OFFSET_SIZE-1 generate
    stored_addr(i) <= tag & index & std_logic_vector(to_unsigned(i, 3));
  end generate;

  process(clk, rst, load, stored_addr, wd1, wd2, wd3, wd4, wd5, wd6, wd7, wd8)
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
        if not is_X(stored_addr(0)) then
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
  process(stored_addr, we)
  begin
    if is_X(stored_addr(0)) then
      ram1_datum <= (others => '0');
      ram2_datum <= (others => '0');
      ram3_datum <= (others => '0');
      ram4_datum <= (others => '0');
      ram5_datum <= (others => '0');
      ram6_datum <= (others => '0');
      ram7_datum <= (others => '0');
      ram8_datum <= (others => '0');
    elsif we = '0' then
      ram1_datum <= ram(to_integer(unsigned(stored_addr(0))));
      ram2_datum <= ram(to_integer(unsigned(stored_addr(1))));
      ram3_datum <= ram(to_integer(unsigned(stored_addr(2))));
      ram4_datum <= ram(to_integer(unsigned(stored_addr(3))));
      ram5_datum <= ram(to_integer(unsigned(stored_addr(4))));
      ram6_datum <= ram(to_integer(unsigned(stored_addr(5))));
      ram7_datum <= ram(to_integer(unsigned(stored_addr(6))));
      ram8_datum <= ram(to_integer(unsigned(stored_addr(7))));
      -- notify completion of export to the cache
      rd_en0 <= '1';
    end if;
  end process;
  rd_en <= rd_en0;

  -- transport rds to cache
  reg_d1 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => rd_en0,
    a => ram1_datum,
    y => rd1
  );

  reg_d2 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => rd_en0,
    a => ram2_datum,
    y => rd2
  );

  reg_d3 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => rd_en0,
    a => ram3_datum,
    y => rd3
  );

  reg_d4 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => rd_en0,
    a => ram4_datum,
    y => rd4
  );

  reg_d5 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => rd_en0,
    a => ram5_datum,
    y => rd5
  );

  reg_d6 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => rd_en0,
    a => ram6_datum,
    y => rd6
  );

  reg_d7 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => rd_en0,
    a => ram7_datum,
    y => rd7
  );

  reg_d8 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => rd_en0,
    a => ram8_datum,
    y => rd8
  );
end architecture;
