library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use work.tools_pkg.ALL;
use work.cache_pkg.ALL;

entity data_cache is
  generic(filename : string);
  port (
    clk, rst : in std_logic;
    we : in std_logic;
    -- program counter is 4-byte aligned
    a : in std_logic_vector(31 downto 0);
    wd : in std_logic_vector(31 downto 0);
    rd : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behavior of data_cache is
  component cache_decoder
    port (
      addr : in std_logic_vector(31 downto 0);
      tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      index : out std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
      offset : out std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0)
    );
  end component;

  component mux8
    generic(N : integer);
    port (
      d000 : in std_logic_vector(N-1 downto 0);
      d001 : in std_logic_vector(N-1 downto 0);
      d010 : in std_logic_vector(N-1 downto 0);
      d011 : in std_logic_vector(N-1 downto 0);
      d100 : in std_logic_vector(N-1 downto 0);
      d101 : in std_logic_vector(N-1 downto 0);
      d110 : in std_logic_vector(N-1 downto 0);
      d111 : in std_logic_vector(N-1 downto 0);
      s : in std_logic_vector(2 downto 0);
      y : out std_logic_vector(N-1 downto 0)
        );
  end component;

  -- The size of data cache assumes to be 1K-byte
  constant SIZE : natural := 256; -- 0x0100
  type validtype is array(natural range<>) of std_logic;
  type ramtype is array(natural range<>) of std_logic_vector(31 downto 0);
  type tagtype is array(natural range<>) of std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);

  signal valid_data : validtype(0 to SIZE-1);
  signal tag_data : tagtype(0 to SIZE-1);

  -- TODO: compatible with CONST_CACHE_OFFSET_SIZE
  signal ram0_data : ramtype(0 to SIZE-1);
  signal ram1_data : ramtype(0 to SIZE-1);
  signal ram2_data : ramtype(0 to SIZE-1);
  signal ram3_data : ramtype(0 to SIZE-1);
  signal ram4_data : ramtype(0 to SIZE-1);
  signal ram5_data : ramtype(0 to SIZE-1);
  signal ram6_data : ramtype(0 to SIZE-1);
  signal ram7_data : ramtype(0 to SIZE-1);

  -- decode addr
  signal tag : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal index : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
  signal offset : std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);

  -- load from memory in case of cache miss
  signal load : std_logic;
  signal s : std_logic_vector(2 downto 0); -- selector for mux8

  signal ram0_datum : std_logic_vector(31 downto 0);
  signal ram1_datum : std_logic_vector(31 downto 0);
  signal ram2_datum : std_logic_vector(31 downto 0);
  signal ram3_datum : std_logic_vector(31 downto 0);
  signal ram4_datum : std_logic_vector(31 downto 0);
  signal ram5_datum : std_logic_vector(31 downto 0);
  signal ram6_datum : std_logic_vector(31 downto 0);
  signal ram7_datum : std_logic_vector(31 downto 0);

begin
  cache_decoder0 : cache_decoder port map(
    addr => a,
    tag => tag,
    index => index,
    offset => offset
  );

  -- write data or load block from memory
  process(clk, rst, a)
    file memfile : text open READ_MODE is filename;
    variable idx : integer;
    variable lin : line;
    variable ch : character;
   begin
    -- initialization
    if rst = '1' then
      -- initialize with zeros
      valid_data <= (others => '0');
    elsif rising_edge(clk) then
      -- load data from memory
      if load = '1' then
        idx := 0;
        -- while not endfile(memfile) loop
        --   readline(memfile, lin);
        --   for i in 0 to 7 loop
        --     read(lin, ch);
        --     ram(idx)(31-i*4 downto 28-i*4) <= char2bits(ch);
        --   end loop;
        --   idx := idx + 1;
        -- end loop;
        -- file_close(memfile);
      -- TODO: implement when we signal is '1'
      -- elsif we = '1' then
      end if;
    end if;
  end process;

  process(index, offset, we)
    variable s0 : std_logic_vector(2 downto 0);
    variable load0 : std_logic;
  begin
    load0 := '0';
    if we = '0' then
      if valid_data(to_integer(unsigned(index))) = '1' then
        -- cache hit!
        if tag_data(to_integer(unsigned(index))) = tag then
          s0 := offset;
        else
          -- cache miss
          load0 := '1';
        end if;
      else
        load0 := '1';
      end if;
    end if;
    s <= s0;
    load <= load0;
  end process;

  ram0_datum <= ram0_data(to_integer(unsigned(index)));
  ram1_datum <= ram1_data(to_integer(unsigned(index)));
  ram2_datum <= ram2_data(to_integer(unsigned(index)));
  ram3_datum <= ram3_data(to_integer(unsigned(index)));
  ram4_datum <= ram4_data(to_integer(unsigned(index)));
  ram5_datum <= ram5_data(to_integer(unsigned(index)));
  ram6_datum <= ram6_data(to_integer(unsigned(index)));
  ram7_datum <= ram7_data(to_integer(unsigned(index)));
  mux8_0 : mux8 generic map(N=>32)
  port map (
    d000 => ram0_datum,
    d001 => ram1_datum,
    d010 => ram2_datum,
    d011 => ram3_datum,
    d100 => ram4_datum,
    d101 => ram5_datum,
    d110 => ram6_datum,
    d111 => ram7_datum,
    s => s,
    y => rd
  );
end architecture;
