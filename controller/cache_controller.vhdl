library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

entity cache_controller is
  port (
    clk, rst : in std_logic;
    is_init : in std_logic;
    cache_valid : in std_logic;
    addr_tag, cache_tag : in std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
    addr_index : in std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
    addr_offset : in std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);
    cache_miss_en : out std_logic;
    cache_valid_flag : out std_logic;
    rd_s : out std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0)
  );
end entity;

architecture behavior of cache_controller is
  -- state
  type statetype is (
    CacheMissEnS, NormalS
  );

  signal state, nextstate : statetype;
  signal cache_miss_en0 : std_logic;
begin
  -- FSM for cache_miss_en signal
  process(clk, rst, state)
  begin
    if rst = '1' then
      state <= NormalS;
    elsif rising_edge(clk) then
      state <= nextstate;
    end if;
  end process;

  process(state, cache_miss_en0)
  begin
    case state is
      when NormalS =>
        if cache_miss_en0 = '1' then
          nextstate <= CacheMissEnS;
        else
          nextstate <= NormalS;
        end if;
      when CacheMissEnS =>
        nextstate <= NormalS;
    end case;
  end process;

  -- cache_hit or cache_miss
  process(state, addr_index, addr_tag, cache_valid, cache_tag)
  begin
    if is_init = '1' then
      cache_miss_en0 <= '0';
    else
      case state is
        when NormalS =>
          if cache_valid = '1' then
            -- cache hit!
            if cache_tag = addr_tag then
              cache_miss_en0 <= '0';
            else
              -- cache miss
              cache_miss_en0 <= '1';
            end if;
          else
            -- if ram is invalid, cache_miss also occurs
            if not is_X(addr_index) then
              cache_miss_en0 <= '1';
            end if;
          end if;
        when CacheMissEnS =>
          cache_miss_en0 <= '0';
        when others =>
          -- do nothing
      end case;
    end if;
  end process;
  cache_miss_en <= cache_miss_en0;
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

