library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2_tb is
end entity;

architecture testbench of mux2_tb is
  component mux2
    generic (N: integer);
    port (
      d0 : in std_logic_vector(N-1 downto 0);
      d1 : in std_logic_vector(N-1 downto 0);
      s : in std_logic;
      y : out std_logic_vector(N-1 downto 0)
        );
  end component;

  constant N : integer := 32;
  signal d0 : std_logic_vector(N-1 downto 0);
  signal d1 : std_logic_vector(N-1 downto 0);
  signal s : std_logic;
  signal y : std_logic_vector(N-1 downto 0);

begin
  uut : mux2 generic map (N => N)
    port map (
    d0 => d0,
    d1 => d1,
    s => s,
    y => y
  );

  stim_proc: process
  begin
    d0 <= X"00000001"; d1 <= X"00000010";
    wait for 20 ns;
    s <= '0'; wait for 10 ns; assert y <= X"00000001";
    s <= 'U'; wait for 10 ns; assert y <= X"00000001";
    s <= '-'; wait for 10 ns; assert y <= X"00000001";
    s <= '1'; wait for 10 ns; assert y <= X"00000010";
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
