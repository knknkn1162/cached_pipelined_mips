library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity pcnext_controller is
  port (
    opcode : in opcode_vector;
    cmp_eq : in std_logic;
    decode_pc_br_ja_s : out std_logic_vector(1 downto 0)
  );
end entity;

architecture behavior of pcnext_controller is
  signal branch_taken : std_logic;
begin
  process(opcode, cmp_eq)
  begin
    if opcode = OP_BEQ then
      branch_taken <= cmp_eq;
    elsif opcode = OP_BNE then
      branch_taken <= (not cmp_eq);
    end if;
  end process;

  process(opcode)
  begin
    case opcode is
      when OP_BEQ | OP_BNE =>
        if branch_taken = '1' then
          decode_pc_br_ja_s <= "01";
        else
          decode_pc_br_ja_s <= "00";
        end if;
      when OP_J =>
        decode_pc_br_ja_s <= "10";
      when others =>
        decode_pc_br_ja_s <= "00";
    end case;
  end process;
end architecture;
