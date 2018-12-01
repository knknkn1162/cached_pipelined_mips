library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

entity mem_cache_controller is
  port (
    clk, rst : in std_logic;
    cache_miss_en : in std_logic;
    rd_en : in std_logic;
    tag_s : out std_logic;
    load_en : out std_logic;
    mem_we : out std_logic
  );
end entity;

architecture behavior of mem_cache_controller is
  type statetype is (
    NormalS, Cache2MemS, Mem2CacheS, CacheWriteBackS
  );
  signal state, nextstate : statetype;

begin
  -- control enable signal
  process(clk, rst, nextstate)
  begin
    if rst = '1' then
      state <= NormalS;
    elsif rising_edge(clk) then
      state <= nextstate;
    end if;
  end process;

  process(state, rd_en, cache_miss_en)
  begin
    case state is
      when NormalS =>
        if cache_miss_en = '1' then
          nextstate <= Cache2MemS;
        else
          nextstate <= NormalS;
        end if;
      when Cache2MemS =>
        nextstate <= Mem2CacheS;
      when Mem2CacheS =>
        if rd_en = '1' then
          nextstate <= CacheWriteBackS;
        else
          nextstate <= Mem2CacheS;
        end if;
      when CacheWriteBackS =>
        nextstate <= NormalS;
    end case;
  end process;

  process(state)
  begin
    case state is
      -- tranform cache to memory with old tag
      when Mem2CacheS =>
        tag_s <= '0';
      -- transform mem to cache with new tag
      when Cache2MemS =>
        tag_s <= '1';
      when others =>
        -- do nothing
    end case;
  end process;

  process(state)
  begin
    if state = Cache2MemS then
      mem_we <= '1';
    else
      mem_we <= '0';
    end if;
  end process;

  process(state)
  begin
    if state = CacheWriteBackS then
      load_en <= '1';
    else
      load_en <= '0';
    end if;
  end process;
end architecture;
