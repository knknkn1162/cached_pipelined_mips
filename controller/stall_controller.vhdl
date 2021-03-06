library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity stall_controller is
  port (
    opcode0, opcode1 : in opcode_vector;
    valid0 : in std_logic;
    rs0, rt0, rt1 : in reg_vector;
    stall : out std_logic
  );
end entity;

architecture behavior of stall_controller is
begin
  process(opcode1, rt1, rs0, rt0, opcode0, valid0)
  begin
    if valid0 /= '1' then
      stall <= '0';
    elsif opcode1 = OP_LW then
      if rt1 = rs0 then
        stall <= '1';
      else
        case opcode0 is
          when OP_RTYPE | OP_BEQ | OP_BNE =>
            if rt1 = rt0 then
              stall <= '1';
            else
              stall <= '0';
            end if;
          when others => stall <= '0';
        end case;
      end if;
    else
      stall <= '0';
    end if;
  end process;

end architecture;
