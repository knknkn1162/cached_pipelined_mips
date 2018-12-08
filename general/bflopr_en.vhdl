library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bflopr_en is
  port (
    clk, rst, en: in std_logic;
    a : in std_logic;
    y : out std_logic
  );
end entity;


architecture behavior of bflopr_en is
begin
  process(clk, rst) begin
    if rst='1' then
      y <= '0';
    elsif rising_edge(clk) then
      if en = '1' then
        y <= a;
      end if;
    end if;
  end process;
end architecture;
