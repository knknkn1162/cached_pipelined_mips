library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.tools_pkg.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tools_pkg_tb is
end entity;

architecture testbench of tools_pkg_tb is
  signal output : std_logic_vector(3 downto 0);
begin
  stim_proc : process
  begin
    wait for 20 ns;
    output <= char2bits('c'); wait for 10 ns; assert output = X"C";
    output <= char2bits('C'); wait for 10 ns; assert output = X"C";
    output <= char2bits('9'); wait for 10 ns; assert output = X"9";
    output <= char2bits('G'); wait for 10 ns; assert output = X"0";
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
