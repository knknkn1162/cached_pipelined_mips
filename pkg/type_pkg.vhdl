library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package type_pkg is
  constant CONST_REG_SIZE : natural := 5;
  constant CONST_INSTR_OPCODE_SIZE : natural := 6;
  constant CONST_INSTR_TARGET_SIZE : natural := 26;
  constant CONST_INSTR_IMM_SIZE : natural := 16;
  constant CONST_INSTR_SHAMT_SIZE : natural := 5;
  constant CONST_INSTR_FUNCT_SIZE : natural := 6;

  constant CONST_ALUCONT_SIZE : natural := 3;

  subtype alucont_type is std_logic_vector(CONST_ALUCONT_SIZE-1 downto 0);
  subtype reg_vector is std_logic_vector(CONST_REG_SIZE-1 downto 0);
  subtype opcode_vector is std_logic_vector(CONST_INSTR_OPCODE_SIZE-1 downto 0);
  subtype imm_vector is std_logic_vector(CONST_INSTR_IMM_SIZE-1 downto 0);
  subtype shamt_vector is std_logic_vector(CONST_INSTR_SHAMT_SIZE-1 downto 0);
  subtype funct_vector is std_logic_vector(CONST_INSTR_FUNCT_SIZE-1 downto 0);

  constant OP_LW : opcode_vector := "100011"; -- 0x23
  constant OP_SW : opcode_vector := "101011"; -- 0x2B
  constant OP_ADDI : opcode_vector := "001000"; -- 0x08
  constant OP_ADDIU : opcode_vector := "001001"; -- 0x09
  constant OP_ANDI : opcode_vector := "001100"; -- 0x0C
  constant OP_ORI : opcode_vector := "001101"; -- 0x0D
  constant OP_SLTI : opcode_vector := "001010"; -- 0x0A

  constant OP_RTYPE : opcode_vector := "000000";
  constant OP_BEQ : opcode_vector := "000100"; -- 0x04
  constant OP_BNE : opcode_vector := "000101"; -- 0x05
  constant OP_J : opcode_vector := "000010"; -- 0x02

  constant FUNCT_ADD : funct_vector := "100000"; -- 0x20
  constant FUNCT_ADDU : funct_vector := "100001"; -- 0x21
  constant FUNCT_AND : funct_vector := "100100"; -- 0x24
  constant FUNCT_DIV : funct_vector := "011010"; -- 0x1A
  constant FUNCT_DIVU : funct_vector := "011011"; -- 0x1B
  constant FUNCT_JR : funct_vector := "001000"; -- 0x08
  constant FUNCT_NOR : funct_vector := "100111"; -- 0x27
  constant FUNCT_XOR : funct_vector := "100110"; -- 0x26
  constant FUNCT_OR : funct_vector := "100101"; -- 0x25
  constant FUNCT_SLT : funct_vector := "101010"; -- 0x2A
  constant FUNCT_SLL : funct_vector := "000000"; -- 0x00
  constant FUNCT_SRL : funct_vector := "000010"; -- 0x02
  constant FUNCT_SUB : funct_vector := "100010"; -- 0x22
  constant FUNCT_SUBU : funct_vector := "100011"; -- 0x23

  constant MEM_BITS_SIZE : natural := 14;
end package;
