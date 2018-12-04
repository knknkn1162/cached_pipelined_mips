library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux4_tb is
end entity;

architecture testbench of mux4_tb is
  component mux4
    generic (N : natural);
    port (
      d00 : in std_logic_vector(N-1 downto 0);
      d01 : in std_logic_vector(N-1 downto 0);
      d10 : in std_logic_vector(N-1 downto 0);
      d11 : in std_logic_vector(N-1 downto 0);
      s : in std_logic_vector(1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;

  constant N : natural := 32;
  constant all_x : std_logic_vector(N-1 downto 0) := (others => 'X');
  signal d00, d01, d10, d11, y : std_logic_vector(N-1 downto 0);
  signal s : std_logic_vector(1 downto 0);

begin
  uut : mux4 generic map (N=>32)
  port map (
    d00 => d00, d01 => d01, d10 => d10, d11 => d11,
    s => s,
    y => y
  );

  stim_proc : process
  begin
    wait for 20 ns;
    d00 <= X"00000001"; d01 <= X"00000010"; d10 <= X"00000100"; d11 <= X"00001000";
    s <= "00"; wait for 10 ns;
    assert y = X"00000001";

    s <= "01"; wait for 10 ns;
    assert y = X"00000010";

    s <= "10"; wait for 10 ns;
    assert y = X"00000100";

    s <= "11"; wait for 10 ns;
    assert y = X"00001000";

    -- when s is an undefined value, y is also undefined
    s <= "XX"; wait for 10 ns;
    assert y = all_x;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
  
end architecture;
