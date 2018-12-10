library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bflopr_en_clr_tb is
end entity;

architecture testbench of bflopr_en_clr_tb is
  component bflopr_en_clr
    port (
      clk, rst, en, clr: in std_logic;
      a : in std_logic;
      y : out std_logic
    );
  end component;

  signal clk, rst, en, clr : std_logic;
  signal a, y : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : bflopr_en_clr port map (
    clk => clk, rst => rst, en => en, clr => clr,
    a => a, y => y
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
    rst <= '1'; wait for 1 ns; rst <= '0'; assert y = '0';
    a <= '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert y = '0';
    en <= '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert y = '1';
    clr <= '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert y = '0';

    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
