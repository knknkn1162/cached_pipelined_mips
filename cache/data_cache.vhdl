library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cache_pkg.ALL;

entity data_cache is
  port (
    clk, rst, load : in std_logic;
    we : in std_logic;
    -- program counter is 4-byte aligned
    a : in std_logic_vector(31 downto 0);
    wd : in std_logic_vector(31 downto 0);
    tag_s : in std_logic;
    rd : out std_logic_vector(31 downto 0);
    wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08 : in std_logic_vector(31 downto 0);
    rd_tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
    rd_index : out cache_index_vector;
    rd01, rd02, rd03, rd04, rd05, rd06, rd07, rd08 : out std_logic_vector(31 downto 0);
    -- push cache miss to the memory
    cache_miss_en : out std_logic;
    valid_flag : out std_logic;
    -- pull load from the memory
    load_en : in std_logic
  );
end entity;

architecture behavior of data_cache is
  component cache_decoder
    port (
      addr : in std_logic_vector(31 downto 0);
      tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      index : out cache_index_vector;
      offset : out cache_offset_vector
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

  component mux2
    generic(N : integer);
    port (
      d0 : in std_logic_vector(N-1 downto 0);
      d1 : in std_logic_vector(N-1 downto 0);
      s : in std_logic;
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component cache_controller
    port (
      load : in std_logic;
      cache_valid : in std_logic;
      addr_tag, cache_tag : in std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      addr_index : in cache_index_vector;
      addr_offset : in cache_offset_vector;
      cache_miss_en : out std_logic;
      cache_valid_flag : out std_logic;
      rd_s : out cache_offset_vector
    );
  end component;

  -- The size of data cache assumes to be 1K-byte
  constant SIZE : natural := 256; -- 0x0100
  constant DATA_BLOCK_SIZE : natural := 2**CONST_CACHE_OFFSET_SIZE;
  type validtype is array(natural range<>) of std_logic;
  type ramtype is array(natural range<>) of std_logic_vector(31 downto 0);
  type addr30_type is array(natural range<>) of std_logic_vector(29 downto 0);
  type tagtype is array(natural range<>) of std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);

  -- decode addr
  signal addr_tag : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal addr_index : cache_index_vector;
  signal addr_offset : cache_offset_vector;

  -- TODO: compatible with CONST_CACHE_OFFSET_SIZE
  signal ram1_datum : std_logic_vector(31 downto 0);
  signal ram2_datum : std_logic_vector(31 downto 0);
  signal ram3_datum : std_logic_vector(31 downto 0);
  signal ram4_datum : std_logic_vector(31 downto 0);
  signal ram5_datum : std_logic_vector(31 downto 0);
  signal ram6_datum : std_logic_vector(31 downto 0);
  signal ram7_datum : std_logic_vector(31 downto 0);
  signal ram8_datum : std_logic_vector(31 downto 0);
  signal valid_datum : std_logic;
  signal tag_datum : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);

  -- is cache miss occurs or not
  signal rd_s : cache_offset_vector; -- selector for mux8

begin
  cache_decoder0 : cache_decoder port map(
    addr => a,
    tag => addr_tag,
    index => addr_index,
    offset => addr_offset
  );

  -- read & write data or load block from memory
  process(clk, rst, we, addr_tag, valid_datum, addr_index, addr_offset, wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08, wd)
    variable idx : natural;
    variable valid_data : validtype(0 to SIZE-1);
    variable tag_data : tagtype(0 to SIZE-1);

    -- TODO: compatible with CONST_CACHE_OFFSET_SIZE
    variable ram1_data : ramtype(0 to SIZE-1);
    variable ram2_data : ramtype(0 to SIZE-1);
    variable ram3_data : ramtype(0 to SIZE-1);
    variable ram4_data : ramtype(0 to SIZE-1);
    variable ram5_data : ramtype(0 to SIZE-1);
    variable ram6_data : ramtype(0 to SIZE-1);
    variable ram7_data : ramtype(0 to SIZE-1);
    variable ram8_data : ramtype(0 to SIZE-1);
  begin
    -- initialization
    if rst = '1' then
      -- initialize with zeros
      valid_data := (others => '0');
    -- writeback
    elsif rising_edge(clk) then
      -- pull the notification from the memory
      if load_en = '1' then
        idx := to_integer(unsigned(addr_index));
        -- when the ram_data is initial state
        valid_data(idx) := '1';
        tag_data(idx) := addr_tag;
        ram1_data(idx) := wd01;
        ram2_data(idx) := wd02;
        ram3_data(idx) := wd03;
        ram4_data(idx) := wd04;
        ram5_data(idx) := wd05;
        ram6_data(idx) := wd06;
        ram7_data(idx) := wd07;
        ram8_data(idx) := wd08;
      elsif we = '1' then
        if valid_datum = '1' then
          -- cache hit!
          if tag_datum = addr_tag then
            idx := to_integer(unsigned(addr_index));
            case addr_offset is
              when "000" =>
                ram1_data(idx) := wd;
              when "001" =>
                ram2_data(idx) := wd;
              when "010" =>
                ram3_data(idx) := wd;
              when "011" =>
                ram4_data(idx) := wd;
              when "100" =>
                ram5_data(idx) := wd;
              when "101" =>
                ram6_data(idx) := wd;
              when "110" =>
                ram7_data(idx) := wd;
              when "111" =>
                ram8_data(idx) := wd;
              when others =>
                -- do nothing
            end case;
          end if;
        end if;
      end if;
    end if;

    -- read
    if not is_X(addr_index) then
      ram1_datum <= ram1_data(to_integer(unsigned(addr_index)));
      ram2_datum <= ram2_data(to_integer(unsigned(addr_index)));
      ram3_datum <= ram3_data(to_integer(unsigned(addr_index)));
      ram4_datum <= ram4_data(to_integer(unsigned(addr_index)));
      ram5_datum <= ram5_data(to_integer(unsigned(addr_index)));
      ram6_datum <= ram6_data(to_integer(unsigned(addr_index)));
      ram7_datum <= ram7_data(to_integer(unsigned(addr_index)));
      ram8_datum <= ram8_data(to_integer(unsigned(addr_index)));
      valid_datum <= valid_data(to_integer(unsigned(addr_index)));
      tag_datum <= tag_data(to_integer(unsigned(addr_index)));
    end if;
  end process;

  cache_controller0 : cache_controller port map (
    load => load,
    cache_valid => valid_datum,
    addr_tag => addr_tag, cache_tag => tag_datum,
    addr_index => addr_index, addr_offset => addr_offset,
    cache_miss_en => cache_miss_en, cache_valid_flag => valid_flag,
    rd_s => rd_s
  );

  -- if cache_hit
  mux8_0 : mux8 generic map(N=>32)
  port map (
    d000 => ram1_datum,
    d001 => ram2_datum,
    d010 => ram3_datum,
    d011 => ram4_datum,
    d100 => ram5_datum,
    d101 => ram6_datum,
    d110 => ram7_datum,
    d111 => ram8_datum,
    s => rd_s,
    y => rd
  );

  -- out rd_tag, rd_index,rd0*
  mux2_tag : mux2 generic map(N=>CONST_CACHE_TAG_SIZE)
  port map (
    d0 => tag_datum,
    d1 => addr_tag,
    s => tag_s,
    y => rd_tag
  );
  rd_index <= addr_index;

  rd01 <= ram1_datum;
  rd02 <= ram2_datum;
  rd03 <= ram3_datum;
  rd04 <= ram4_datum;
  rd05 <= ram5_datum;
  rd06 <= ram6_datum;
  rd07 <= ram7_datum;
  rd08 <= ram8_datum;
end architecture;
