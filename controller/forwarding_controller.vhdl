library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity forwarding_controller is
  port (
    opcode1 : in opcode_vector;
    rs0, rs1 : in reg_vector;
    rt0, rt1 : in reg_vector;
    forwarding_rds0_s, forwarding_rdt0_s : out std_logic
  );
end entity;

architecture behavior of forwarding_controller is
begin
  process(opcode1, rs0, rs0, rt0, rt1)
    variable forwarding_rds0_s0, forwarding_rdt0_s0 : std_logic;
  begin
    forwarding_rds0_s0 := '0'; forwarding_rdt0_s0 := '0';
    case opcode1 is
      when OP_ADDI | OP_SLTI | OP_ORI | OP_ANDI | OP_RTYPE =>
        if rs0 = rs1 then
          forwarding_rds0_s <= '1';
        end if;
        if rt0 = rt1 then
          forwarding_rdt0_s <= '1';
        end if;
      when others =>
        -- do nothing
    end case;
    forwarding_rds0_s <= forwarding_rds0_s0;
    forwarding_rdt0_s <= forwarding_rdt0_s0;
  end process;
end architecture;
