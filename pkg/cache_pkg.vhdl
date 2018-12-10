library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package cache_pkg is
  -- each memory is 4-bit aligned
  constant CONST_CACHE_OFFSET_SIZE : natural := 3;
  constant CONST_CACHE_INDEX_SIZE : natural := 7;
  constant CONST_CACHE_TAG_SIZE : natural := 20;
  constant CONST_ALIGNED_SIZE : natural := 32-(CONST_CACHE_OFFSET_SIZE+CONST_CACHE_INDEX_SIZE+CONST_CACHE_TAG_SIZE);
  subtype cache_offset_vector is std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);
  subtype cache_index_vector is std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
end package;
