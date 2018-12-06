library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flopen_controller is
  port (
    suspend_flag : in std_logic;
    fetch_en, decode_en, calc_en, dcache_en : out std_logic
  );
end entity;

architecture behavior of flopen_controller is
  signal work_en : std_logic;
begin
  work_en <= (not suspend_flag);
  fetch_en <= work_en;
  decode_en <= work_en;
  calc_en <= work_en;
  dcache_en <= work_en;
end architecture;
