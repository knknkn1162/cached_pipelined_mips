library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_cache_tb is
end entity;

architecture testbench of mem_cache_tb is
  component mem_cache
    generic(memfile : string);
    port (
      clk, rst, load : in std_logic;
      a : in std_logic_vector(31 downto 0);
      wd : in std_logic_vector(31 downto 0);
      rd : out std_logic_vector(31 downto 0)
    );
  end component;

  constant memfile : string := "./assets/mem/memfile.hex";
  signal clk, rst, load : std_logic;
  signal a : std_logic_vector(31 downto 0);
  signal wd : std_logic_vector(31 downto 0);
  signal rd : std_logic_vector(31 downto 0);

  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : mem_cache generic map (memfile=>memfile)
  port map (
    clk => clk, rst => rst, load => load,
    a => a,
    wd => wd,
    rd => rd
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
    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
