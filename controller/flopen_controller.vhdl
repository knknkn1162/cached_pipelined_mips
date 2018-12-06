library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flopen_controller is
  port (
    clk, rst : in std_logic;
    fetch_en, decode_en, calc_en, dcache_en : out std_logic
  );
end entity;

architecture behavior of flopen_controller is
begin
  fetch_en <= '1';
  decode_en <= '1';
  calc_en <= '1';
  dcache_en <= '1';
end architecture;
