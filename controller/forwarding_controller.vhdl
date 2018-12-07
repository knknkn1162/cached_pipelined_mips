library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity forwarding_controller is
  port (
    opcode1 : in opcode_vector;
    rs0, rt0 : in reg_vector;
    rt1, rd1 : in reg_vector;
    forwarding_rds0_s, forwarding_rdt0_s : out std_logic
  );
end entity;

architecture behavior of forwarding_controller is
  signal r1 : reg_vector;
begin
  process(opcode1, rt1, rd1)
  begin
    case opcode1 is
      when OP_ADDI | OP_SLTI | OP_ORI | OP_ANDI =>
        r1 <= rt1;
      when OP_RTYPE =>
        r1 <= rd1;
      when others =>
        r1 <= (others => 'X');
    end case;
  end process;

  forwarding_rds0_s <= '1' when rs0 = r1 else '0';
  forwarding_rdt0_s <= '1' when rt0 = r1 else '0';
end architecture;
