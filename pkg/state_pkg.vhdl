library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package state_pkg is
  type flopen_statetype is (
    ResetS, LoadS, SuspendS, NormalS, StallS, ErrorS
  );
end package;
