library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity load_controller_tb is
end entity;

architecture testbench of load_controller_tb is
  component load_controller
    port (
      clk, rst : in std_logic;
      load : out std_logic
    );
  end component;

  signal clk, rst, load : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : load_controller port map (
    clk => clk, rst => rst, load => load
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
    assert load = '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert load = '0';
    -- load = '0' forever until rst signal 
    wait until rising_edge(clk); wait for 1 ns;
    assert load = '0';

    -- assume that long reset
    wait for 1 ns; rst <= '1'; wait until rising_edge(clk);
    assert load = '1';
    wait for 1 ns; rst <= '0';
    assert load = '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert load = '0';
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
