library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity instr_controller is
  port (
    clk, rst : in std_logic;
    instr : in std_logic_vector(31 downto 0);
    valid, halt : out std_logic
  );
end entity;

architecture behavior of instr_controller is
  type statetype is (
    LoadS, NormalS, HaltS
  );
  signal state, nextstate : statetype;
  signal valid0 : std_logic;
begin
  process(clk, rst)
  begin
    if rst = '1' then
      state <= LoadS;
    elsif rising_edge(clk) then
      state <= nextstate;
    end if;
  end process;

  -- FSM
  process(state)
  begin
    case state is
      when LoadS =>
        if valid0 = '1' then
          nextstate <= NormalS;
        end if;
      when NormalS =>
        if valid0 = '0' then
          nextstate <= HaltS;
        end if;
      when HaltS =>
        nextstate <= HaltS;
      when others =>
        -- do nothing
    end case;
  end process;

  valid0 <= '0' when instr = X"00000000" else '1';
  valid <= valid0;
  halt <= '1' when state = HaltS else '0';
end architecture;
