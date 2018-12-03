library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flopr_en_tb is
end entity;

architecture testbench of flopr_en_tb is
  component flopr_en
    generic(N : natural := 32);
    port (
      clk, rst, en: in std_logic;
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
        );
  end component;

  signal clk, rst, en : std_logic;
  signal N : natural := 32;
  signal a, y : std_logic_vector(N-1 downto 0);
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : flopr_en generic map(N=>N)
  port map (
    clk => clk, rst => rst, en => en,
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
    rst <= '1'; wait for 1 ns; rst <= '0'; assert y = X"00000000";
    a <= X"00000001"; wait for clk_period/2; assert y = X"00000000";
    en <= '1'; wait for clk_period; assert y = X"00000001";
    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
