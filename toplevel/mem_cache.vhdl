library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

entity mem_cache is
  generic(memfile : string);
  port (
    clk, rst, load : in std_logic;
    a : in std_logic_vector(31 downto 0);
    dcache_we : in std_logic;
    wd : in std_logic_vector(31 downto 0);
    rd : out std_logic_vector(31 downto 0);
    -- scan
    cache_miss_en : out std_logic;
    mem_we : out std_logic;
    load_en : out std_logic
  );
end entity;

architecture behavior of mem_cache is
  component mem
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
  end component;

  component data_cache
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
      -- push cache miss to the memory
      cache_miss_en : out std_logic;
      -- pull load from the memory
      load_en : in std_logic
    );
  end component;

  type statetype is (
    NormalS, Cache2MemS, Mem2CacheS, CacheWriteBackS
  );

  signal state, nextstate : statetype;

  signal dcache2mem_d1, dcache2mem_d2, dcache2mem_d3, dcache2mem_d4, dcache2mem_d5, dcache2mem_d6, dcache2mem_d7, dcache2mem_d8 : std_logic_vector(31 downto 0);
  signal mem2dcache_d1, mem2dcache_d2, mem2dcache_d3, mem2dcache_d4, mem2dcache_d5, mem2dcache_d6, mem2dcache_d7, mem2dcache_d8 : std_logic_vector(31 downto 0);
  signal tag0 : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal index0 : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
  signal tag_s0 : std_logic;
  signal mem_we0, cache_miss_en0, load_en0 : std_logic;
begin
  -- control enable signal
  process(clk, rst, nextstate)
  begin
    if rst = '1' then
      state <= NormalS;
    elsif rising_edge(clk) then
      state <= nextstate;
    end if;
  end process;

  process(state, cache_miss_en0)
  begin
    case state is
      when NormalS =>
        if cache_miss_en0 = '1' then
          nextstate <= Cache2MemS;
        else
          nextstate <= NormalS;
        end if;
      when Cache2MemS =>
        nextstate <= Mem2CacheS;
      when Mem2CacheS =>
        nextstate <= CacheWriteBackS;
      when CacheWriteBackS =>
        nextstate <= NormalS;
    end case;
  end process;

  process(state)
  begin
    case state is
      -- tranform cache to memory with old tag
      when Mem2CacheS =>
        tag_s0 <= '0';
      -- transform mem to cache with new tag
      when Cache2MemS =>
        tag_s0 <= '1';
      when others =>
        -- do nothing
    end case;
  end process;

  process(state)
  begin
    if state = Cache2MemS then
      mem_we0 <= '1';
    else
      mem_we0 <= '0';
    end if;
  end process;
  mem_we <= mem_we0; -- for scan

  process(state)
  begin
    if state = CacheWriteBackS then
      load_en0 <= '1';
    else
      load_en0 <= '0';
    end if;
  end process;
  load_en <= load_en0; -- for scan

  mem0 : mem generic map(filename=>memfile, BITS=>10)
  port map (
    clk => clk, rst => rst, load => load,
    we => mem_we0,
    tag => tag0, index => index0,
    wd1 => dcache2mem_d1, wd2 => dcache2mem_d2, wd3 => dcache2mem_d3, wd4 => dcache2mem_d4,
    wd5 => dcache2mem_d5, wd6 => dcache2mem_d6, wd7 => dcache2mem_d7, wd8 => dcache2mem_d8,

    rd1 => mem2dcache_d1, rd2 => mem2dcache_d2, rd3 => mem2dcache_d3, rd4 => mem2dcache_d4,
    rd5 => mem2dcache_d5, rd6 => mem2dcache_d6, rd7 => mem2dcache_d7, rd8 => mem2dcache_d8
  );

  data_cache0 : data_cache port map (
    clk => clk, rst => rst,
    we => dcache_we,
    a => a,
    wd => wd,
    rd => rd,
    wd_d1 => mem2dcache_d1, wd_d2 => mem2dcache_d2, wd_d3 => mem2dcache_d3, wd_d4 => mem2dcache_d4,
    wd_d5 => mem2dcache_d5, wd_d6 => mem2dcache_d6, wd_d7 => mem2dcache_d7, wd_d8 => mem2dcache_d8,
    rd_d1 => dcache2mem_d1, rd_d2 => dcache2mem_d2, rd_d3 => dcache2mem_d3, rd_d4 => dcache2mem_d4,
    rd_d5 => dcache2mem_d5, rd_d6 => dcache2mem_d6, rd_d7 => dcache2mem_d7, rd_d8 => dcache2mem_d8,

    rd_tag => tag0, rd_index => index0,
    cache_miss_en => cache_miss_en0,
    load_en => load_en0,
    tag_s => tag_s0
  );
  cache_miss_en <= cache_miss_en0;
end architecture;
