library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_cache_controller is
  port (
    clk, rst : in std_logic;
    cache_miss_en : in std_logic;
    valid_flag : in std_logic;
    dirty_flag : in std_logic;
    mem2cache : out std_logic;
    tag_s : out std_logic;
    load_en : out std_logic;
    mem_we : out std_logic;
    suspend : out std_logic
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

  process(state, cache_miss_en)
  begin
    if state = NormalS then
      if cache_miss_en = '1' then
        suspend <= '1';
      else
        suspend <= '0';
      end if;
    end if;
  end process;

  process(state,  cache_miss_en, valid_flag, dirty_flag)
  begin
    case state is
      when NormalS =>
        if cache_miss_en = '1' then
          if valid_flag = '1' and dirty_flag = '1' then
            nextstate <= Cache2MemS;
          else
            nextstate <= Mem2CacheS;
          end if;
        else
          nextstate <= NormalS;
        end if;
      when Cache2MemS =>
        nextstate <= Mem2CacheS;
      when Mem2CacheS =>
        nextstate <= CacheWriteBackS;
      when CacheWriteBackS =>
        nextstate <= NormalS;
    end case;
  end process;

  process(state)
  begin
    case state is
      -- tranform cache to memory with old tag
      when Cache2MemS =>
        tag_s <= '0';
      -- transform mem to cache with new tag
      when Mem2CacheS =>
        tag_s <= '1';
      when others =>
        tag_s <= '1';
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

  process(state)
  begin
    if state = Mem2CacheS then
      mem2cache <= '1';
    else
      mem2cache <= '0';
    end if;
  end process;

end architecture;
