library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity slt2_tb is
end entity;

architecture behavior of slt2_tb is
  component slt2 is
    generic (N: natural);
    port (
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;

  constant N : natural := 32;
  signal a : std_logic_vector(N-1 downto 0);
  signal y : std_logic_vector(N-1 downto 0);

begin
  uut : slt2 generic map (N=>N)
  port map (
    a => a,
    y => y
  );

  stim_proc: process
  begin
    wait for 20 ns;
    a <= X"00000FF1"; wait for 10 ns; assert y = X"00003FC4";
    a <= X"FFFF0000"; wait for 10 ns; assert y = X"FFFC0000";
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
