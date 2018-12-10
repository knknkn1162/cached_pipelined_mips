library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

entity cache_decoder is
  port (
    addr : in std_logic_vector(31 downto 0);
    tag : out cache_tag_vector;
    index : out cache_index_vector;
    offset : out cache_offset_vector
  );
end entity;

architecture behavior of cache_decoder is
begin
  tag <= addr(31 downto 32-CONST_CACHE_TAG_SIZE);
  index <= addr(31-CONST_CACHE_TAG_SIZE downto 32-(CONST_CACHE_TAG_SIZE+CONST_CACHE_INDEX_SIZE));
  offset <= addr(31-(CONST_CACHE_TAG_SIZE+CONST_CACHE_INDEX_SIZE) downto CONST_ALIGNED_SIZE);
end architecture;
