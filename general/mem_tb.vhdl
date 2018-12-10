library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cache_pkg.ALL;

entity mem_tb is
end entity;

architecture testbench of mem_tb is
  component mem
    generic(filename : string; BITS : natural);
    port (
      clk, rst, load : in std_logic;
      -- we='1' when transport cache2mem
      we : in std_logic;
      tag : in cache_tag_vector;
      index : in cache_index_vector;
      wd1, wd2, wd3, wd4, wd5, wd6, wd7, wd8 : in std_logic_vector(31 downto 0);
      rd1, rd2, rd3, rd4, rd5, rd6, rd7, rd8 : out std_logic_vector(31 downto 0)
    );
  end component;

  constant BITS : natural := 10;
  constant filename : string := "./assets/memfile.hex";

  signal clk, rst, load, we : std_logic;
  signal tag : cache_tag_vector;
  signal index : cache_index_vector;
  signal wd1, wd2, wd3, wd4, wd5, wd6, wd7, wd8 : std_logic_vector(31 downto 0);
  signal rd1, rd2, rd3, rd4, rd5, rd6, rd7, rd8 : std_logic_vector(31 downto 0);
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : mem generic map (filename=>filename, BITS=>BITS)
  port map (
    clk => clk, rst => rst, load => load,
    we => we,
    tag => tag, index => index,
    wd1 => wd1, wd2 => wd2, wd3 => wd3, wd4 => wd4, wd5 => wd5, wd6 => wd6, wd7 => wd7, wd8 => wd8,
    rd1 => rd1, rd2 => rd2, rd3 => rd3, rd4 => rd4, rd5 => rd5, rd6 => rd6, rd7 => rd7, rd8 => rd8
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

    -- sync
    load <= '1'; wait for clk_period/2; load <= '0';
    wait until falling_edge(clk);
    -- read test
    tag <= X"00000"; index <= "0000000"; we <= '0'; wait for clk_period*2 + 1 ns;
    assert rd1 = X"20020005"; assert rd2 = X"2003000c"; assert rd3 = X"2067fff7"; assert rd4 = X"00e22025"; assert rd5 = X"00642824"; assert rd6 = X"00a42820"; assert rd7 = X"10a7000a"; assert rd8 = X"0064202a";

    wait until falling_edge(clk);
    -- write in ram
    we <= '1'; tag <= X"00000"; index <= "0000000";
    wd1 <= X"FFFFFFFF"; wd2 <= X"FFFFFFFE"; wd3 <= X"FFFFFFFD"; wd4 <= X"FFFFFFFC"; wd5 <= X"FFFFFFFB"; wd6 <= X"FFFFFFFA"; wd7 <= X"FFFFFFF9"; wd8 <= X"FFFFFFF8";
    wait for clk_period/2+ 1 ns;
    -- after writeback
    we <= '0'; wait for clk_period;
    assert rd1 = X"FFFFFFFF"; assert rd2 = X"FFFFFFFE"; assert rd3 = X"FFFFFFFD"; assert rd4 = X"FFFFFFFC"; assert rd5 = X"FFFFFFFB"; assert rd6 = X"FFFFFFFA"; assert rd7 = X"FFFFFFF9"; assert rd8 = X"FFFFFFF8";
    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
