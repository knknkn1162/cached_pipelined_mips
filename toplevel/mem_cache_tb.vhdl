library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_cache_tb is
end entity;

architecture testbench of mem_cache_tb is
  component mem_cache
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
  end component;

  constant memfile : string := "./assets/mem/memfile.hex";
  signal clk, rst, load : std_logic;
  signal a : std_logic_vector(31 downto 0);
  signal dcache_we : std_logic;
  signal wd : std_logic_vector(31 downto 0);
  signal rd : std_logic_vector(31 downto 0);

  signal cache_miss_en, mem_we, load_en : std_logic;

  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : mem_cache generic map (memfile=>memfile)
  port map (
    clk => clk, rst => rst, load => load,
    a => a,
    dcache_we => dcache_we,
    wd => wd,
    rd => rd,
    cache_miss_en => cache_miss_en, mem_we => mem_we, load_en => load_en
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
    -- cache miss
    a <= X"00000001"; dcache_we <= '0'; wait for 1 ns;
    assert cache_miss_en = '1';
    wait until rising_edge(clk); wait for 1 ns;

    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
