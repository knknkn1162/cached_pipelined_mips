library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_idcache_controller is
  port (
    clk, rst : in std_logic;
    instr_cache_miss_en, data_cache_miss_en : in std_logic;
    valid_flag : in std_logic;
    tag_s : out std_logic;
    instr_load_en, data_load_en : out std_logic;
    mem_we : out std_logic
  );
end entity;

architecture behavior of mem_idcache_controller is
  component mem_cache_controller
    port (
      clk, rst : in std_logic;
      cache_miss_en : in std_logic;
      valid_flag : in std_logic;
      tag_s : out std_logic;
      load_en : out std_logic;
      mem_we : out std_logic
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

  signal data_cache_miss_en0, data_cache_miss_en1, instr_cache_miss_en0 : std_logic_vector(0 downto 0);
  signal data_cache_miss_en_vector : std_logic_vector(0 downto 0);

begin
  data_cache_miss_en_vector <= data_cache_miss_en & "";
  reg_dcache_miss : flopr_en generic map (N=>1)
  port map (
    clk => clk, rst => rst,
    a => data_cache_miss_en_vector,
    y => data_cache_miss_en1
  );

  process(instr_cache_miss_en, data_cache_miss_en, data_cache_miss_en1)
  begin
    -- if collision between instr cache miss and data cache miss
    if (instr_cache_miss_en and data_cache_miss_en) = '1' then
      data_cache_miss_en0 <= data_cache_miss_en1;
    else
      data_cache_miss_en0 <= data_cache_miss_en & "";
    end if;
    instr_cache_miss_en0 <= instr_cache_miss_en & "";
  end process;

  mem_dcache_controller : mem_cache_controller port map (
    clk => clk, rst => rst,
    cache_miss_en => data_cache_miss_en0(0),
    valid_flag => valid_flag,
    tag_s => tag_s,
    load_en => data_load_en,
    mem_we => mem_we
  );

  mem_icache_controller : mem_cache_controller port map (
    clk => clk, rst => rst,
    cache_miss_en => instr_cache_miss_en0(0),
    -- instrcution cache doesn't have to write back to the memory
    valid_flag => '0',
    -- tag_s => tag_s, -- in fact, always '1'(new)
    load_en => instr_load_en
    -- mem_we => imem_we0 -- always '0'
  );
end architecture;
