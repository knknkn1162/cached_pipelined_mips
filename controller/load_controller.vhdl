library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity load_controller is
  port (
    clk, rst : in std_logic;
    load : out std_logic
  );
end entity;

architecture behavior of load_controller is
  signal load0 : std_logic;
begin
  process(clk, rst)
  begin
    if rst = '1' then
      load0 <= '1';
    elsif rising_edge(clk) then
      load0 <= '0';
    end if;
  end process;
  load <= load0;
end architecture;
