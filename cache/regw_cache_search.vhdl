library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity regw_cache_search is
  port (
    wa0, wa1, wa2 : in reg_vector;
    wd0, wd1, wd2 : in std_logic_vector(31 downto 0);
    we0, we1, we2 : in std_logic;
    ra : in reg_vector;
    rd : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behavior of regw_cache_search is
begin
  process(wa0, wa1, wa2, wd0, wd1, wd2, we0, we1, we2)
  begin
    if ra = wa0 and we0 = '1' then
      rd <= wd0;
    elsif ra = wa1 and we1 = '1' then
      rd <= wd1;
    elsif ra = wa2 and we2 = '1' then
      rd <= wd2;
    else
      rd <= (others => 'X');
    end if;
  end process;
end architecture;
