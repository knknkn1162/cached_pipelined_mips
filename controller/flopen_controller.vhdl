library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.debug_pkg.ALL;
use work.state_pkg.ALL;

entity flopen_controller is
  port (
    clk, rst, load : in std_logic;
    suspend, stall, halt : in std_logic;
    branch_taken : in std_logic;
    fetch_en, decode_en, decode_clr, calc_clr, dcache_en : out std_logic;
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
  process(state, load, suspend, stall)
  begin
    case state is
      when ResetS =>
        if load = '1' then
          nextstate <= LoadS;
        else
          nextstate <= ResetS;
        end if;
      when NormalS =>
        if suspend = '1' then
          nextstate <= SuspendS;
        elsif stall = '1' then
          nextstate <= StallS;
        else
          nextstate <= NormalS;
        end if;
      when SuspendS | LoadS =>
        if suspend = '0' then
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
  process(stall, state, suspend, halt, branch_taken)
    variable work_en : std_logic;
  begin
    if state = NormalS then
      fetch_en <= (not stall) and (not halt);
      decode_en <= (not stall);
      decode_clr <= branch_taken;
      dcache_en <= '1';
      calc_clr <= stall;
    else
      case state is
        when ResetS | LoadS =>
          work_en := '0';
        when SuspendS =>
          work_en := (not suspend);
        -- wait for MemRead in lw instruction
        when others =>
          work_en := '1';
      end case;
      fetch_en <= work_en;
      decode_en <= work_en;
      calc_clr <= (not work_en);
      decode_clr <= '0';
      dcache_en <= work_en;
    end if;
  end process;
end architecture;
