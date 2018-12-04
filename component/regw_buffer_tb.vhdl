library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity regw_buffer_tb is
end entity;

architecture behavior of regw_buffer_tb is
  component regw_buffer is
    port (
      clk, rst : in std_logic;
      wa0 : in reg_vector;
      wd0 : in std_logic_vector(31 downto 0);
      we0 : in std_logic;
      wa1 : in reg_vector;
      wd1 : in std_logic_vector(31 downto 0);
      we1 : in std_logic;
      -- for register WB
      wa2 : out reg_vector;
      wd2 : out std_logic_vector(31 downto 0);
      we2 : out std_logic;
      -- search for forwarding
      ra1 : in reg_vector;
      ra2 : in reg_vector;
      rd1 : out std_logic_vector(31 downto 0);
      rd2 : out std_logic_vector(31 downto 0)
    );
  end component;

  -- skip
  signal clk, rst : std_logic;
  signal wa0, wa1, wa2, ra1, ra2 : reg_vector;
  signal wd0, wd1, wd2, rd1, rd2 : std_logic_vector(31 downto 0);
  signal we0, we1, we2, s1 : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : regw_buffer port map (
    clk => clk, rst => rst,
    wa0 => wa0, wd0 => wd0, we0 => we0,
    wa1 => wa1, wd1 => wd1, we1 => we1,
    wa2 => wa2, wd2 => wd2, we2 => we2,
    ra1 => ra1, ra2 => ra2,
    rd1 => rd1, rd2 => rd2
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
    wa0 <= "00001"; wd0 <= X"00000003"; we0 <= '1';
    wa1 <= "00010"; wd1 <= X"00000005"; we1 <= '1';
    wait until rising_edge(clk);
    we1 <= '0';
    wa0 <= "00011"; wd0 <= X"0000000F"; we0 <= '1';
    wait for 1 ns;
    assert wa2 = "00010"; assert wd2 = X"00000005"; assert we2 = '1';
    ra1 <= "00010"; wait for 1 ns; assert rd1 = X"00000005";
    ra2 <= "00011"; wait for 1 ns; assert rd2 = X"0000000F";
    wait until rising_edge(clk);
    we0 <= '0';
    wait for 1 ns;
    assert wa2 = "00001"; assert wd2 = X"00000003"; assert we2 = '1';
    ra1 <= "00010"; wait for 1 ns; assert is_X(rd1);
    ra2 <= "00011"; wait for 1 ns; assert rd2 = X"0000000F";
    wait until rising_edge(clk); wait for 1 ns;
    assert wa2 = "00011"; assert wd2 = X"0000000F"; assert we2 = '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert we2 = '0';

    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
