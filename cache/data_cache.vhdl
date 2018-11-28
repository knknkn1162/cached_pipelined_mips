library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.tools_pkg.ALL;
use work.cache_pkg.ALL;

entity data_cache is
  generic(filename : string);
  port (
    clk, rst : in std_logic;
    we : in std_logic;
    -- program counter is 4-byte aligned
    a : in std_logic_vector(31 downto 0);
    wd : in std_logic_vector(31 downto 0);
    rd : out std_logic_vector(31 downto 0);
    im_d1, im_d2, im_d3, im_d4, im_d5, im_d6, im_d7, im_d8 : in std_logic_vector(31 downto 0);
    ex_d1, ex_d2, ex_d3, ex_d4, ex_d5, ex_d6, ex_d7, ex_d8 : out std_logic_vector(31 downto 0);
    ex_tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
    ex_index : out std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
    ex_ok: out std_logic
  );
end entity;

architecture behavior of data_cache is
  component cache_decoder
    port (
      addr : in std_logic_vector(31 downto 0);
      tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      index : out std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
      offset : out std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0)
    );
  end component;

  component mux8
    generic(N : integer);
    port (
      d000 : in std_logic_vector(N-1 downto 0);
      d001 : in std_logic_vector(N-1 downto 0);
      d010 : in std_logic_vector(N-1 downto 0);
      d011 : in std_logic_vector(N-1 downto 0);
      d100 : in std_logic_vector(N-1 downto 0);
      d101 : in std_logic_vector(N-1 downto 0);
      d110 : in std_logic_vector(N-1 downto 0);
      d111 : in std_logic_vector(N-1 downto 0);
      s : in std_logic_vector(2 downto 0);
      y : out std_logic_vector(N-1 downto 0)
        );
  end component;

  component flopr_en
    generic(N : natural);
    port (
      clk, rst, en: in std_logic;
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;

  -- state
  type statetype is (
    NormalS, DumpS, WaitS, LoadS
  );
  signal state, nextstate : statetype;

  -- The size of data cache assumes to be 1K-byte
  constant SIZE : natural := 256; -- 0x0100
  constant DATA_BLOCK_SIZE : natural := 2**CONST_CACHE_OFFSET_SIZE;
  type validtype is array(natural range<>) of std_logic;
  type ramtype is array(natural range<>) of std_logic_vector(31 downto 0);
  type addr30_type is array(natural range<>) of std_logic_vector(29 downto 0);
  type tagtype is array(natural range<>) of std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);

  signal valid_data : validtype(0 to SIZE-1);
  signal tag_data : tagtype(0 to SIZE-1);

  -- TODO: compatible with CONST_CACHE_OFFSET_SIZE
  signal ram1_data : ramtype(0 to SIZE-1);
  signal ram2_data : ramtype(0 to SIZE-1);
  signal ram3_data : ramtype(0 to SIZE-1);
  signal ram4_data : ramtype(0 to SIZE-1);
  signal ram5_data : ramtype(0 to SIZE-1);
  signal ram6_data : ramtype(0 to SIZE-1);
  signal ram7_data : ramtype(0 to SIZE-1);
  signal ram8_data : ramtype(0 to SIZE-1);

  -- decode addr
  signal addr_tag : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal addr_index : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
  signal addr_offset : std_logic_vector(CONST_CACHE_OFFSET_SIZE-1 downto 0);

  -- TODO: compatible with CONST_CACHE_OFFSET_SIZE
  signal ram1_datum : std_logic_vector(31 downto 0);
  signal ram2_datum : std_logic_vector(31 downto 0);
  signal ram3_datum : std_logic_vector(31 downto 0);
  signal ram4_datum : std_logic_vector(31 downto 0);
  signal ram5_datum : std_logic_vector(31 downto 0);
  signal ram6_datum : std_logic_vector(31 downto 0);
  signal ram7_datum : std_logic_vector(31 downto 0);
  signal ram8_datum : std_logic_vector(31 downto 0);
  signal tag_datum : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);

  -- is cache miss occurs or not
  signal cache_miss_en : std_logic;
  signal rd_s : std_logic_vector(2 downto 0); -- selector for mux8

begin
  process(clk, rst, nextstate)
  begin
    if rst = '1' then
      -- initialization
      state <= NormalS;
    elsif rising_edge(clk) then
      state <= nextstate;
    end if;
  end process;

  process(state)
  begin
    case state is
      when NormalS =>
        if cache_miss_en = '1' then
          nextstate <= DumpS;
        else
          nextstate <= NormalS;
        end if;
      when DumpS =>
        nextstate <= LoadS;
      when LoadS =>
        nextstate <= NormalS;
      when others =>
        nextstate <= NormalS;
    end case;
  end process;

  cache_decoder0 : cache_decoder port map(
    addr => a,
    tag => addr_tag,
    index => addr_index,
    offset => addr_offset
  );

  -- write data or load block from memory
  process(clk, rst, we, addr_index, im_d1, im_d2, im_d3, im_d4, im_d5, im_d6, im_d7, im_d8)
    variable idx : natural;
  begin
    -- initialization
    if rst = '1' then
      -- initialize with zeros
      valid_data <= (others => '0');
    elsif rising_edge(clk) then
      -- pull the notification from the memory
      if we = '1' then
        idx := to_integer(unsigned(addr_index));
        ram1_data(idx) <= im_d1;
        ram2_data(idx) <= im_d2;
        ram3_data(idx) <= im_d3;
        ram4_data(idx) <= im_d4;
        ram5_data(idx) <= im_d5;
        ram6_data(idx) <= im_d6;
        ram7_data(idx) <= im_d7;
        ram8_data(idx) <= im_d8;
      end if;
    end if;
  end process;

  process(addr_index, addr_offset, we)
    variable cache_miss_en0 : std_logic;
  begin
    cache_miss_en0 := '0';
    if we = '0' then
      if valid_data(to_integer(unsigned(addr_index))) = '1' then
        -- cache hit!
        if tag_data(to_integer(unsigned(addr_index))) = addr_tag then
          rd_s <= addr_offset;
        else
          -- cache miss
          cache_miss_en0 := '1';
        end if;
      end if;
    end if;
    cache_miss_en <= cache_miss_en0;
  end process;

  -- output rd signal
  ram1_datum <= ram1_data(to_integer(unsigned(addr_index)));
  ram2_datum <= ram2_data(to_integer(unsigned(addr_index)));
  ram3_datum <= ram3_data(to_integer(unsigned(addr_index)));
  ram4_datum <= ram4_data(to_integer(unsigned(addr_index)));
  ram5_datum <= ram5_data(to_integer(unsigned(addr_index)));
  ram6_datum <= ram6_data(to_integer(unsigned(addr_index)));
  ram7_datum <= ram7_data(to_integer(unsigned(addr_index)));
  ram8_datum <= ram8_data(to_integer(unsigned(addr_index)));

  mux8_0 : mux8 generic map(N=>32)
  port map (
    d000 => ram1_datum,
    d001 => ram2_datum,
    d010 => ram3_datum,
    d011 => ram4_datum,
    d100 => ram5_datum,
    d101 => ram6_datum,
    d110 => ram7_datum,
    d111 => ram8_datum,
    s => rd_s,
    y => rd
  );

  tag_datum <= tag_data(to_integer(unsigned(addr_index)));
  -- save
  reg_ex_tag : flopr_en generic map (N=>CONST_CACHE_INDEX_SIZE)
  port map (
    clk => clk, rst => rst, en => cache_miss_en,
    a => tag_datum,
    y => ex_tag
  );
  ex_index <= addr_index;

  reg_ex_d1 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en,
    a => ram1_datum,
    y => ex_d1
  );

  reg_ex_d2 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en,
    a => ram2_datum,
    y => ex_d2
  );

  reg_ex_d3 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en,
    a => ram3_datum,
    y => ex_d3
  );

  reg_ex_d4 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en,
    a => ram4_datum,
    y => ex_d4
  );

  reg_ex_d5 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en,
    a => ram5_datum,
    y => ex_d5
  );

  reg_ex_d6 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en,
    a => ram6_datum,
    y => ex_d6
  );

  reg_ex_d7 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en,
    a => ram7_datum,
    y => ex_d8
  );

  reg_ex_d8 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => cache_miss_en,
    a => ram8_datum,
    y => ex_d8
  );
end architecture;
