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
      cache_miss_en : out std_logic;
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

begin
  uut : data_cach port map (
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
    a <= X"00000008"; we <= '0'; wait for clk_period*2; assert rd = X"00000000";
    -- write
    -- we <= '1'; a <= X"00000004"; wd <= X"0000000F"; wait for clk_period/2;
    -- we <= '1'; a <= X"00000008"; wd <= X"0000000E"; wait for clk_period;
    wait until falling_edge(clk);
    -- a <= X"00000008"; we <= '0'; wait for 1 ns; assert rd = X"0000000E";
    -- a <= X"00000004"; wait for 1 ns; assert rd = X"0000000F";


    -- wait until falling_edge(clk);
    -- -- read test
    -- a <= b"00" & X"0000000"; wait for 1 ns; assert rd /= X"00000000";
    -- a <= b"00" & X"0000001"; wait for 1 ns; assert rd /= X"00000000";

    -- wait until falling_edge(clk);
    -- -- write in ram
    -- we <= '1'; a <= b"00" & X"0000002"; wd <= X"FFFFFFFF"; wait for clk_period/2+ 1 ns;
    -- we <= '0'; wait for 1 ns; assert rd = X"FFFFFFFF";
    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
