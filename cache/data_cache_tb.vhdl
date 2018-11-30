library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.tools_pkg.ALL;
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

  signal clk, rst, we : std_logic;
  signal a : std_logic_vector(31 downto 0);
  signal wd, rd : std_logic_vector(31 downto 0);

  signal wd_d1, wd_d2, wd_d3, wd_d4, wd_d5, wd_d6, wd_d7, wd_d8 : std_logic_vector(31 downto 0);
  signal rd_d1, rd_d2, rd_d3, rd_d4, rd_d5, rd_d6, rd_d7, rd_d8 : std_logic_vector(31 downto 0);
  signal rd_tag : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal rd_index : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);

  signal tag_s, cache_miss_en, load_en : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;
  constant filename : string := "./assets/mem/memfile.hex";
  constant all_x : std_logic_vector(31 downto 0) := (others => 'X');

begin
  uut : data_cache port map (
    clk => clk, rst => rst,
    we => we,
    a => a,
    wd => wd,
    rd => rd,
    wd_d1 => wd_d1, wd_d2 => wd_d2, wd_d3 => wd_d3, wd_d4 => wd_d4,
    wd_d5 => wd_d5, wd_d6 => wd_d6, wd_d7 => wd_d7, wd_d8 => wd_d8,
    rd_d1 => rd_d1, rd_d2 => rd_d2, rd_d3 => rd_d3, rd_d4 => rd_d4,
    rd_d5 => rd_d5, rd_d6 => rd_d6, rd_d7 => rd_d7, rd_d8 => rd_d8,
    tag_s => tag_s,
    rd_tag => rd_tag,
    rd_index => rd_index,
    cache_miss_en => cache_miss_en,
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
    rst <= '1'; wait for 1 ns; rst <= '0';

    -- read
    a <= X"00000008"; wait for 1 ns; assert rd = all_x;
    a <= X"00000008"; we <= '0'; wait for 1 ns; assert rd = all_x;
    -- write without cache
    a <= X"00000008"; wd <= X"0000000F"; we <= '1'; wait for 1 ns; assert cache_miss_en = '1';

    a <= X"00000008";
    wd_d1 <= X"00000010"; wd_d2 <= X"00000011"; wd_d3 <= X"00000012"; wd_d4 <= X"00000013";
    wd_d5 <= X"00000014"; wd_d6 <= X"00000015"; wd_d7 <= X"00000016"; wd_d8 <= X"00000017";
    load_en <= '1';
    -- load from memory
    wait until rising_edge(clk); wait for 1 ns; load_en <= '0';

    -- cache read
    a <= X"00000008"; we <= '0'; wait for 1 ns; assert rd = X"00000012";
    a <= X"0000000C"; wait for 1 ns; assert rd = X"00000013";

    -- cache writeback
    a <= X"0000000C"; wd <= X"FFFFFFFF"; we <= '1'; wait until rising_edge(clk); wait for 1 ns;
    we <= '0'; wait for 1 ns; assert rd = X"FFFFFFFF";



    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
