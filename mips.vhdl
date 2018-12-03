library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;
use work.type_pkg.ALL;

entity mips is
  generic(memfile : string);
  port (
    clk, rst, load : in std_logic;
    data_cache_a : in std_logic_vector(31 downto 0);
    we : in std_logic;
    wd : in std_logic_vector(31 downto 0);
    -- scan
    -- -- cache & memory
    pc, pcnext : out std_logic_vector(31 downto 0);
    instr : out std_logic_vector(31 downto 0);
    data_cache_miss_en, instr_cache_miss_en : out std_logic;
    rd : out std_logic_vector(31 downto 0);
    instr_load_en, data_load_en : out std_logic;
    suspend_flag : out std_logic
  );
end entity;

architecture behavior of mips is
  component flopr_en
    generic(N : natural);
    port (
      clk, rst, en: in std_logic;
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component instr_decoder
    port (
      instr : in std_logic_vector(31 downto 0);
      opcode : out opcode_vector;
      rs, rt, rd : out reg_vector;
      immext : out std_logic_vector(31 downto 0);
      brplus: out std_logic_vector(31 downto 0);
      shamt : out shamt_vector;
      funct : out funct_vector;
      target2 : out target2_vector
    );
  end component;

  component mux2
    generic(N : integer);
    port (
      d0 : in std_logic_vector(N-1 downto 0);
      d1 : in std_logic_vector(N-1 downto 0);
      s : in std_logic;
      y : out std_logic_vector(N-1 downto 0)
        );
  end component;

  component regfile
    port (
      clk, rst : in std_logic;
      -- 25:21(read)
      a1 : in reg_vector;
      rd1 : out std_logic_vector(31 downto 0);
      -- 20:16(read)
      a2 : in reg_vector;
      rd2 : out std_logic_vector(31 downto 0);
      wa : in reg_vector;
      wd : in std_logic_vector(31 downto 0);
      we : in std_logic
    );
  end component;

  component alu
    port (
      a, b : in std_logic_vector(31 downto 0);
      f : in alucont_type;
      y : out std_logic_vector(31 downto 0)
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

  component instr_cache
    port (
      clk, rst : in std_logic;
      -- program counter is 4-byte aligned
      a : in std_logic_vector(31 downto 0);
      rd : out std_logic_vector(31 downto 0);
      -- when cache miss
      -- -- pull load from the memory
      load_en : in std_logic;
      wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08 : in std_logic_vector(31 downto 0);
      -- push cache miss to the memory
      cache_miss_en : out std_logic
    );
  end component;

  component data_cache
    port (
      clk, rst : in std_logic;
      we : in std_logic;
      -- program counter is 4-byte aligned
      a : in std_logic_vector(31 downto 0);
      wd : in std_logic_vector(31 downto 0);
      tag_s : in std_logic;
      rd : out std_logic_vector(31 downto 0);
      wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08 : in std_logic_vector(31 downto 0);
      rd_tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      rd_index : out std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
      rd01, rd02, rd03, rd04, rd05, rd06, rd07, rd08 : out std_logic_vector(31 downto 0);
      -- push cache miss to the memory
      cache_miss_en : out std_logic;
      valid_flag : out std_logic;
      -- pull load from the memory
      load_en : in std_logic
    );
  end component;

  -- cache & memory
  signal dcache2mem_d1, dcache2mem_d2, dcache2mem_d3, dcache2mem_d4, dcache2mem_d5, dcache2mem_d6, dcache2mem_d7, dcache2mem_d8 : std_logic_vector(31 downto 0);
  signal mem2cache_d1, mem2cache_d2, mem2cache_d3, mem2cache_d4, mem2cache_d5, mem2cache_d6, mem2cache_d7, mem2cache_d8 : std_logic_vector(31 downto 0);
  signal tag0 : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal index0 : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
  signal tag_s0 : std_logic;
  signal data_cache_miss_en0, instr_cache_miss_en0: std_logic;
  signal mem_we0, valid_flag0 : std_logic;
  signal instr_load_en0, data_load_en0 : std_logic;

  -- enable
  signal fetch_en, decode_en, calc_en, dmemrw_en, regwb_en : std_logic;
  -- -- write enable
  signal reg_we0, mem_we0 : std_logic;

  -- fetchS
  signal pc0, pcnext0 : std_logic_vector(31 downto 0);
  signal instr0, instr1 : std_logic_vector(31 downto 0);
  -- decodeS
  -- -- decoder
  signal opcode0 : opcode_vector;
  signal rs0, rt0, rd0, rt_rd0 : reg_vector;
  signal brplus0 : std_logic_vector(31 downto 0);
  signal funct0 : funct_vector;
  signal target2_0 : target2_vector;

  signal rds0, rds1, rdt0, rdt1, immext0, immext1 : std_logic_vector(31 downto 0);
  signal rdt_immext0 : std_logic_vector(31 downto 0);
  signal shamt0, shamt1 : shamt_vector;

  -- CalCS
  signal aluout0, aluout1 : std_logic_vector(31 downto 0);
  signal alu_controller : alucont_type;

  -- RegWriteBackS
  signal wd0 : std_logic_vector(31 downto 0);


begin

  -- DecodeS (pc part)
  pcnext0 <= std_logic_vector(unsigned(pc0) + 4);
  pcnext <= pcnext0; -- for scan
  -- FetchS
  reg_pc : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => fetch_en,
    a => pcnext0,
    y => pc0
  );
  pc <= pc0; -- for scan

  instr_cache0 : instr_cache port map (
    clk => clk, rst => rst,
    a => pc0,
    rd => instr0,
    load_en => instr_load_en0,
    wd01 => mem2cache_d1, wd02 => mem2cache_d2, wd03 => mem2cache_d3, wd04 => mem2cache_d4,
    wd05 => mem2cache_d5, wd06 => mem2cache_d6, wd07 => mem2cache_d7, wd08 => mem2cache_d8,
    cache_miss_en => instr_cache_miss_en0
  );
  instr_cache_miss_en <= instr_cache_miss_en0;
  instr <= instr0;


  -- DecodeS (decoder & regfile part)
  reg_instr : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => decode_en,
    a => instr0,
    y => instr1
  );

  instr_decoder0 : instr_decoder port map (
    instr => instr1,
    opcode => opcode0,
    rs => rs0, rt => rt0, rd => rd0,
    immext => immext0,
    brplus => brplus0,
    shamt => shamt0,
    funct => funct0,
    target2 => target2
  );

  mux2_rt_rd : mux2 generic map (N=>CONST_REG_SIZE)
  port map (
    d0 => rt0,
    d1 => rd0,
    s => regwb_rt_rd_s,
    y => rt_rd0
  );
  
  -- -- RegWriteBackS
  reg_dmem_rd : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => regwb_en,
    a => rd0,
    y => rd1
  );
  wd0 <= rd1;

  regfile0 : regfile port map (
    clk => clk, rst => rst,
    a1 => rs0, rd1 => rds0,
    a2 => rt0, rd2 => rdt0,
    wa => rt_rd0, wd => wd0, we => reg_we0
  );

  -- CalcS
  reg_rds : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => calc_en,
    a => rds0,
    y => rds1
  );

  reg_rdt : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => calc_en,
    a => rdt0,
    y => rdt1
  );

  reg_immext : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => calc_en,
    a => immext0,
    y => immext1
  );

  mux2_rdt_immext : mux2 generic map (N=>32)
  port map (
    d0 => rdt1,
    d1 => immext1,
    s => calc_rdt_immext_s,
    y => rdt_immext0
  );

  alu0 : alu port map (
    a => rds1,
    b => rdt_immext0,
    f => alu_controller,
    y => aluout0
  );

  -- DMemRWS
  reg_rdt : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => dmemrw_en,
    a => rdt1,
    y => rdt2
  );

  reg_aluout : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => dmemrw_en,
    a => aluout0,
    y => aluout1
  );

  data_cache0 : data_cache port map (
    clk => clk, rst => rst,
    we => we,
    a => aluout1,
    wd => rdt2,
    tag_s => tag_s0,
    rd => rd0,
    load_en => data_load_en0,
    wd01 => mem2cache_d1, wd02 => mem2cache_d2, wd03 => mem2cache_d3, wd04 => mem2cache_d4,
    wd05 => mem2cache_d5, wd06 => mem2cache_d6, wd07 => mem2cache_d7, wd08 => mem2cache_d8,
    rd_tag => tag0, rd_index => index0,
    rd01 => dcache2mem_d1, rd02 => dcache2mem_d2, rd03 => dcache2mem_d3, rd04 => dcache2mem_d4,
    rd05 => dcache2mem_d5, rd06 => dcache2mem_d6, rd07 => dcache2mem_d7, rd08 => dcache2mem_d8,
    cache_miss_en => data_cache_miss_en0, valid_flag => valid_flag0
  );
  rd <= rd0;
  data_cache_miss_en <= data_cache_miss_en0;

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

  -- memory
  mem0 : mem generic map(filename=>memfile, BITS=>MEM_BITS_SIZE)
  port map (
    clk => clk, rst => rst, load => load,
    we => mem_we0,
    tag => tag0, index => index0,
    -- data cache only
    wd1 => dcache2mem_d1, wd2 => dcache2mem_d2, wd3 => dcache2mem_d3, wd4 => dcache2mem_d4,
    wd5 => dcache2mem_d5, wd6 => dcache2mem_d6, wd7 => dcache2mem_d7, wd8 => dcache2mem_d8,

    rd1 => mem2cache_d1, rd2 => mem2cache_d2, rd3 => mem2cache_d3, rd4 => mem2cache_d4,
    rd5 => mem2cache_d5, rd6 => mem2cache_d6, rd7 => mem2cache_d7, rd8 => mem2cache_d8
  );
end architecture;
