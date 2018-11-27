library IEEE;;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

entity cache_decoder is
  port map (
    addr : in std_logic_vector(31 downto 0);
    tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
    index : out std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
    offset : out std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);
  );
end entity;

architecture behavior of cache_decoder is
begin
  tag <= addr(31 downto 32-CONST_CACHE_TAG_SIZE);
  index <= addr(31-CONST_CACHE_TAG_SIZE downto 32-(CONST_CACHE_TAG_SIZE+CONST_CACHE_INDEX_SIZE));
  offset <= addr(31-(CONST_CACHE_TAG_SIZE+CONST_CACHE_OFFSET_SIZE) downto CONST_ALIGNED_SIZE);
end architecture;
