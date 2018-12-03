library IEEE;
use IEEE.STD_LOGIC_1164.ALL

entity flopr_en is
  generic(N : natural);
  port (
    clk, rst, en: in std_logic;
    a : in std_logic_vector(N-1 downto 0);
    y : out std_logic_vector(N-1 downto 0)
  );
end entity;


architecture behavior of flopr_en is
begin
  process(clk, rst) begin
    if rst='1' then
      y <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' then
        y <= a;
      end if;
    end if;
  end process;
end architecture;
