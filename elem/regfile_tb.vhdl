library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity regfile_tb is
end entity;

architecture testbench of regfile_tb is
  component regfile
    port (
      clk, rst : in std_logic;
      -- 25:21(read)
      a1 : in std_logic_vector(4 downto 0);
      rd1 : out std_logic_vector(31 downto 0);
      -- 20:16(read)
      a2 : in std_logic_vector(4 downto 0);
      rd2 : out std_logic_vector(31 downto 0);
      wa : in std_logic_vector(4 downto 0);
      wd : in std_logic_vector(31 downto 0);
      we : in std_logic
    );
  end component;

  signal clk, rst, we : std_logic;
  signal a1, a2, wa : std_logic_vector(4 downto 0);
  signal rd1, rd2, wd : std_logic_vector(31 downto 0);
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : regfile port map (
    clk => clk, rst => rst,
    a1 => a1, rd1 => rd1,
    a2 => a2, rd2 => rd2,
    wa => wa, wd => wd, we => we
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
    -- write
    wa <= "10001"; wd <= X"FFFFFFFF"; we <= '1';
    wait until rising_edge(clk); wait for 1 ns; we <= '0';

    -- read
    a1 <= "10001"; wait for 1 ns; assert rd1 = X"FFFFFFFF";
    a2 <= "10001"; wait for 1 ns; assert rd2 = X"FFFFFFFF";
    a1 <= "10000"; wait for 1 ns; assert rd1 = X"00000000";
    -- overwrite
    wa <= "10001"; wd <= X"0000000F"; we <= '1';
    wait until rising_edge(clk); wait for 1 ns; we <= '0';
    -- check read
    a1 <= "10001"; wait for 1 ns; assert rd1 = X"0000000F";
    a2 <= "10001"; wait for 1 ns; assert rd2 = X"0000000F";
    
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;

end architecture;
