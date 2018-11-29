library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
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
    rd : out std_logic_vector(31 downto 0);
    wd_d1, wd_d2, wd_d3, wd_d4, wd_d5, wd_d6, wd_d7, wd_d8 : in std_logic_vector(31 downto 0);
    rd_d1, rd_d2, rd_d3, rd_d4, rd_d5, rd_d6, rd_d7, rd_d8 : out std_logic_vector(31 downto 0);
    tag_s : in std_logic;
    rd_tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
    rd_index : out std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
    cache_miss_en : out std_logic;
    load_en : in std_logic
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

  component flopr_en
    generic(N : natural);
    port (
      clk, rst, en: in std_logic;
      a : in std_logic_vector(N-1 downto 0);
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

  -- state
  type statetype is (
    NormalS, DumpS, WaitS, LoadS
  );
  signal state, nextstate : statetype;

  -- The size of data cache assumes to be 1K-byte
  constant SIZE : natural := 256; -- 0x0100
  constant DATA_BLOCK_SIZE : natural := 2**CONST_CACHE_OFFSET_SIZE;
  type validtype is array(natural range<>) of std_logic;
  type ramtype is array(natural range<>) of std_logic_vector(31 downto 0);
  type addr30_type is array(natural range<>) of std_logic_vector(29 downto 0);
  type tagtype is array(natural range<>) of std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);

  signal valid_data : validtype(0 to SIZE-1);
  signal tag_data : tagtype(0 to SIZE-1);

  -- TODO: compatible with CONST_CACHE_OFFSET_SIZE
  signal ram1_data : ramtype(0 to SIZE-1);
  signal ram2_data : ramtype(0 to SIZE-1);
  signal ram3_data : ramtype(0 to SIZE-1);
  signal ram4_data : ramtype(0 to SIZE-1);
  signal ram5_data : ramtype(0 to SIZE-1);
  signal ram6_data : ramtype(0 to SIZE-1);
  signal ram7_data : ramtype(0 to SIZE-1);
  signal ram8_data : ramtype(0 to SIZE-1);

  -- decode addr
  signal addr_tag : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal addr_index : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
  signal addr_offset : std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);

  -- TODO: compatible with CONST_CACHE_OFFSET_SIZE
  signal ram1_datum : std_logic_vector(31 downto 0);
  signal ram2_datum : std_logic_vector(31 downto 0);
  signal ram3_datum : std_logic_vector(31 downto 0);
  signal ram4_datum : std_logic_vector(31 downto 0);
  signal ram5_datum : std_logic_vector(31 downto 0);
  signal ram6_datum : std_logic_vector(31 downto 0);
  signal ram7_datum : std_logic_vector(31 downto 0);
  signal ram8_datum : std_logic_vector(31 downto 0);
  signal old_tag_datum : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal new_tag_datum : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal tag_datum : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);

  -- is cache miss occurs or not
  signal cache_miss_en0 : std_logic;
  signal rd_s : std_logic_vector(2 downto 0); -- selector for mux8

begin
  cache_decoder0 : cache_decoder port map(
    addr => a,
    tag => addr_tag,
    index => addr_index,
    offset => addr_offset
  );

  -- write data or load block from memory
  process(clk, rst, we, addr_index, addr_offset, wd_d1, wd_d2, wd_d3, wd_d4, wd_d5, wd_d6, wd_d7, wd_d8)
    variable idx : natural;
  begin
    -- initialization
    if rst = '1' then
      -- initialize with zeros
      valid_data <= (others => '0');
    elsif rising_edge(clk) then
      -- pull the notification from the memory
      if load_en = '1' then
        idx := to_integer(unsigned(addr_index));
        ram1_data(idx) <= wd_d1;
        ram2_data(idx) <= wd_d2;
        ram3_data(idx) <= wd_d3;
        ram4_data(idx) <= wd_d4;
        ram5_data(idx) <= wd_d5;
        ram6_data(idx) <= wd_d6;
        ram7_data(idx) <= wd_d7;
        ram8_data(idx) <= wd_d8;
      elsif we = '1' then
        idx := to_integer(unsigned(addr_index));
        case addr_offset is
          when "000" =>
            ram1_data(idx) <= wd;
          when "001" =>
            ram2_data(idx) <= wd;
          when "010" =>
            ram3_data(idx) <= wd;
          when "011" =>
            ram4_data(idx) <= wd;
          when "100" =>
            ram5_data(idx) <= wd;
          when "101" =>
            ram6_data(idx) <= wd;
          when "110" =>
            ram7_data(idx) <= wd;
          when "111" =>
            ram8_data(idx) <= wd;
          when others =>
            -- do nothing
        end case;
      end if;
    end if;
  end process;

  -- chech cache_hit or cache_miss
  process(addr_index, addr_offset, we)
    variable cache_miss_en00 : std_logic;
  begin
    cache_miss_en00 := '0';
    if we = '0' then
      if valid_data(to_integer(unsigned(addr_index))) = '1' then
        -- cache hit!
        if tag_data(to_integer(unsigned(addr_index))) = addr_tag then
          rd_s <= addr_offset;
        else
          -- cache miss
          cache_miss_en00 := '1';
        end if;
      end if;
    end if;
    cache_miss_en0 <= cache_miss_en00;
  end process;
  cache_miss_en <= cache_miss_en0;

  -- output rd signal
  ram1_datum <= ram1_data(to_integer(unsigned(addr_index)));
  ram2_datum <= ram2_data(to_integer(unsigned(addr_index)));
  ram3_datum <= ram3_data(to_integer(unsigned(addr_index)));
  ram4_datum <= ram4_data(to_integer(unsigned(addr_index)));
  ram5_datum <= ram5_data(to_integer(unsigned(addr_index)));
  ram6_datum <= ram6_data(to_integer(unsigned(addr_index)));
  ram7_datum <= ram7_data(to_integer(unsigned(addr_index)));
  ram8_datum <= ram8_data(to_integer(unsigned(addr_index)));

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

  -- if cache miss, send data to the memory
  old_tag_datum <= tag_data(to_integer(unsigned(addr_index))); -- for dump to the memory
  new_tag_datum <= addr_tag; -- for load from the memory

  mux2_tag : mux2 generic map(N=>CONST_CACHE_TAG_SIZE)
  port map (
    d0 => old_tag_datum,
    d1 => new_tag_datum,
    s => tag_s,
    y => tag_datum
  );

  -- save
  reg_rd_tag : flopr_en generic map (N=>CONST_CACHE_INDEX_SIZE)
  port map (
    clk => clk, rst => rst, en => cache_miss_en0,
    a => tag_datum,
    y => rd_tag
  );
  rd_index <= addr_index;

  reg_rd_d1 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en0,
    a => ram1_datum,
    y => rd_d1
  );

  reg_rd_d2 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en0,
    a => ram2_datum,
    y => rd_d2
  );

  reg_rd_d3 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en0,
    a => ram3_datum,
    y => rd_d3
  );

  reg_rd_d4 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en0,
    a => ram4_datum,
    y => rd_d4
  );

  reg_rd_d5 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en0,
    a => ram5_datum,
    y => rd_d5
  );

  reg_rd_d6 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en0,
    a => ram6_datum,
    y => rd_d6
  );

  reg_rd_d7 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en0,
    a => ram7_datum,
    y => rd_d8
  );

  reg_rd_d8 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en0,
    a => ram8_datum,
    y => rd_d8
  );
end architecture;
