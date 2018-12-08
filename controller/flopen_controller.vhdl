library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.debug_pkg.ALL;
use work.state_pkg.ALL;

entity flopen_controller is
  port (
    clk, rst, load : in std_logic;
    suspend_flag : in std_logic;
    stall_flag : in std_logic;
    fetch_en, decode_en, calc_en, dcache_en : out std_logic;
    state_vector : out flopen_state_vector
  );
end entity;

architecture behavior of flopen_controller is
  signal state, nextstate : flopen_statetype;
begin
  state_vector <= decode_flopen_state(state, flopen_state_vector'length);
  process(clk, rst, nextstate)
  begin
    if rst = '1' then
      state <= ResetS;
    elsif rising_edge(clk) then
      state <= nextstate;
    end if;
  end process;

  -- nextstate
  process(state, load, suspend_flag, stall_flag)
  begin
    case state is
      when ResetS =>
        if load = '1' then
          nextstate <= LoadS;
        else
          nextstate <= ResetS;
        end if;
      when NormalS =>
        if suspend_flag = '1' then
          nextstate <= SuspendS;
        elsif stall_flag = '1' then
          nextstate <= StallS;
        else
          nextstate <= NormalS;
        end if;
      when SuspendS | LoadS =>
        if suspend_flag = '0' then
          nextstate <= NormalS;
        else
          nextstate  <= SuspendS;
        end if;
      when StallS =>
        nextstate <= NormalS;
      when others =>
        nextstate <= ErrorS;
    end case;
  end process;

  -- **_en
  process(state, suspend_flag)
    variable work_en : std_logic;
  begin
    if state = StallS then
      fetch_en <= '0';
      decode_en <= '0';
      calc_en <= '0';
    else
      case state is
        when ResetS | LoadS =>
          work_en := '0';
        when SuspendS =>
          work_en := (not suspend_flag);
        -- wait for MemRead in lw instruction
        when others =>
          work_en := '1';
      end case;
      fetch_en <= work_en;
      decode_en <= work_en;
      calc_en <= work_en;
      dcache_en <= work_en;
    end if;
  end process;
end architecture;
