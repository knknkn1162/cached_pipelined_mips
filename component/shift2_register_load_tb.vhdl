library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity shift2_register_load_tb is
end entity;

architecture testbench of shift2_register_load_tb is
  component shift2_register_load is
    generic(N : natural);
    port (
      clk, rst : in std_logic;
      en0, en1 : in std_logic;
      s1 : in std_logic;
      a0 : in std_logic_vector(N-1 downto 0);
      load1 : in std_logic_vector(N-1 downto 0);
      a1, a2 : out std_logic_vector(N-1 downto 0)
    );
  end component;

  constant N : natural := 32;
  signal clk, rst : std_logic;
  signal en0, en1 : std_logic;
  signal s1 : std_logic;
  signal a0, load1, a1, a2 : std_logic_vector(N-1 downto 0);
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : shift2_register_load generic map (N=>32)
  port map (
    clk => clk, rst => rst,
    en0 => en0, en1 => en1,
    s1 => s1,
    a0 => a0,
    load1 => load1,
    a1 => a1, a2 => a2
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
    -- wait for some time..
    wait for clk_period*5;
    en0 <= '1'; en1 <= '1'; s1 <= '0';
    a0 <= X"00000001";
    wait until rising_edge(clk); wait for 1 ns;
    assert a1 = X"00000001";
    a0 <= X"00000002";
    wait until rising_edge(clk); wait for 1 ns;
    assert a1 <= X"00000002"; assert a2 <= X"00000001";

    a0 <= X"00000003"; load1 <= X"FFFFFFFF"; s1 <= '1';
    wait until rising_edge(clk); s1 <= '0'; wait for 1 ns;
    assert a1 = X"00000003"; assert a2 = X"FFFFFFFF";

    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
