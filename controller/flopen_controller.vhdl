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
  process(state)
    variable fetch_en0, decode_en0, calc_en0, dcache_en0 : std_logic;
  begin
    fetch_en0 := '1';
    decode_en0 := '1';
    calc_en0 := '1';
    dcache_en0 := '1';
    case state is
      when SuspendS | ResetS | LoadS =>
        fetch_en0 := '0';
        decode_en0 := '0';
        calc_en0 := '0';
        dcache_en0 := '0';
      -- wait for MemRead in lw instruction
      when StallS =>
        fetch_en0 := '0';
        decode_en0 := '0';
        calc_en0 := '0';
      when others =>
        -- do nothing
    end case;
    fetch_en <= fetch_en0;
    decode_en <= decode_en0;
    calc_en <= calc_en0;
    dcache_en <= dcache_en0;
  end process;
end architecture;
