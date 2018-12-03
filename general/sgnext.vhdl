library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sgnext is
  port (
    a : in std_logic_vector(15 downto 0);
    y : out std_logic_vector(31 downto 0)
       );
end entity;

architecture behavior of sgnext is
begin
  y <= (X"FFFF" & a) when a(15) = '1' else (X"0000" & a);
end architecture;
