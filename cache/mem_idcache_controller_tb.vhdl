library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_idcache_controller_tb is
end entity;

architecture testbench of mem_idcache_controller_tb is
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

  signal clk, rst : std_logic;
  signal instr_cache_miss_en, data_cache_miss_en : std_logic;
  signal valid_flag : std_logic;
  signal tag_s, instr_load_en, data_load_en, mem_we : std_logic;
  signal suspend_flag : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : mem_idcache_controller port map (
    clk => clk, rst => rst,
    instr_cache_miss_en => instr_cache_miss_en,
    data_cache_miss_en => data_cache_miss_en,
    valid_flag => valid_flag,
    tag_s => tag_s,
    instr_load_en => instr_load_en, data_load_en => data_load_en,
    mem_we => mem_we,
    suspend_flag => suspend_flag
  );

  clk_process: process
  begin
    while not stop loop
      clk <= '0'; wait for clk_period/2;
      clk <= '1'; wait for clk_period/2;
    end loop;
    wait;
  end process;

  stim_proc : process
  begin
    wait for clk_period;
    rst <= '1'; wait for 1 ns; rst <= '0';
    -- wait for some time..
    wait for clk_period*2;
    assert suspend_flag = '0';
    -- when the cache miss occurs in both instruction cache & data cache
    -- (instr : NormalS, mem: NormalS)
    instr_cache_miss_en <= '1'; data_cache_miss_en <= '1'; valid_flag <= '1';
    wait for 1 ns; assert suspend_flag = '1';
    wait until rising_edge(clk);
    instr_cache_miss_en <= '0'; data_cache_miss_en <= '0'; valid_flag <= '1';
    wait for 1 ns;

    -- (instr: Mem2CacheS, mem : NormalS)
    assert tag_s = '1'; assert mem_we = '0'; assert instr_load_en = '0'; assert data_load_en = '0'; assert suspend_flag = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- (instr: CacheWriteBackS, mem : Cache2MemS)
    assert tag_s = '0'; assert mem_we = '1'; assert instr_load_en = '1'; assert data_load_en = '0'; assert suspend_flag = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- (instr: NormalS, mem : Mem2CacheS)
    assert tag_s = '1'; assert mem_we = '0'; assert instr_load_en = '0'; assert data_load_en = '0'; assert suspend_flag = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- (instr: NormalS, mem : CacheWriteBackS)
    assert tag_s = '1'; assert mem_we = '0'; assert instr_load_en = '0'; assert data_load_en = '1'; assert suspend_flag = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- (instr : NormalS, mem: NormalS)
    assert tag_s = '1'; assert mem_we = '0'; assert instr_load_en = '0'; assert data_load_en = '0'; assert suspend_flag = '0';

    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
