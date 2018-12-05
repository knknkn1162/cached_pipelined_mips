library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mips is
end entity;

-- memory, controller and datapath
architecture behavior of mips is
  component mem
    generic(filename : string; BITS : natural);
    port (
      clk, rst, load : in std_logic;
      -- we='1' when transport cache2mem
      we : in std_logic;
      tag : in std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      index : in std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
      wd1, wd2, wd3, wd4, wd5, wd6, wd7, wd8 : in std_logic_vector(31 downto 0);
      rd1, rd2, rd3, rd4, rd5, rd6, rd7, rd8 : out std_logic_vector(31 downto 0)
    );
  end component;

  component mem_idcache_controller
    port (
      clk, rst : in std_logic;
      instr_cache_miss_en, data_cache_miss_en : in std_logic;
      valid_flag : in std_logic;
      tag_s : out std_logic;
      instr_load_en, data_load_en : out std_logic;
      mem_we : out std_logic;
      suspend_flag : out std_logic
    );
  end component;

  component alu_controller
    port (
      opcode : in opcode_vector;
      funct : in funct_vector;
      alu_s : out alucont_type
    );
  end component;

  component load_controller
    port (
      clk, rst : in std_logic;
      load : out std_logic
    );
  end component;

  component datapath
    port (
      clk, rst : in std_logic;
      -- controller
      load : in std_logic;
      fetch_en, decode_en, calc_en, dcache_en : in std_logic;
      reg_we1, reg_we2 : in std_logic;
      dcache_we : in std_logic;
      decode_instr_rtrd_s, calc_rdt_immext_s, memrw_instr_rtrd_aluout_s : in std_logic;
      decode_pc_br_ja_s : in std_logic_vector(1 downto 0);
      tag_s : in std_logic;
      opcode1 : out opcode_vector;
      funct1 : out funct_vector;
      alu_s : in alucont_type;
      -- from cache & memory
      instr_cache_miss_en, data_cache_miss_en, valid_flag : out std_logic;
      instr_load_en, dcache_load_en : in std_logic;
      mem2cache_d1, mem2cache_d2, mem2cache_d3, mem2cache_d4, mem2cache_d5, mem2cache_d6, mem2cache_d7, mem2cache_d8 : in std_logic_vector(31 downto 0);
      mem_tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      mem_index : out std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
      dcache2mem_d1, dcache2mem_d2, dcache2mem_d3, dcache2mem_d4, dcache2mem_d5, dcache2mem_d6, dcache2mem_d7, dcache2mem_d8 : out std_logic_vector(31 downto 0);
      -- scan
      -- -- cache & memory
      pc, pcnext : out std_logic_vector(31 downto 0);
      instr : out std_logic_vector(31 downto 0)
    );
  end component;

  signal alu_s0 : std_logic;
  signal load0 : std_logic;

begin
  load_controller0 : port map (
    clk => clk, rst => rst, load => load0
  );
  -- memory
  mem0 : mem generic map(filename=>memfile, BITS=>MEM_BITS_SIZE)
  port map (
    clk => clk, rst => rst, load => load0,
    we => mem_we,
    tag => tag0, index => index0,
    -- data cache only
    wd1 => dcache2mem_d1, wd2 => dcache2mem_d2, wd3 => dcache2mem_d3, wd4 => dcache2mem_d4,
    wd5 => dcache2mem_d5, wd6 => dcache2mem_d6, wd7 => dcache2mem_d7, wd8 => dcache2mem_d8,

    rd1 => mem2cache_d1, rd2 => mem2cache_d2, rd3 => mem2cache_d3, rd4 => mem2cache_d4,
    rd5 => mem2cache_d5, rd6 => mem2cache_d6, rd7 => mem2cache_d7, rd8 => mem2cache_d8
  );
  -- controller
  mem_idcache_controller0 : mem_idcache_controller port map (
    clk => clk, rst => rst,
    instr_cache_miss_en => instr_cache_miss_en0, data_cache_miss_en => data_cache_miss_en0,
    valid_flag => valid_flag0,
    tag_s => tag_s0,
    instr_load_en => instr_load_en0, data_load_en => data_load_en0,
    mem_we => mem_we0,
    suspend_flag => suspend_flag
  );
  instr_load_en <= instr_load_en0;
  data_load_en <= data_load_en0;

  alucont0 : alu_controller port map (
    opcode => opcode1,
    funct => funct1,
    alu_s => alu_s0
  );
  alu_s <= alu_s0;
end architecture;
