library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package type_pkg is
  subtype alucont_type is std_logic_vector(2 downto 0);
  subtype reg_vector is std_logic_vector(4 downto 0);
end package;
