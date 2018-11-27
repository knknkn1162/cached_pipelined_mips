library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.tools_pkg.ALL;

entity data_cache_tb is
end entity;

architecture testbench of data_cache_tb is
  component data_cache
    generic(filename : string);
    port (
      clk, rst, load : in std_logic;
      we : in std_logic;
      -- program counter is 4-byte aligned
      a : in std_logic_vector(29 downto 0);
      wd : in std_logic_vector(31 downto 0);
      rd : out std_logic_vector(31 downto 0)
    );
  end component;

  signal clk, rst, load, we : std_logic;
  signal a : std_logic_vector(29 downto 0);
  signal wd, rd : std_logic_vector(31 downto 0);
  constant clk_period : time := 10 ns;
  signal stop : boolean;
  constant filename : string := "./assets/mem/memfile.hex";

begin
  uut : data_cache generic map (filename=>filename)
  port map (
    clk => clk, rst => rst, load => load,
    we => we,
    a => a,
    wd => wd,
    rd => rd
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
    load <= '1'; wait for 1 ns;
    wait for clk_period/2;
    load <= '0';
    we <= '0';
    wait until falling_edge(clk);
    -- read test
    a <= b"00" & X"0000000"; wait for 1 ns; assert rd /= X"00000000";
    a <= b"00" & X"0000001"; wait for 1 ns; assert rd /= X"00000000";

    wait until falling_edge(clk);
    -- write in ram
    we <= '1'; a <= b"00" & X"0000002"; wd <= X"FFFFFFFF"; wait for clk_period/2+ 1 ns;
    we <= '0'; wait for 1 ns; assert rd = X"FFFFFFFF";
    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
