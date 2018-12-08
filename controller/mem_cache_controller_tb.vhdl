library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_cache_controller_tb is
end entity;


architecture testbench of mem_cache_controller_tb is
  component mem_cache_controller
    port (
      clk, rst : in std_logic;
      cache_miss_en : in std_logic;
      valid_flag : in std_logic;
      tag_s : out std_logic;
      load_en : out std_logic;
      mem_we : out std_logic;
      suspend : out std_logic
    );
  end component;

  signal clk, rst : std_logic;
  signal cache_miss_en, valid_flag, tag_s, load_en : std_logic;
  signal mem_we: std_logic;
  signal suspend : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : mem_cache_controller port map (
    clk => clk, rst => rst,
    cache_miss_en => cache_miss_en, valid_flag => valid_flag,
    tag_s => tag_s,
    load_en => load_en,
    mem_we => mem_we,
    suspend => suspend
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
    wait for clk_period*3;
    assert suspend /= '1';
    -- NormalS
    cache_miss_en <= '1'; valid_flag <= '0'; wait for 1 ns; assert suspend = '1';
    wait until rising_edge(clk); wait for 1 ns; cache_miss_en <= '0';
    -- Mem2CacheS
    assert mem_we = '0'; assert tag_s = '1'; assert load_en = '0'; assert suspend = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- CacheWriteBackS
    assert mem_we = '0'; assert load_en = '1'; assert suspend = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- NormalS
    assert mem_we = '0'; assert load_en = '0'; assert suspend = '0';
    wait for clk_period*5;
    assert mem_we = '0'; assert load_en = '0'; assert suspend = '0';
    cache_miss_en <= '1'; valid_flag <= '1'; wait for 1 ns; assert suspend = '1';
    wait until rising_edge(clk); wait for 1 ns; cache_miss_en <= '0';

    -- Cache2MemS
    assert mem_we = '1'; assert tag_s = '0'; assert load_en = '0'; assert suspend = '1';
    wait until rising_edge(clk); wait for 1 ns; cache_miss_en <= '0';
    -- Mem2CacheS
    assert mem_we = '0'; assert tag_s = '1'; assert load_en = '0'; assert suspend = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;


