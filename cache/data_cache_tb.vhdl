library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cache_pkg.ALL;

entity data_cache_tb is
end entity;

architecture testbench of data_cache_tb is
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

  signal clk, rst, we : std_logic;
  signal a : std_logic_vector(31 downto 0);
  signal wd, rd : std_logic_vector(31 downto 0);

  signal wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08 : std_logic_vector(31 downto 0);
  signal rd01, rd02, rd03, rd04, rd05, rd06, rd07, rd08 : std_logic_vector(31 downto 0);
  signal rd_tag : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal rd_index : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);

  signal tag_s, cache_miss_en, load_en, valid_flag : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;
  constant all_x : std_logic_vector(31 downto 0) := (others => 'X');

begin
  uut : data_cache port map (
    clk => clk, rst => rst,
    we => we,
    a => a,
    wd => wd,
    rd => rd,
    wd01 => wd01, wd02 => wd02, wd03 => wd03, wd04 => wd04,
    wd05 => wd05, wd06 => wd06, wd07 => wd07, wd08 => wd08,
    rd01 => rd01, rd02 => rd02, rd03 => rd03, rd04 => rd04,
    rd05 => rd05, rd06 => rd06, rd07 => rd07, rd08 => rd08,
    tag_s => tag_s,
    rd_tag => rd_tag,
    rd_index => rd_index,
    cache_miss_en => cache_miss_en, valid_flag => valid_flag,
    load_en => load_en
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
    rst <= '1'; wait for 1 ns; rst <= '0'; assert cache_miss_en = '0';

    -- read with empty cache
    a <= X"00000008"; wait for 1 ns; assert rd = all_x; assert cache_miss_en = '1'; assert valid_flag = '0';
    a <= X"00000008"; we <= '0'; wait for 1 ns; assert rd = all_x; assert cache_miss_en = '1'; assert valid_flag = '0';
    -- write with empty cache
    a <= X"00000008"; wd <= X"0000000F"; we <= '1'; wait for 1 ns; assert cache_miss_en = '1'; assert valid_flag = '0';

    a <= X"00000008";
    wd01 <= X"00000010"; wd02 <= X"00000011"; wd03 <= X"00000012"; wd04 <= X"00000013";
    wd05 <= X"00000014"; wd06 <= X"00000015"; wd07 <= X"00000016"; wd08 <= X"00000017";
    load_en <= '1';
    -- load from memory
    wait until rising_edge(clk); wait for 1 ns; load_en <= '0'; assert cache_miss_en = '0';

    -- cache read
    a <= X"00000008"; we <= '0'; wait for 1 ns; assert rd = X"00000012"; assert cache_miss_en = '0';
    a <= X"0000000C"; wait for 1 ns; assert rd = X"00000013"; assert cache_miss_en = '0';

    -- cache writeback
    a <= X"0000000C"; wd <= X"FFFFFFFF"; we <= '1'; wait until rising_edge(clk); wait for 1 ns;
    we <= '0'; wait for 1 ns; assert rd = X"FFFFFFFF"; assert cache_miss_en = '0';

    -- cache miss
    a <= X"00001" & X"00C"; we <= '0'; wait for 1 ns; assert rd = all_x; assert cache_miss_en = '1'; assert valid_flag = '1';
    -- cache hit
    a <= X"00000008"; we <= '0'; wait for 1 ns; assert rd = X"00000012"; assert cache_miss_en = '0';
    -- cache miss again
    a <= X"00001" & X"00C"; we <= '1'; wd <= X"FFFFFFFE"; wait for 1 ns; assert cache_miss_en = '1'; assert valid_flag = '1';

    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
