library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity regwe_controller is
  port (
    opcode : in opcode_vector;
    funct : in funct_vector;
    reg_we1, reg_we2 : out std_logic
  );
end entity;

architecture behavior of regwe_controller is
begin
  process(opcode, funct)
  begin
    case opcode is
      when OP_RTYPE | OP_ADDI | OP_SLTI | OP_ORI | OP_ANDI =>
        reg_we1 <= '1'; reg_we2 <= '0';
      when OP_LW =>
        reg_we1 <= '0'; reg_we2 <= '1';
      -- OP_SW
      when others => reg_we1 <= '0'; reg_we2 <= '0';
    end case;
  end process;
end architecture;
