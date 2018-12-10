library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

entity cache_controller is
  port (
    load : in std_logic;
    cache_valid : in std_logic;
    addr_tag, cache_tag : in std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
    addr_index : in std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
    addr_offset : in cache_offset_vector;
    cache_miss_en : out std_logic;
    cache_valid_flag : out std_logic;
    rd_s : out cache_offset_vector
  );
end entity;

architecture behavior of cache_controller is
begin
  -- cache_hit or cache_miss
  process(addr_index, addr_tag, cache_valid, cache_tag, load)
  begin
    if load = '1' then
      cache_miss_en <= '0';
    elsif cache_valid = '1' then
      -- cache hit!
      if cache_tag = addr_tag then
        cache_miss_en <= '0';
      else
        -- cache miss
        cache_miss_en <= '1';
      end if;
    else
      -- if ram is invalid, cache_miss also occurs
      if not is_X(addr_index) then
        cache_miss_en <= '1';
      end if;
    end if;
  end process;
  cache_valid_flag <= cache_valid;

  -- direct mux8 selector
  process(addr_tag, addr_offset, cache_valid, cache_tag)
  begin
    if cache_valid = '1' and cache_tag = addr_tag then
      rd_s <= addr_offset;
    else
      rd_s <= (others => 'X');
    end if;
  end process;
end architecture;

