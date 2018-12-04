library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cache_pkg.ALL;
use work.type_pkg.ALL;

entity datapath is
  generic(memfile : string);
  port (
    clk, rst, load : in std_logic;
    data_cache_a : in std_logic_vector(31 downto 0);
    we : in std_logic;
    wd : in std_logic_vector(31 downto 0);
    -- controller
    -- -- mem_cache
    instr_cache_miss_en, data_cache_miss_en : out std_logic;
    valid_flag : out std_logic;
    tag_s : in std_logic;
    instr_load_en, data_load_en : in std_logic;
    mem_we : in std_logic;
    -- calc
    alucont : in alucont_type;
    calc_rdt_immext_s : in std_logic;
    -- RegWritebackS
    regwb_rt_rd_s : in std_logic;
    reg_we : in std_logic;
    -- from memory
    mem2cache_d1, mem2cache_d2, mem2cache_d3, mem2cache_d4, mem2cache_d5, mem2cache_d6, mem2cache_d7, mem2cache_d8 : in std_logic_vector(31 downto 0);
    mem_tag : out std_logic;
    mem_index : out std_logic;
    dcache2mem_d1, dcache2mem_d2, dcache2mem_d3, dcache2mem_d4, dcache2mem_d5, dcache2mem_d6, dcache2mem_d7, dcache2mem_d8 : out std_logic_vector(31 downto 0);
    -- scan
    -- -- cache & memory
    pc, pcnext : out std_logic_vector(31 downto 0);
    instr : out std_logic_vector(31 downto 0);
    rd : out std_logic_vector(31 downto 0)
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

  component regw_cache
    port (
      clk, rst : in std_logic;
      wa0 : in reg_vector;
      wd0 : in std_logic_vector(31 downto 0);
      we0 : in std_logic;
      wa1 : in reg_vector;
      wd1 : in std_logic_vector(31 downto 0);
      we1 : in std_logic;
      s1 : in std_logic;
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

  -- cache & memory
  signal tag0 : std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
  signal index0 : std_logic_vector(CONST_CACHE_INDEX_SIZE-1 downto 0);
  signal data_cache_miss_en0, instr_cache_miss_en0: std_logic;

  -- enable
  signal fetch_en, decode_en, calc_en, dmemrw_en, regwb_en : std_logic;

  -- fetchS
  signal pc0, pcnext0 : std_logic_vector(31 downto 0);
  signal instr0, instr1 : std_logic_vector(31 downto 0);
  -- decodeS
  -- -- decoder
  signal opcode0 : opcode_vector;
  signal funct_opcode0, funct_opcode1 : std_logic_vector(CONST_INSTR_FUNCT_SIZE+CONST_INSTR_OPCODE_SIZE-1 downto 0);
  signal rs0, rt0, rt1, rd0, rd1, rt_rd0 : reg_vector;
  signal brplus0 : std_logic_vector(31 downto 0);
  signal funct0 : funct_vector;
  signal target2 : target2_vector;

  signal rds0, rds1, rdt0, rdt1, rdt2, immext0, immext1 : std_logic_vector(31 downto 0);
  signal rdt_immext0 : std_logic_vector(31 downto 0);
  signal shamt0, shamt1 : shamt_vector;

  -- CalCS
  signal aluout0, aluout1 : std_logic_vector(31 downto 0);
  signal alu_controller : alucont_type;

  -- RegWriteBackS
  signal wd0 : std_logic_vector(31 downto 0);

begin
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
    load_en => instr_load_en,
    wd01 => mem2cache_d1, wd02 => mem2cache_d2, wd03 => mem2cache_d3, wd04 => mem2cache_d4,
    wd05 => mem2cache_d5, wd06 => mem2cache_d6, wd07 => mem2cache_d7, wd08 => mem2cache_d8,
    cache_miss_en => instr_cache_miss_en
  );
  instr <= instr0;

  -- DecodeS
  -- -- (decoder & regfile part)
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
    brplus => brplus0, -- for bne, beq instruction
    shamt => shamt0,
    funct => funct0,
    target2 => target2 -- for j instruction
  );

  regfile0 : regfile port map (
    clk => clk, rst => rst,
    a1 => rs0, rd1 => rds0,
    a2 => rt0, rd2 => rdt0,
    wa => wa0, wd => wd0, we => reg_we
  );

  rt_rd_mux : mux2 generic map (N=>CONST_REG_SIZE)
  port map (
    d0 => rt0,
    d1 => rd0,
    s => decode_rt_rd_s,
    y => mem_wa0
  );

  -- -- (pc part)
  reg_pc0 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => decode_en,
    a => pc0,
    a => pc1
  );

  br4 <= std_logic_vector(unsigned(brplus0) + unsigned(pc1) + 4);
  pc4 <= std_logic_vector(unsigned(pc0) + 4);
  ja <= pc1(31 downto 28) & target2;

  pc_br_ja_mux4 : mux4 generic map (N=>32)
  port map (
    d00 => pc4,
    d01 => br4,
    d10 => ja,
    d11 => pc4, -- dummy
    s => decodes_pc_br_ja_s,
    y => pcnext0
  );
  pcnext <= pcnext0; -- for scan

  -- CalcS
  reg_rt_rd : flopr_en generic map (N=>CONST_REG_SIZE)
  port map (
    clk => clk, rst => rst, en => calc_en, a => mem_wa0, y => mem_wa1
  );

  reg_rds : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => calc_en, a => rds0, y => rds1
  );

  reg_rdt0 : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => calc_en, a => rdt0, y => rdt1
  );

  reg_immext : flopr_en generic map (N=>32)
  port map (
    clk => clk, rst => rst, en => calc_en, a => immext0, y => immext1
  );

  funct_opcode0 <= funct0 & opcode0;
  reg_funct : flopr_en generic map (N=>CONST_INSTR_FUNCT_SIZE+CONST_INSTR_OPCODE_SIZE)
  port map (
    clk => clk, rst => rst, en => calc_en, a => funct_opcode0, y => funct_opcode1
  );
  funct1 <= funct_opcode1(11 downto 6);
  opcode1 <= funct_opcode1(5 downto 0);

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
  reg_rdt1 : flopr_en generic map (N=>32)
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
    tag_s => tag_s,
    rd => mem_rd0,
    load_en => data_load_en,
    wd01 => mem2cache_d1, wd02 => mem2cache_d2, wd03 => mem2cache_d3, wd04 => mem2cache_d4,
    wd05 => mem2cache_d5, wd06 => mem2cache_d6, wd07 => mem2cache_d7, wd08 => mem2cache_d8,
    rd_tag => mem_tag, rd_index => mem_index,
    rd01 => dcache2mem_d1, rd02 => dcache2mem_d2, rd03 => dcache2mem_d3, rd04 => dcache2mem_d4,
    rd05 => dcache2mem_d5, rd06 => dcache2mem_d6, rd07 => dcache2mem_d7, rd08 => dcache2mem_d8,
    cache_miss_en => data_cache_miss_en, valid_flag => valid_flag
  );
  rd <= rdt0;

  -- -- RegWriteBackS

  regw_cache0 : regw_cache0 port map (
    clk => clk, rst => rst,
    -- for add(R-type), addi(part of I-type)
    wa0 => mem_wa1, wd0 => aluout0, we0 => we1,
    s => regw_s,
    -- for lw
    wa1 => mem_wa2, wd1 => mem_rd0, we1 => we2,
    -- out
    wa2 => reg_wa0, wd2 => reg_wd0, we2 => reg_we0,
    -- cache search
    ra1 => rs0, rd1 => pre_rds0,
    ra1 => rt0, rd2 => pre_rdt0
  );

end architecture;
