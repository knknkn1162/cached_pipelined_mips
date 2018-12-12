library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity jtype_decoder is
  port (
    instr : in std_logic_vector(31 downto 0);
    pc_msb4 : in std_logic_vector(3 downto 0);
    instr_jtype_flag : out std_logic;
    ja : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behavior of jtype_decoder is
begin
  instr_jtype_flag <= '1' when instr(31 downto 26) = OP_J else '0';
  ja <= pc_msb4 & instr(25 downto 0) & "00";
end architecture;
