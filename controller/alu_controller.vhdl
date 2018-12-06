library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity alu_controller is
  port (
    opcode : in opcode_vector;
    funct : in funct_vector;
    alu_s : out alucont_type
  );
end entity;

architecture behavior of alu_controller is
begin
  process(opcode, funct)
  begin
    case opcode is
      when OP_RTYPE =>
        case funct is
          when FUNCT_AND => alu_s <= "000";
          when FUNCT_SUB => alu_s <= "110";
          when FUNCT_SLT => alu_s <= "111";
          when FUNCT_OR => alu_s <= "001";
          -- FUNCT_ADD 
          when others => alu_s <= "010";
        end case;
      when OP_ANDI => alu_s <= "000";
      when OP_SLTI => alu_s <= "111";
      when OP_ORI => alu_s <= "001";
      -- OP_ADDI | OP_SW | OP_LW
      when others => alu_s <= "010";
    end case;
  end process;

end architecture;
