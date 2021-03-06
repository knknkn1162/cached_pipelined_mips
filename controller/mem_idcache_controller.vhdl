library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_idcache_controller is
  port (
    clk, rst : in std_logic;
    instr_cache_miss_en, data_cache_miss_en : in std_logic;
    valid_flag, dirty_flag : in std_logic;
    tag_s : out std_logic; -- only in Cache2Mem in data_cache component
    instr_load_en, data_load_en : out std_logic;
    mem_we : out std_logic;
    suspend : out std_logic;
    idcache_addr_s : out std_logic
  );
end entity;

architecture behavior of mem_idcache_controller is
  component mem_cache_controller
    port (
      clk, rst : in std_logic;
      cache_miss_en : in std_logic;
      valid_flag, dirty_flag : in std_logic;
      mem2cache : out std_logic;
      tag_s : out std_logic;
      load_en : out std_logic;
      mem_we : out std_logic;
      suspend : out std_logic
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

  signal data_cache_miss_en0:  std_logic;
  signal valid_flag0, valid_flag1 : std_logic;
  signal dirty_flag0, dirty_flag1 : std_logic;
  signal cache_vector0, cache_vector1 : std_logic_vector(2 downto 0);
  signal both_cache_miss_en0, both_cache_miss_en1 : std_logic;
  signal instr_suspend, data_suspend : std_logic;
  signal icache_dcache_s : std_logic;
  signal mem2dcache0, mem2icache0 : std_logic;

begin
  both_cache_miss_en0 <= instr_cache_miss_en and data_cache_miss_en;
  cache_vector0 <= both_cache_miss_en0 & valid_flag & dirty_flag;
  reg_dcache_miss : flopr_en generic map (N=>3)
  port map (
    clk => clk, rst => rst, en => '1',
    a => cache_vector0,
    y => cache_vector1
  );
  dirty_flag1 <= cache_vector1(0);
  valid_flag1 <= cache_vector1(1);
  both_cache_miss_en1 <= cache_vector1(2);

  process(both_cache_miss_en1, both_cache_miss_en0, data_cache_miss_en, valid_flag, valid_flag1, dirty_flag, dirty_flag1)
  begin
    -- if collision between instr cache miss and data cache miss
    if (both_cache_miss_en1 or both_cache_miss_en0) = '1' then
      data_cache_miss_en0 <= both_cache_miss_en1;
      valid_flag0 <= valid_flag1;
      dirty_flag0 <= dirty_flag1;
    else
      data_cache_miss_en0 <= data_cache_miss_en;
      valid_flag0 <= valid_flag;
      dirty_flag0 <= dirty_flag;
    end if;
  end process;

  mem_dcache_controller : mem_cache_controller port map (
    clk => clk, rst => rst,
    cache_miss_en => data_cache_miss_en0,
    valid_flag => valid_flag0, dirty_flag => dirty_flag0,
    mem2cache => mem2dcache0,
    tag_s => tag_s,
    load_en => data_load_en,
    mem_we => mem_we,
    suspend => data_suspend
  );

  mem_icache_controller : mem_cache_controller port map (
    clk => clk, rst => rst,
    cache_miss_en => instr_cache_miss_en,
    -- instrcution cache doesn't have to write back to the memory
    valid_flag => '0', dirty_flag => '0',
    mem2cache => mem2icache0,
    -- tag_s => tag_s, -- in fact, always '1'(new)
    load_en => instr_load_en,
    -- mem_we => imem_we0 -- always '0'
    suspend => instr_suspend
  );
  suspend <= data_suspend or instr_suspend;

  process(mem2dcache0, mem2icache0)
  begin
    if mem2icache0 = '1' then
      idcache_addr_s <= '0';
    elsif mem2dcache0 = '1' then
      idcache_addr_s <= '1';
    end if;
  end process;
end architecture;
