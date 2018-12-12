library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity pcnext_controller is
  port (
    opcode : in opcode_vector;
    cmp_eq : in std_logic;
    instr0_jtype_flag : in std_logic;
    branch_taken : out std_logic;
    decode_pc_br_ja_s : out std_logic_vector(1 downto 0)
  );
end entity;

architecture behavior of pcnext_controller is
  signal branch_taken0 : std_logic;
begin
  process(opcode, cmp_eq)
  begin
    if opcode = OP_BEQ then
      branch_taken0 <= cmp_eq;
    elsif opcode = OP_BNE then
      branch_taken0 <= (not cmp_eq);
    else
      branch_taken0 <= '0';
    end if;
  end process;
  branch_taken <= branch_taken0;

  process(opcode, branch_taken0, instr0_jtype_flag)
  begin
    if branch_taken0 = '1' then
      decode_pc_br_ja_s <= "01";
    elsif instr0_jtype_flag = '1' then
      decode_pc_br_ja_s <= "10";
    else
      decode_pc_br_ja_s <= "00";
    end if;
  end process;
end architecture;
