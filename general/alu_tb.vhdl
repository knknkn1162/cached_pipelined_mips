library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity alu_tb is
end entity;

architecture testbench of alu_tb is
  component alu
    port (
      a, b : in std_logic_vector(31 downto 0);
      f : in alucont_type;
      y : out std_logic_vector(31 downto 0)
    );
  end component;

  signal a, b, y : std_logic_vector(31 downto 0);
  signal f : alucont_type;

begin
  uut : alu port map (
    a => a, b => b,
    y => y,
    f => f
  );

  stim_proc : process
  begin
    wait for 20 ns;

    -- test sgn
    a <= X"00000001"; b <= X"00000000"; f <= "111"; wait for 10 ns; assert y = X"0000000" & "0000";
    a <= X"00000001"; b <= X"00000001"; f <= "111"; wait for 10 ns; assert y = X"0000000" & "0000";
    a <= X"00000001"; b <= X"00000002"; f <= "111"; wait for 10 ns; assert y = X"0000000" & "0001";
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
