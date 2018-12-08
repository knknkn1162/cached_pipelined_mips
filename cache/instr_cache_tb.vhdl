library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cache_pkg.ALL;

entity instr_cache_tb is
end entity;

architecture testbench of instr_cache_tb is
  component instr_cache
    port (
      clk, rst, load : in std_logic;
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

  signal clk, rst, load, we : std_logic;
  signal a : std_logic_vector(31 downto 0);
  signal rd : std_logic_vector(31 downto 0);

  signal wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08 : std_logic_vector(31 downto 0);

  signal cache_miss_en, load_en : std_logic;
  constant all_x : std_logic_vector(31 downto 0) := (others => 'X');
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : instr_cache port map (
    clk => clk, rst => rst, load => load,
    a => a,
    rd => rd,
    load_en => load_en,
    wd01 => wd01, wd02 => wd02, wd03 => wd03, wd04 => wd04,
    wd05 => wd05, wd06 => wd06, wd07 => wd07, wd08 => wd08,
    cache_miss_en => cache_miss_en
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
    load <= '1'; wait until rising_edge(clk); load <= '0';
    wait for 1 ns;
    
    -- read with empty cache
    a <= X"00000008"; wait for 1 ns; assert rd = all_x; assert cache_miss_en = '1';

    a <= X"00000008";
    wd01 <= X"00000010"; wd02 <= X"00000011"; wd03 <= X"00000012"; wd04 <= X"00000013";
    wd05 <= X"00000014"; wd06 <= X"00000015"; wd07 <= X"00000016"; wd08 <= X"00000017";
    load_en <= '1';
    -- load from memory
    wait until rising_edge(clk); wait for 1 ns; load_en <= '0'; assert cache_miss_en = '0';

    -- wait for some time to initialize cache_miss_en 
    wait until rising_edge(clk); wait for 1 ns;
    wait until rising_edge(clk); wait for 1 ns;
    -- cache hit
    a <= X"00000008"; wait for 1 ns; assert rd = X"00000012"; assert cache_miss_en = '0';
    a <= X"0000000C"; wait for 1 ns; assert rd = X"00000013"; assert cache_miss_en = '0';

    -- cache miss
    a <= X"00001" & X"00C"; wait for 1 ns; assert rd = all_x; assert cache_miss_en = '1';
    -- cache hit
    a <= X"00000008"; we <= '0'; wait for 1 ns; assert rd = X"00000012"; assert cache_miss_en = '0';
    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
