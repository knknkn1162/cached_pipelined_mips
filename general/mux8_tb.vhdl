library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux8_tb is
end entity;

architecture testbench of mux8_tb is
  component mux8
    generic(N : integer);
    port (
      d000 : in std_logic_vector(N-1 downto 0);
      d001 : in std_logic_vector(N-1 downto 0);
      d010 : in std_logic_vector(N-1 downto 0);
      d011 : in std_logic_vector(N-1 downto 0);
      d100 : in std_logic_vector(N-1 downto 0);
      d101 : in std_logic_vector(N-1 downto 0);
      d110 : in std_logic_vector(N-1 downto 0);
      d111 : in std_logic_vector(N-1 downto 0);
      s : in std_logic_vector(2 downto 0);
      y : out std_logic_vector(N-1 downto 0)
        );
  end component;

  signal N : natural := 8;
  signal d000 : std_logic_vector(N-1 downto 0);
  signal d001 : std_logic_vector(N-1 downto 0);
  signal d010 : std_logic_vector(N-1 downto 0);
  signal d011 : std_logic_vector(N-1 downto 0);
  signal d100 : std_logic_vector(N-1 downto 0);
  signal d101 : std_logic_vector(N-1 downto 0);
  signal d110 : std_logic_vector(N-1 downto 0);
  signal d111 : std_logic_vector(N-1 downto 0);
  signal s : std_logic_vector(2 downto 0);
  signal y : std_logic_vector(N-1 downto 0);

begin
  uut : mux8 generic map (N=>N)
  port map (
    d000 => d000,
    d001 => d001,
    d010 => d010,
    d011 => d011,
    d100 => d100,
    d101 => d101,
    d110 => d110,
    d111 => d111,
    s => s,
    y => y
  );

  stim_proce : process
  begin
    wait for 20 ns;
    d000 <= X"01"; s <= "000"; wait for 10 ns; assert y = X"01";
    s <= "XXX"; wait for 10 ns; assert y = "XXXXXXXX";
    d001 <= X"02"; s <= "001"; wait for 10 ns; assert y = X"02";
    d010 <= X"03"; s <= "010"; wait for 10 ns; assert y = X"03";
    d011 <= X"04"; s <= "011"; wait for 10 ns; assert y = X"04";
    d100 <= X"05"; s <= "100"; wait for 10 ns; assert y = X"05";
    d101 <= X"06"; s <= "101"; wait for 10 ns; assert y = X"06";
    d110 <= X"07"; s <= "110"; wait for 10 ns; assert y = X"07";
    d111 <= X"08"; s <= "111"; wait for 10 ns; assert y = X"08";

    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
