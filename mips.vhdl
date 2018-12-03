library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

entity mips is
  generic(memfile : string);
  port (
    clk, rst, load : in std_logic;
    data_cache_a : in std_logic_vector(31 downto 0);
    instr_cache_a : in std_logic_vector(31 downto 0);
    we : in std_logic;
    wd : in std_logic_vector(31 downto 0);
    instr_cache_rd : out std_logic_vector(31 downto 0);
    data_cache_rd : out std_logic_vector(31 downto 0);
    -- scan
    data_cache_miss_en, instr_cache_miss_en : out std_logic;
    instr_load_en, data_load_en : out std_logic;
    suspend_flag : out std_logic
  );
end entity;

architecture behavior of mips is
  component mem_idcache_controller
    port (
      clk, rst : in std_logic;
      instr_cache_miss_en, data_cache_miss_en : in std_logic;
      valid_flag : in std_logic;
      tag_s : out std_logic;
      instr_load_en, data_load_en : out std_logic;
      mem_we : out std_logic;
      suspend_flag : out std_logic
    );
  end component;

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

  component instr_cache
    port (
      clk, rst : in std_logic;
      -- program counter is 4-byte aligned
      a : in std_logic_vector(31 downto 0);
      rd : out std_logic_vector(31 downto 0);
      -- when cache miss
      -- -- pull load from the memory
      load_en : in std_logic;
      wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08 : in std_logic_vector(31 downto 0);
      -- push cache miss to the memory
      cache_miss_en : out std_logic
    );
  end component;

  component data_cache
    port (
      clk, rst : in std_logic;
      we : in std_logic;
      -- program counter is 4-byte aligned
      a : in std_logic_vector(31 downto 0);
      wd : in std_logic_vector(31 downto 0);
      tag_s : in std_logic;
      rd : out std_logic_vector(31 downto 0);
      wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08 : in std_logic_vector(31 downto 0);
      rd_tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      rd_index : out std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
      rd01, rd02, rd03, rd04, rd05, rd06, rd07, rd08 : out std_logic_vector(31 downto 0);
      -- push cache miss to the memory
      cache_miss_en : out std_logic;
      valid_flag : out std_logic;
      -- pull load from the memory
      load_en : in std_logic
    );
  end component;

  signal dcache2mem_d1, dcache2mem_d2, dcache2mem_d3, dcache2mem_d4, dcache2mem_d5, dcache2mem_d6, dcache2mem_d7, dcache2mem_d8 : std_logic_vector(31 downto 0);
  signal mem2cache_d1, mem2cache_d2, mem2cache_d3, mem2cache_d4, mem2cache_d5, mem2cache_d6, mem2cache_d7, mem2cache_d8 : std_logic_vector(31 downto 0);
  signal tag0 : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal index0 : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
  signal tag_s0 : std_logic;
  signal data_cache_miss_en0, instr_cache_miss_en0: std_logic;
  signal mem_we0, valid_flag0 : std_logic;
  signal instr_load_en0, data_load_en0 : std_logic;
begin

  mem_idcache_controller0 : mem_idcache_controller port map (
    clk => clk, rst => rst,
    instr_cache_miss_en => instr_cache_miss_en0, data_cache_miss_en => data_cache_miss_en0,
    valid_flag => valid_flag0,
    tag_s => tag_s0,
    instr_load_en => instr_load_en0, data_load_en => data_load_en0,
    mem_we => mem_we0,
    suspend_flag => suspend_flag
  );
  instr_load_en <= instr_load_en0;
  data_load_en <= data_load_en0;

  mem0 : mem generic map(filename=>memfile, BITS=>14)
  port map (
    clk => clk, rst => rst, load => load,
    we => mem_we0,
    tag => tag0, index => index0,
    -- data cache only
    wd1 => dcache2mem_d1, wd2 => dcache2mem_d2, wd3 => dcache2mem_d3, wd4 => dcache2mem_d4,
    wd5 => dcache2mem_d5, wd6 => dcache2mem_d6, wd7 => dcache2mem_d7, wd8 => dcache2mem_d8,

    rd1 => mem2cache_d1, rd2 => mem2cache_d2, rd3 => mem2cache_d3, rd4 => mem2cache_d4,
    rd5 => mem2cache_d5, rd6 => mem2cache_d6, rd7 => mem2cache_d7, rd8 => mem2cache_d8
  );

  instr_cache0 : instr_cache port map (
    clk => clk, rst => rst,
    a => instr_cache_a,
    rd => instr_cache_rd,
    load_en => instr_load_en0,
    wd01 => mem2cache_d1, wd02 => mem2cache_d2, wd03 => mem2cache_d3, wd04 => mem2cache_d4,
    wd05 => mem2cache_d5, wd06 => mem2cache_d6, wd07 => mem2cache_d7, wd08 => mem2cache_d8,
    cache_miss_en => instr_cache_miss_en0
  );
  instr_cache_miss_en <= instr_cache_miss_en0;

  data_cache0 : data_cache port map (
    clk => clk, rst => rst,
    we => we,
    a => data_cache_a,
    wd => wd,
    tag_s => tag_s0,
    rd => data_cache_rd,
    load_en => data_load_en0,
    wd01 => mem2cache_d1, wd02 => mem2cache_d2, wd03 => mem2cache_d3, wd04 => mem2cache_d4,
    wd05 => mem2cache_d5, wd06 => mem2cache_d6, wd07 => mem2cache_d7, wd08 => mem2cache_d8,
    rd_tag => tag0, rd_index => index0,
    rd01 => dcache2mem_d1, rd02 => dcache2mem_d2, rd03 => dcache2mem_d3, rd04 => dcache2mem_d4,
    rd05 => dcache2mem_d5, rd06 => dcache2mem_d6, rd07 => dcache2mem_d7, rd08 => dcache2mem_d8,
    cache_miss_en => data_cache_miss_en0, valid_flag => valid_flag0
  );
  data_cache_miss_en <= data_cache_miss_en0;
end architecture;
