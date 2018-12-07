library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.state_pkg.ALL;

package debug_pkg is
  subtype flopen_state_vector is std_logic_vector(2 downto 0);
  function decode_state(pos : integer; size : natural) return std_logic_vector;
  function decode_flopen_state(state: flopen_statetype; size : natural) return std_logic_vector;
  function encode_flopen_state(vec : flopen_state_vector) return flopen_statetype;
end package;

package body debug_pkg is
  function decode_state(pos : integer; size : natural) return std_logic_vector is
    variable state_vec : flopen_state_vector;
  begin
    state_vec := std_logic_vector(to_unsigned(pos, size));
    return state_vec;
  end function;

  function decode_flopen_state(state : flopen_statetype; size : natural) return std_logic_vector is
    variable res : flopen_state_vector;
  begin
    res := decode_state(flopen_statetype'pos(state), size);
    return res;
  end function;

  function encode_flopen_state(vec : flopen_state_vector) return flopen_statetype is
    variable res : flopen_statetype;
  begin
    if is_X(vec) then
      res := ErrorS;
    else
      res := flopen_statetype'val(to_integer(unsigned(vec)));
    end if;
    return res;
  end function;
end package body;
