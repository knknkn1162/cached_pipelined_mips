library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package type_pkg is
  constant CONST_REG_SIZE : natural := 5;
  constant CONST_INSTR_OPCODE_SIZE : natural := 6;
  constant CONST_INSTR_TARGET_SIZE : natural := 26;
  constant CONST_INSTR_IMM_SIZE : natural := 16;
  constant CONST_INSTR_SHAMT_SIZE : natural := 5;
  constant CONST_INSTR_FUNCT_SIZE : natural := 6;

  subtype alucont_type is std_logic_vector(2 downto 0);
  subtype reg_vector is std_logic_vector(CONST_REG_SIZE downto 0);
  subtype opcode_vector is std_logic_vector(CONST_INSTR_OPCODE_SIZE-1 downto 0);
  subtype imm_vector is std_logic_vector(CONST_INSTR_IMM_SIZE-1 downto 0);
  subtype shamt_vector is std_logic_vector(CONST_INSTR_SHAMT_SIZE-1 downto 0);
  subtype funct_vector is std_logic_vector(CONST_INSTR_FUNCT_SIZE-1 downto 0);
  subtype target_vector is std_logic_vector(CONST_INSTR_TARGET_SIZE-1 downto 0);
  subtype target2_vector is std_logic_vector(CONST_INSTR_TARGET_SIZE+1 downto 0);

  constant MEM_BITS_SIZE : natural := 14;
end package;
