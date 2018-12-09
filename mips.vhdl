library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.debug_pkg.ALL;
use work.type_pkg.ALL;
use work.cache_pkg.ALL;

entity mips is
  generic(memfile : string);
  port (
    clk, rst : in std_logic;
    -- for scan
    -- -- datapath
    pc, pcnext : out std_logic_vector(31 downto 0);
    instr : out std_logic_vector(31 downto 0);
    addr, dcache_rd, dcache_wd : out std_logic_vector(31 downto 0);
    dcache_we : out std_logic;
    reg_wa : out reg_vector;
    reg_wd : out std_logic_vector(31 downto 0);
    reg_we : out std_logic;
    rds, rdt, immext : out std_logic_vector(31 downto 0);
    ja : out std_logic_vector(31 downto 0);
    aluout : out std_logic_vector(31 downto 0);
    -- for controller
    flopen_state : out flopen_state_vector;
    icache_load_en, dcache_load_en : out std_logic;
    suspend, stall, halt : out std_logic
  );
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

  component instr_controller
    port (
      clk, rst : in std_logic;
      instr : in std_logic_vector(31 downto 0);
      valid : out std_logic;
      halt : out std_logic
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
      suspend : out std_logic
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

  component decode_controller
    port (
      opcode : in opcode_vector;
      valid : in std_logic;
      decode_pc_br_ja_s : out std_logic_vector(1 downto 0);
      dcache_we, decode_rt_rd_s : out std_logic;
      calc_rdt_immext_s : out std_logic;
      reg_we1, reg_we2 : out std_logic
    );
  end component;

  component flopen_controller
    port (
      clk, rst, load : in std_logic;
      suspend, stall, halt : in std_logic;
      fetch_en, decode_en, calc_clr, dcache_en : out std_logic;
      state_vector : out flopen_state_vector
    );
  end component;

  component shift_controller
    port (
      clk, rst : in std_logic;
      decode_en, calc_clr, dcache_en : in std_logic;
      instr_valid0 : in std_logic;
      calc_rdt_immext_s0, dcache_we0, reg_we2_0, reg_we1_0 : in std_logic;
      alu_s0 : in alucont_type;
      instr_valid1 : out std_logic;
      calc_rdt_immext_s1, reg_we1 : out std_logic;
      dcache_we2, reg_we2 : out std_logic;
      alu_s1 : out alucont_type
    );
  end component;

  component datapath
    port (
      clk, rst : in std_logic;
      -- controller
      load : in std_logic;
      fetch_en, decode_en, calc_clr, dcache_en : in std_logic;
      -- -- instr_controller
      instr0 : out std_logic_vector(31 downto 0);
      reg_we1, reg_we2 : in std_logic;
      dcache_we : in std_logic;
      decode_rt_rd_s, calc_rdt_immext_s : in std_logic;
      decode_pc_br_ja_s : in std_logic_vector(1 downto 0);
      tag_s : in std_logic;
      opcode0 : out opcode_vector;
      funct0 : out funct_vector;
      alu_s : in alucont_type;
      -- forwarding, regw buffer
      forwarding_rds0_s, forwarding_rdt0_s : in std_logic;
      rs0, rt0 : out reg_vector;
      rt1, instr_rd1 : out reg_vector;
      opcode1 : out opcode_vector;
      -- from cache & memory
      instr_cache_miss_en, data_cache_miss_en, valid_flag : out std_logic;
      instr_load_en, dcache_load_en : in std_logic;
      mem2cache_d1, mem2cache_d2, mem2cache_d3, mem2cache_d4, mem2cache_d5, mem2cache_d6, mem2cache_d7, mem2cache_d8 : in std_logic_vector(31 downto 0);
      mem_tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      mem_index : out std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
      dcache2mem_d1, dcache2mem_d2, dcache2mem_d3, dcache2mem_d4, dcache2mem_d5, dcache2mem_d6, dcache2mem_d7, dcache2mem_d8 : out std_logic_vector(31 downto 0);
      -- scan
      pc, pcnext : out std_logic_vector(31 downto 0);
      addr, dcache_rd, dcache_wd : out std_logic_vector(31 downto 0);
      reg_wa : out reg_vector;
      reg_wd : out std_logic_vector(31 downto 0);
      reg_we : out std_logic;
      rds, rdt, immext : out std_logic_vector(31 downto 0);
      ja : out std_logic_vector(31 downto 0);
      aluout : out std_logic_vector(31 downto 0)
    );
  end component;

  component forwarding_controller is
    port (
      opcode1 : in opcode_vector;
      rs0, rt0 : in reg_vector;
      rt1, rd1 : in reg_vector;
      forwarding_rds0_s, forwarding_rdt0_s : out std_logic
    );
  end component;

  component stall_controller
    port (
      opcode0, opcode1 : in opcode_vector;
      valid0 : in std_logic;
      rs0, rt0, rt1 : in reg_vector;
      stall : out std_logic
    );
  end component;

  signal fetch_en0, decode_en0, dcache_en0 : std_logic;
  signal calc_clr0 : std_logic; -- for stall
  signal tag_s0 : std_logic;
  signal alu_s0, alu_s1 : alucont_type;
  signal reg_we1, reg_we1_0, reg_we2, reg_we2_0 : std_logic;
  signal load0 : std_logic;

  signal instr0 : std_logic_vector(31 downto 0);
  signal halt0 : std_logic;
  signal instr_valid0, instr_valid1 : std_logic;
  signal opcode0 : opcode_vector;
  signal funct0 : funct_vector;

  signal decode_pc_br_ja_s0 : std_logic_vector(1 downto 0);
  signal dcache_we0, dcache_we2, decode_rt_rd_s0 : std_logic;
  signal calc_rdt_immext_s0, calc_rdt_immext_s1 : std_logic;

  -- forwarding
  signal forwarding_rds0_s0, forwarding_rdt0_s0 : std_logic;
  signal rs0, rt0, rt1, instr_rd1 : reg_vector;
  signal opcode1 : opcode_vector;
  -- stall
  signal stall0 : std_logic;

  -- from cache & memory
  signal mem_we0 : std_logic;
  signal suspend0 : std_logic;
  signal instr_cache_miss_en0, data_cache_miss_en0, valid_flag0 : std_logic;
  signal icache_load_en0, dcache_load_en0 : std_logic;
  signal mem2cache_d1, mem2cache_d2, mem2cache_d3, mem2cache_d4, mem2cache_d5, mem2cache_d6, mem2cache_d7, mem2cache_d8 : std_logic_vector(31 downto 0);
  signal dcache2mem_d1, dcache2mem_d2, dcache2mem_d3, dcache2mem_d4, dcache2mem_d5, dcache2mem_d6, dcache2mem_d7, dcache2mem_d8 : std_logic_vector(31 downto 0);
  signal mem_tag0 : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal mem_index0 : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);

begin
  -- for scan
  instr <= instr0;
  icache_load_en <= icache_load_en0;
  dcache_load_en <= dcache_load_en0;
  suspend <= suspend0;
  halt <= halt0;

  -- controller
  load_controller0 : load_controller port map (
    clk => clk, rst => rst, load => load0
  );

  stall_controller0 : stall_controller port map (
    opcode0 => opcode0, opcode1 => opcode1,
    valid0 => instr_valid1,
    rs0 => rs0, rt0 => rt0, rt1 => rt1,
    stall => stall0
  );
  stall <= stall0;

  flopen_controller0 : flopen_controller port map (
    clk => clk, rst => rst, load => load0,
    suspend => suspend0, stall => stall0, halt => halt0,
    fetch_en => fetch_en0, decode_en => decode_en0,
    calc_clr => calc_clr0, dcache_en => dcache_en0,
    state_vector => flopen_state
  );

  mem_idcache_controller0 : mem_idcache_controller port map (
    clk => clk, rst => rst,
    instr_cache_miss_en => instr_cache_miss_en0, data_cache_miss_en => data_cache_miss_en0,
    valid_flag => valid_flag0,
    tag_s => tag_s0,
    instr_load_en => icache_load_en0, data_load_en => dcache_load_en0,
    mem_we => mem_we0,
    suspend => suspend0
  );

  decode_controller0 : decode_controller port map (
    opcode => opcode0,
    valid => instr_valid1,
    decode_pc_br_ja_s => decode_pc_br_ja_s0,
    dcache_we => dcache_we0,
    decode_rt_rd_s => decode_rt_rd_s0,
    calc_rdt_immext_s => calc_rdt_immext_s0,
    reg_we1 => reg_we1_0, reg_we2 => reg_we2_0
  );

  alucont0 : alu_controller port map (
    opcode => opcode0,
    funct => funct0,
    alu_s => alu_s0
  );

  shift_controller0 : shift_controller port map (
    clk => clk, rst => rst,
    decode_en => decode_en0,
    calc_clr => calc_clr0, dcache_en => dcache_en0,
    instr_valid0 => instr_valid0,
    calc_rdt_immext_s0 => calc_rdt_immext_s0, dcache_we0 => dcache_we0,
    reg_we2_0 => reg_we2_0, reg_we1_0 => reg_we1_0, alu_s0 => alu_s0,
    instr_valid1 => instr_valid1,
    calc_rdt_immext_s1 => calc_rdt_immext_s1, reg_we1 => reg_we1,
    dcache_we2 => dcache_we2, reg_we2 => reg_we2, alu_s1 => alu_s1
  );
  dcache_we <= dcache_we2;

  instr_controller0 : instr_controller port map (
    clk => clk, rst => rst,
    instr => instr0,
    valid => instr_valid0, halt => halt0
  );

  datapath0 : datapath port map (
    clk => clk, rst => rst, load => load0,
    -- flopren_controller
    fetch_en => fetch_en0, decode_en => decode_en0, calc_clr => calc_clr0, dcache_en => dcache_en0,
    -- instr_controller
    instr0 => instr0,
    -- regwe_controller
    reg_we1 => reg_we1, reg_we2 => reg_we2,
    -- decode_controller
    decode_pc_br_ja_s => decode_pc_br_ja_s0,
    dcache_we => dcache_we2, decode_rt_rd_s => decode_rt_rd_s0,
    calc_rdt_immext_s => calc_rdt_immext_s1,
    -- alu_controller
    opcode0 => opcode0, funct0 => funct0, alu_s => alu_s1,
    -- forwarding, regw buffer
    forwarding_rds0_s => forwarding_rds0_s0, forwarding_rdt0_s => forwarding_rdt0_s0,
    rs0 => rs0, rt0 => rt0, rt1 => rt1, instr_rd1 => instr_rd1,
    opcode1 => opcode1,
    -- form cache & memory
    tag_s => tag_s0,
    instr_cache_miss_en => instr_cache_miss_en0, data_cache_miss_en => data_cache_miss_en0, valid_flag => valid_flag0,
    instr_load_en => icache_load_en0, dcache_load_en => dcache_load_en0,
    mem2cache_d1 => mem2cache_d1, mem2cache_d2 => mem2cache_d2, mem2cache_d3 => mem2cache_d3, mem2cache_d4 => mem2cache_d4,
    mem2cache_d5 => mem2cache_d5, mem2cache_d6 => mem2cache_d6, mem2cache_d7 => mem2cache_d7, mem2cache_d8 => mem2cache_d8,
    mem_tag => mem_tag0, mem_index => mem_index0,
    dcache2mem_d1 => dcache2mem_d1, dcache2mem_d2 => dcache2mem_d2, dcache2mem_d3 => dcache2mem_d3, dcache2mem_d4 => dcache2mem_d4,
    dcache2mem_d5 => dcache2mem_d5, dcache2mem_d6 => dcache2mem_d6, dcache2mem_d7 => dcache2mem_d7, dcache2mem_d8 => dcache2mem_d8,
    -- for scan
    pc => pc, pcnext => pcnext,
    addr => addr, dcache_rd => dcache_rd, dcache_wd => dcache_wd,
    reg_wa => reg_wa, reg_wd => reg_wd, reg_we => reg_we,
    rds => rds, rdt => rdt, immext => immext,
    ja => ja, aluout => aluout
  );

  forwarding_controller0 : forwarding_controller port map (
    opcode1 => opcode1,
    rs0 => rs0, rt0 => rt0,
    rt1 => rt1, rd1 => instr_rd1,
    forwarding_rds0_s => forwarding_rds0_s0,
    forwarding_rdt0_s => forwarding_rdt0_s0
  );

  -- memory
  mem0 : mem generic map(filename=>memfile, BITS=>MEM_BITS_SIZE)
  port map (
    clk => clk, rst => rst, load => load0,
    we => mem_we0,
    tag => mem_tag0, index => mem_index0,
    -- data cache only
    wd1 => dcache2mem_d1, wd2 => dcache2mem_d2, wd3 => dcache2mem_d3, wd4 => dcache2mem_d4,
    wd5 => dcache2mem_d5, wd6 => dcache2mem_d6, wd7 => dcache2mem_d7, wd8 => dcache2mem_d8,

    rd1 => mem2cache_d1, rd2 => mem2cache_d2, rd3 => mem2cache_d3, rd4 => mem2cache_d4,
    rd5 => mem2cache_d5, rd6 => mem2cache_d6, rd7 => mem2cache_d7, rd8 => mem2cache_d8
  );
end architecture;
