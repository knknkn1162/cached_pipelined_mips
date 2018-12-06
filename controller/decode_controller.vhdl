library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity decode_controller is
  port (
    opcode : in opcode_vector;
    funct : in funct_vector;
    decode_pc_br_ja_s : out std_logic_vector(1 downto 0);
    dcache_we, decode_rt_rd_s : out std_logic
  );
end entity;

architecture behavior of decode_controller is
begin
  process(opcode)
  begin
    case opcode is
      when OP_BEQ | OP_BNE =>
        decode_pc_br_ja_s <= "01";
      when OP_J =>
        decode_pc_br_ja_s <= "10";
      when others =>
        decode_pc_br_ja_s <= "00";
    end case;
  end process;

  process(opcode)
  begin
    case opcode is
      when OP_SW =>
        dcache_we <= '1';
      when others =>
        dcache_we <= '0';
    end case;
  end process;

  process(opcode)
  begin
    case opcode is
      when OP_RTYPE =>
        decode_rt_rd_s <= '1';
      when others =>
        decode_rt_rd_s <= '0';
    end case;
  end process;
end architecture;
