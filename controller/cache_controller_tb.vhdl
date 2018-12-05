library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

entity cache_controller_tb is
end entity;

architecture testbench of cache_controller_tb is
  component cache_controller
    port (
      clk, rst : in std_logic;
      cache_valid : in std_logic;
      addr_tag, cache_tag : in std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      addr_index : in std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
      addr_offset : in std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);
      cache_miss_en : out std_logic;
      cache_valid_flag : out std_logic;
      rd_s : out std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0)
    );
  end component;

  signal clk, rst : std_logic;
  signal cache_valid : std_logic;
  signal addr_tag, cache_tag : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal addr_index : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
  signal addr_offset : std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);
  signal cache_miss_en, cache_valid_flag : std_logic;
  signal rd_s : std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : cache_controller port map (
    clk => clk, rst => rst,
    cache_valid => cache_valid,
    addr_tag => addr_tag, cache_tag => cache_tag,
    addr_index => addr_index, addr_offset => addr_offset,
    cache_miss_en => cache_miss_en,
    cache_valid_flag => cache_valid_flag,
    rd_s => rd_s
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
    addr_index <= "0000001"; cache_valid <= '1';
    -- if addr_tag = cache_tag
    addr_tag <= X"00000"; cache_tag <= X"00000";
    addr_offset <= "010";
    wait for 1 ns;
    assert cache_miss_en = '0'; assert rd_s = "010";
    wait until rising_edge(clk); wait for 1 ns;

    -- if addr_tag /= cache_tag & cache_valid = '1' -> cache_miss
    addr_tag <= X"00000"; cache_tag <= X"00001"; cache_valid <= '1';
    wait for 1 ns;
    assert cache_miss_en = '1'; assert cache_valid_flag = '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert cache_miss_en = '0';
    wait until rising_edge(clk); wait for 1 ns;

    -- if addr_tag /= cache_tag & cache_valid = '0' -> cache_miss
    addr_tag <= X"00001"; cache_tag <= X"00000"; cache_valid <= '0';
    wait for 1 ns;
    assert cache_miss_en = '1'; assert cache_valid_flag = '0';
    wait until rising_edge(clk); wait for 1 ns;
    assert cache_miss_en = '0';


    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
