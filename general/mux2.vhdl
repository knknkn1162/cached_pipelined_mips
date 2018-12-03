library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2 is
  generic(N : integer);
  port (
    d0 : in std_logic_vector(N-1 downto 0);
    d1 : in std_logic_vector(N-1 downto 0);
    s : in std_logic;
    y : out std_logic_vector(N-1 downto 0)
       );
end entity;


architecture behavior of mux2 is
begin
  -- The conditional signal assignment sets y to d1 if s is 1. Other- wise it sets y to d0.
  y <= d1 when s = '1' else d0;
end architecture;
