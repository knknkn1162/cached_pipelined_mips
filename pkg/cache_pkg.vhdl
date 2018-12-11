library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package cache_pkg is
  -- each memory is 4-bit aligned
  constant CONST_CACHE_OFFSET_SIZE : natural := 3;
  constant CONST_CACHE_INDEX_SIZE : natural := 7;
  constant CONST_CACHE_TAG_SIZE : natural := 20;
  constant CONST_ALIGNED_SIZE : natural := 2; -- every instruction size is 32bit=4byte.
  subtype cache_offset_vector is std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);
  subtype cache_index_vector is std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
  subtype cache_tag_vector is std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);

  type valid_array_type is array(natural range<>) of std_logic;
  type dirty_array_type is array(natural range<>) of std_logic;
  type ram_type is array(natural range<>) of std_logic_vector(31 downto 0);
  type tag_array_type is array(natural range<>) of cache_tag_vector;
end package;
