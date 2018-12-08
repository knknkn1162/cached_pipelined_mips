library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flopr_clr is
  generic(N : natural);
  port (
    clk, rst, clr: in std_logic;
    a : in std_logic_vector(N-1 downto 0);
    y : out std_logic_vector(N-1 downto 0)
  );
end entity;


architecture behavior of flopr_clr is
begin
  process(clk, rst) begin
    if rst='1' then
      y <= (others => '0');
    elsif rising_edge(clk) then
      if clr = '1' then
        y <= (others => '0');
      else
        y <= a;
      end if;
    end if;
  end process;
end architecture;
