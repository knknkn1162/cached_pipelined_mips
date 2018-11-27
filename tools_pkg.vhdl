library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package tools_pkg is
  function char2bits(ch : character) return std_logic_vector;
end package;

package body tools_pkg is
  function char2bits(ch : character) return std_logic_vector is
    variable ret : natural range 0 to 15;
  begin
    if '0' <= ch and ch <= '9' then
      -- * - 0x30
      ret := character'pos(ch) - character'pos('0');
    elsif 'a' <= ch and ch <= 'f' then
      ret := character'pos(ch) - character'pos('a') + 10;
    elsif 'A' <= ch and ch <= 'F' then
      ret := character'pos(ch) - character'pos('A') + 10;
    else
      ret := 0;
    end if;
    return std_logic_vector(to_unsigned(ret, 4));
  end function;
end package body;
