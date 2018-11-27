library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity slt2 is
  generic (N: natural);
  port (
    a : in std_logic_vector(N-1 downto 0);
    y : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture behavior of slt2 is
begin
  y <= a(N-3 downto 0) & "00";
end architecture;
