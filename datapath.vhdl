library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cache_pkg.ALL;
use work.type_pkg.ALL;

entity datapath is
  generic(memfile: string);
  port (
    clk, rst, load : in std_logic;
    -- flopren_controller
    fetch_en, decode_en, decode_clr : in std_logic;
    calc_en, calc_clr, dcache_en : in std_logic;
    -- -- instr_controller
    instr0 : out std_logic_vector(31 downto 0);
    -- pcnext_controller
    decode_pc_br_ja_s : in std_logic_vector(1 downto 0);
    cmp_eq : out std_logic;
    instr0_jtype_flag : out std_logic;
    -- decode_controller
    dcache_we : in std_logic;
    decode_rt_rd_s : in std_logic;
    calc_rdt_immext_s : in std_logic;
    -- stall_controller
    rs0, rt0, rt1 : out reg_vector;
    opcode0 : out opcode_vector;
    opcode1 : out opcode_vector;
    -- alu_controller
    funct0 : out funct_vector;
    alu_s : in alucont_type;
    -- regwe_controller
    reg_we1, reg_we2 : in std_logic;
    -- from cache & memory
    tag_s : in std_logic;
    instr_cache_miss_en, data_cache_miss_en : out std_logic;
    valid_flag, dirty_flag : out std_logic;
    instr_load_en, dcache_load_en : in std_logic;
    idcache_addr_s : in std_logic;
    mem_we : in std_logic;
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
end entity;

architecture behavior of datapath is
  component flopr_en
    generic(N : natural);
    port (
      clk, rst, en: in std_logic;
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component flopr_clr
    generic(N : natural);
    port (
      clk, rst, clr: in std_logic;
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component flopr_en_clr
    generic(N : natural);
    port (
      clk, rst, en, clr : in std_logic;
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
      funct : out funct_vector
    );
  end component;

  component jtype_decoder
    port (
      instr : in std_logic_vector(31 downto 0);
      pc_msb4 : in std_logic_vector(3 downto 0);
      instr_jtype_flag : out std_logic;
      ja : out std_logic_vector(31 downto 0)
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

  component mux4
    generic (N : natural);
    port (
      d00 : in std_logic_vector(N-1 downto 0);
      d01 : in std_logic_vector(N-1 downto 0);
      d10 : in std_logic_vector(N-1 downto 0);
      d11 : in std_logic_vector(N-1 downto 0);
      s : in std_logic_vector(1 downto 0);
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

  component instr_cache
    port (
      clk, rst, load : in std_logic;
      -- program counter is 4-byte aligned
      a : in std_logic_vector(31 downto 0);
      rd : out std_logic_vector(31 downto 0);
      -- when cache miss
      -- -- pull load from the memory
      load_en : in std_logic;
      wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08 : in std_logic_vector(31 downto 0);
      -- push cache miss to the memory
      cache_miss_en : out std_logic;
      tag : out cache_tag_vector;
      index : out cache_index_vector
    );
  end component;

  component data_cache
    port (
      clk, rst, load : in std_logic;
      we : in std_logic;
      -- program counter is 4-byte aligned
      a : in std_logic_vector(31 downto 0);
      wd : in std_logic_vector(31 downto 0);
      tag_s : in std_logic;
      rd : out std_logic_vector(31 downto 0);
      wd01, wd02, wd03, wd04, wd05, wd06, wd07, wd08 : in std_logic_vector(31 downto 0);
      rd_tag : out cache_tag_vector;
      rd_index : out cache_index_vector;
      rd01, rd02, rd03, rd04, rd05, rd06, rd07, rd08 : out std_logic_vector(31 downto 0);
      -- push cache miss to the memory
      cache_miss_en : out std_logic;
      valid_flag, dirty_flag : out std_logic;
      -- pull load from the memory
      load_en : in std_logic
    );
  end component;

  component mem
    generic(filename : string; BITS : natural);
    port (
      clk, rst, load : in std_logic;
      -- we='1' when transport cache2mem
      we : in std_logic;
      tag : in cache_tag_vector;
      index : in cache_index_vector;
      wd1, wd2, wd3, wd4, wd5, wd6, wd7, wd8 : in std_logic_vector(31 downto 0);
      rd1, rd2, rd3, rd4, rd5, rd6, rd7, rd8 : out std_logic_vector(31 downto 0)
    );
  end component;

  component regw_buffer
    port (
      clk, rst : in std_logic;
      wa0 : in reg_vector;
      wd0 : in std_logic_vector(31 downto 0);
      we0 : in std_logic;
      wa1 : in reg_vector;
      wd1 : in std_logic_vector(31 downto 0);
      we1 : in std_logic;
      -- for register WB
      wa2 : out reg_vector;
      wd2 : out std_logic_vector(31 downto 0);
      we2 : out std_logic;

      -- search for forwarding
      ra1 : in reg_vector;
      ra2 : in reg_vector;
      rd1 : out std_logic_vector(31 downto 0);
      rd2 : out std_logic_vector(31 downto 0)
    );
  end component;

  signal pc0, pc1, pcnext0, pc_br4_0 : std_logic_vector(31 downto 0);
  signal instr0_0, instr1 : std_logic_vector(31 downto 0);
  signal rs0_0, rt0_0, instr_rd0_0, reg_wa0, instr_rtrd0, instr_rtrd1, instr_rtrd2 : reg_vector;
  signal opcode0_0 : opcode_vector;
  signal rds0, rds1, rdt0, rdt1, rdt2, reg_wd0 : std_logic_vector(31 downto 0);
  signal immext0, immext1, brplus0 : std_logic_vector(31 downto 0);
  signal shamt0 : shamt_vector;
  signal br4, pc4, ja0: std_logic_vector(31 downto 0);
  -- calc
  signal rdt_immext0, aluout0, aluout1 : std_logic_vector(31 downto 0);
  -- DMemRWS
  signal dcache_a0, dcache_rd0, dcache_wd0 : std_logic_vector(31 downto 0);
  -- RegWriteBackS
  signal reg_we0 : std_logic;
  signal buf_rds0, buf_rdt0 : std_logic_vector(31 downto 0);
  -- forwarding
  signal forwarding_rds0, forwarding_rdt0 : std_logic_vector(31 downto 0);

  -- memory
    signal mem2cache_d1, mem2cache_d2, mem2cache_d3, mem2cache_d4, mem2cache_d5, mem2cache_d6, mem2cache_d7, mem2cache_d8 : std_logic_vector(31 downto 0);
    signal icache_tag0, dcache_tag0, mem_tag0 : cache_tag_vector;
    signal icache_index0, dcache_index0, mem_index0 : cache_index_vector;
    signal dcache2mem_d1, dcache2mem_d2, dcache2mem_d3, dcache2mem_d4, dcache2mem_d5, dcache2mem_d6, dcache2mem_d7, dcache2mem_d8 : std_logic_vector(31 downto 0);

begin
  -- for scan
  pc <= pc0;
  pcnext <= pcnext0;
  addr <= dcache_a0; dcache_rd <= dcache_rd0; dcache_wd <= dcache_wd0;
  reg_wa <= reg_wa0; reg_wd <= reg_wd0; reg_we <= reg_we0;
  rds <= forwarding_rds0; rdt <= forwarding_rdt0;
  immext <= immext0;
  ja <= ja0;
  aluout <= aluout0;

  -- Fetch Stage
  reg_pc : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => fetch_en,
    a => pcnext0,
    y => pc0
  );

  instr_cache0 : instr_cache port map (
    clk => clk, rst => rst, load => load,
    a => pc0,
    rd => instr0_0,
    load_en => instr_load_en,
    wd01 => mem2cache_d1, wd02 => mem2cache_d2, wd03 => mem2cache_d3, wd04 => mem2cache_d4,
    wd05 => mem2cache_d5, wd06 => mem2cache_d6, wd07 => mem2cache_d7, wd08 => mem2cache_d8,
    cache_miss_en => instr_cache_miss_en, tag => icache_tag0, index => icache_index0
  );
  instr0 <= instr0_0;

  jtype_decoder0: jtype_decoder port map (
    pc_msb4 => pc0(31 downto 28),
    instr => instr0_0,
    instr_jtype_flag => instr0_jtype_flag,
    ja => ja0
  );

  -- Decode & RegWriteBack Stage
  -- -- Decode Stage(regfile part)
  reg_instr : flopr_en_clr generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => decode_en, clr => decode_clr,
    a => instr0_0,
    y => instr1
  );

  instr_decoder0 : instr_decoder port map (
    instr => instr1,
    opcode => opcode0_0,
    rs => rs0_0, rt => rt0_0, rd => instr_rd0_0,
    immext => immext0,
    brplus => brplus0, -- for bne, beq instruction
    shamt => shamt0,
    funct => funct0
  );
  rs0 <= rs0_0; rt0 <= rt0_0;
  opcode0 <= opcode0_0;

  regfile0 : regfile port map (
    clk => clk, rst => rst,
    a1 => rs0_0, rd1 => rds0,
    a2 => rt0_0, rd2 => rdt0,
    wa => reg_wa0, wd => reg_wd0, we => reg_we0
  );

  forwarding_rds0 <= rds0 when is_X(buf_rds0) else buf_rds0;
  forwarding_rdt0 <= rdt0 when is_X(buf_rdt0) else buf_rdt0;

  cmp_eq <= '1' when forwarding_rds0 = forwarding_rdt0 else '0'; -- for beq, bne instruction

  -- -- Regfile Writeback Stage
  instr_rtrd_mux : mux2 generic map (N=>CONST_REG_SIZE)
  port map (
    d0 => rt0_0,
    d1 => instr_rd0_0,
    s => decode_rt_rd_s,
    y => instr_rtrd0
  );

  -- -- Decode Stage (pcnext part)
  reg_pc0 : flopr_en_clr generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => decode_en, clr => decode_clr,
    a => pc0,
    y => pc1
  );

  br4 <= std_logic_vector(unsigned(brplus0) + unsigned(pc1) + 4);
  pc4 <= std_logic_vector(unsigned(pc0) + 4);

  pc_br_mux2 : mux4 generic map (N=>32)
  port map (
    d00 => pc4,
    d01 => br4,
    d10 => ja0,
    d11 => pc4, -- dummy
    s => decode_pc_br_ja_s,
    y => pcnext0
  );

  -- Calc Stage
  reg_instr_rtrd0 : flopr_en_clr generic map (N=>CONST_REG_SIZE)
  port map (
    clk => clk, rst => rst, en => calc_en, clr => calc_clr, a => instr_rtrd0, y => instr_rtrd1
  );

  reg_rds : flopr_en_clr generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => calc_en, clr => calc_clr, a => forwarding_rds0, y => rds1
  );

  reg_rdt0 : flopr_en_clr generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => calc_en, clr => calc_clr, a => forwarding_rdt0, y => rdt1
  );

  reg_immext : flopr_en_clr generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => calc_en, clr => calc_clr, a => immext0, y => immext1
  );

  -- -- for regw_buffer and stall
  reg_rt0 : flopr_en_clr generic map (N=>CONST_REG_SIZE)
  port map (
    clk => clk, rst => rst, en => calc_en, clr => calc_clr, a => rt0_0, y => rt1
  );

  reg_opcode0 : flopr_en_clr generic map (N=>CONST_INSTR_OPCODE_SIZE)
  port map (
    clk => clk, rst => rst, en => calc_en, clr => calc_clr, a => opcode0_0, y => opcode1
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
    f => alu_s,
    y => aluout0
  );

  -- Data Cache Read/WriteBack Stage
  -- -- for sw instruction
  reg_rdt1 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => dcache_en,
    a => rdt1,
    y => rdt2
  );

  reg_instr_rtrd1 : flopr_en generic map (N=>5)
  port map (
    clk => clk, rst => rst, en => dcache_en,
    a => instr_rtrd1,
    y => instr_rtrd2
  );

  reg_aluout : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => dcache_en,
    a => aluout0,
    y => aluout1
  );
  dcache_a0 <= aluout1;
  dcache_wd0 <= rdt2;


  data_cache0 : data_cache port map (
    clk => clk, rst => rst, load => load,
    we => dcache_we,
    a => dcache_a0,
    wd => dcache_wd0,
    tag_s => tag_s,
    rd => dcache_rd0,
    load_en => dcache_load_en,
    wd01 => mem2cache_d1, wd02 => mem2cache_d2, wd03 => mem2cache_d3, wd04 => mem2cache_d4,
    wd05 => mem2cache_d5, wd06 => mem2cache_d6, wd07 => mem2cache_d7, wd08 => mem2cache_d8,
    rd_tag => dcache_tag0, rd_index => dcache_index0,
    rd01 => dcache2mem_d1, rd02 => dcache2mem_d2, rd03 => dcache2mem_d3, rd04 => dcache2mem_d4,
    rd05 => dcache2mem_d5, rd06 => dcache2mem_d6, rd07 => dcache2mem_d7, rd08 => dcache2mem_d8,
    cache_miss_en => data_cache_miss_en,
    valid_flag => valid_flag, dirty_flag => dirty_flag
  );

  -- -- RegWriteBack Stage
  regw_buffer0 : regw_buffer port map (
    clk => clk, rst => rst,
    -- for add(R-type), addi(part of I-type)
    wa0 => instr_rtrd1, wd0 => aluout0, we0 => reg_we1,
    -- for lw
    wa1 => instr_rtrd2, wd1 => dcache_rd0, we1 => reg_we2,
    -- out
    wa2 => reg_wa0, wd2 => reg_wd0, we2 => reg_we0,
    -- buffer search
    ra1 => rs0_0, rd1 => buf_rds0,
    ra2 => rt0_0, rd2 => buf_rdt0
  );

  -- memory
  idcache_tag_mux : mux2 generic map (N=>CONST_CACHE_TAG_SIZE)
  port map (
    d0 => icache_tag0,
    d1 => dcache_tag0,
    s => idcache_addr_s,
    y => mem_tag0
  );

  idcache_index_mux : mux2 generic map (N=>CONST_CACHE_INDEX_SIZE)
  port map (
    d0 => icache_index0,
    d1 => dcache_index0,
    s => idcache_addr_s,
    y => mem_index0
  );

  mem0 : mem generic map(filename=>memfile, BITS=>MEM_BITS_SIZE)
  port map (
    clk => clk, rst => rst, load => load,
    we => mem_we,
    tag => mem_tag0, index => mem_index0,
    -- data cache only
    wd1 => dcache2mem_d1, wd2 => dcache2mem_d2, wd3 => dcache2mem_d3, wd4 => dcache2mem_d4,
    wd5 => dcache2mem_d5, wd6 => dcache2mem_d6, wd7 => dcache2mem_d7, wd8 => dcache2mem_d8,

    rd1 => mem2cache_d1, rd2 => mem2cache_d2, rd3 => mem2cache_d3, rd4 => mem2cache_d4,
    rd5 => mem2cache_d5, rd6 => mem2cache_d6, rd7 => mem2cache_d7, rd8 => mem2cache_d8
  );
end architecture;
