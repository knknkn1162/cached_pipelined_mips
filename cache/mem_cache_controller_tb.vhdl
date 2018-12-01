library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_cache_controller_tb is
end entity;


architecture testbench of mem_cache_controller_tb is
  component mem_cache_controller
    port (
      clk, rst : in std_logic;
      cache_miss_en : in std_logic;
      rd_en : in std_logic;
      tag_s : out std_logic;
      load_en : out std_logic;
      mem_we : out std_logic
    );
  end component;

  signal clk, rst : std_logic;
  signal cache_miss_en, tag_s, load_en : std_logic;
  signal mem_we , rd_en : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;

begin
  uut : mem_cache_controller port map (
    clk => clk, rst => rst,
    cache_miss_en => cache_miss_en, rd_en => rd_en,
    tag_s => tag_s,
    load_en => load_en,
    mem_we => mem_we
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


