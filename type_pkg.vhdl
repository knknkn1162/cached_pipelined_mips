library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package type_pkg is
  subtype alucont_type is std_logic_vector(2 downto 0);
  subtype reg_vector is std_logic_vector(4 downto 0);
  subtype opcode_vector is std_logic_vector(5 downto 0);
  subtype imm_vector is std_logic_vector(15 downto 0);
  subtype shamt_vector is std_logic_vector(4 downto 0);
  subtype funct_vector is std_logic_vector(5 downto 0);
  subtype target_vector is std_logic_vector(25 downto 0);
  constant CONST_INSTR_TARGET_SIZE : natural := 26;
  subtype target2_vector is std_logic_vector(CONST_INSTR_TARGET_SIZE+1 downto 0);
end package;
