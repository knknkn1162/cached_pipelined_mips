library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.debug_pkg.ALL;
use work.state_pkg.ALL;
use work.type_pkg.ALL;

entity memfile_tb is
end entity;

architecture testbench of memfile_tb is
  component mips
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
      suspend, stall, halt, branch_taken : out std_logic
    );
  end component;

  constant memfile : string := "./assets/memfile.hex";
  signal clk, rst : std_logic;
  signal pc, pcnext : std_logic_vector(31 downto 0);
  signal instr : std_logic_vector(31 downto 0);
  signal addr, dcache_rd, dcache_wd : std_logic_vector(31 downto 0);
  signal dcache_we : std_logic;
  signal reg_wa : reg_vector;
  signal reg_wd : std_logic_vector(31 downto 0);
  signal reg_we : std_logic;
  signal rds, rdt, immext : std_logic_vector(31 downto 0);
  signal ja : std_logic_vector(31 downto 0);
  signal aluout : std_logic_vector(31 downto 0);
  -- for controller
  signal flopen_state_vec : flopen_state_vector;
  signal icache_load_en, dcache_load_en : std_logic;
  signal suspend, stall, halt, branch_taken : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;
  signal state : flopen_statetype;

begin
  mips0 : mips generic map(memfile=>memfile)
  port map (
    clk => clk, rst => rst,
    -- -- datapath
    pc => pc, pcnext => pcnext,
    instr => instr,
    addr => addr, dcache_rd => dcache_rd, dcache_wd => dcache_wd,
    dcache_we => dcache_we,
    reg_wa => reg_wa, reg_wd => reg_wd, reg_we => reg_we,
    rds => rds, rdt => rdt, immext => immext,
    ja => ja, aluout => aluout,
    flopen_state => flopen_state_vec,
    icache_load_en => icache_load_en, dcache_load_en => dcache_load_en,
    suspend => suspend, stall => stall, halt => halt, branch_taken => branch_taken
  );

  state <= encode_flopen_state(flopen_state_vec);

  clk_process: process
  begin
    while not stop loop
      clk <= '0'; wait for clk_period/2;
      clk <= '1'; wait for clk_period/2;
    end loop;
    wait;
  end process;

  stim_proc : process
  begin
    wait for clk_period;
    rst <= '1'; wait for 1 ns; rst <= '0';
    assert state = ResetS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    assert pc = X"00000000"; assert pcnext = X"00000004";
    wait until rising_edge(clk); wait for 1 ns;
    -- Load (cache_miss)
    assert state = LoadS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '1';
    wait until rising_edge(clk); wait for 1 ns;

    -- (instr: Mem2CacheS, mem : NormalS)
    assert state = SuspendS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '1'; assert stall = '0';
    assert icache_load_en = '0'; assert dcache_load_en = '0';
    wait until rising_edge(clk); wait for 1 ns;

    -- (instr: CacheWriteBackS, mem : Mem2CacheS)
    assert state = SuspendS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '1'; assert stall = '0';
    assert icache_load_en = '1'; assert dcache_load_en = '0';
    wait until rising_edge(clk); wait for 1 ns;

    -- (instr: NormalS, mem : CacheWriteBackS)
    assert state = SuspendS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '1'; assert stall = '0';
    assert icache_load_en = '0'; assert dcache_load_en = '1';
    wait until rising_edge(clk); wait for 1 ns;

    -- (FetchS, InitS) (restore from SuspendS)
    assert state = SuspendS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    assert icache_load_en = '0'; assert dcache_load_en = '0';
    -- FetchS : addi $2, $0, 5
    assert pc = X"00000000"; assert pcnext = X"00000004";
    assert instr = X"20020005";
    -- (not yet)
    assert rds = X"00000000"; assert immext = X"00000000";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    -- DecodeS : 00: addi $2, $0, 5
    assert rds = X"00000000"; assert immext = X"00000005";
    -- FetchS : 04: addi $3, $0, 12 # initialize $3 = 12 4
    assert pc = X"00000004"; assert pcnext = X"00000008";
    assert instr = X"2003000c";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    -- CalcS : : 00: addi $2, $0, 5
    assert aluout = X"00000005";
    -- DecodeS : 04: addi $3, $0, 12 # initialize $3 = 12 4
    assert rds = X"00000000"; assert immext = X"0000000C";
    -- FetchS : 08: addi $7, $3, -9 # initialize $7 = 3  8
    assert pc = X"00000008"; assert pcnext = X"0000000C";
    assert instr = X"2067fff7";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    -- (00 : addi $2, $0, 5)
    -- CalcS : 04: addi $3, $0, 12 # initialize $3 = 12
    assert aluout = X"0000000C";
    -- DecodeS : 08: addi $7, $3, -9 # initialize $7 = 3
    assert rds = X"0000000C"; assert immext = X"FFFFFFF7";
    -- FetchS : 0C or   $4, $7, $2     # $4 <= 3 or 5 = 7
    assert pc = X"0000000C"; assert pcnext = X"00000010";
    assert instr = X"00e22025";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0';
    -- RegWriteBackS : 00: addi $2, $0, 5
    assert reg_wa = "00010"; assert reg_wd = X"00000005";
    -- (04: addi $3, $0, 12) # initialize $3 = 12
    -- CalcS : 08: addi $7, $3, -9 # initialize $7 = 3
    assert aluout = X"00000003";
    -- DecodeS : 0C: or   $4, $7, $2     # $4 <= 3 or 5 = 7
    assert rds = X"00000003"; assert rdt = X"00000005";
    -- FetchS : 10: and $5,  $3, $4     # $5 <= 12 and 7 = 4
    assert pc = X"00000010"; assert pcnext = X"00000014";
    assert instr = X"00642824";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0';
    -- RegWriteBackS : 04: addi $3, $0, 12) # initialize $3 = 12
    assert reg_wa = "00011"; assert reg_wd = X"0000000C";
    -- (08: addi $7, $3, -9 # initialize $7 = 3)
    -- CalcS: 0C: or   $4, $7, $2     # $4 <= 3 or 5 = 7
    assert aluout = X"00000007";
    -- DecodeS: 10: and $5,  $3, $4     # $5 <= 12 and 7 = 4
    assert rds = X"0000000C"; assert rdt = X"00000007";
    -- FetchS: 14: add $5,  $5, $4     # $5 = 4 + 7 = 11
    assert pc = X"00000014"; assert pcnext = X"00000018";
    assert instr = X"00a42820";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0';
    -- RegWriteBackS : 08: addi $7, $3, -9 # initialize $7 = 3)
    assert reg_wa = "00111"; assert reg_wd = X"00000003";
    -- (0C: or   $4, $7, $2     # $4 <= 3 or 5 = 7)
    -- CalcS: 10: and $5,  $3, $4     # $5 <= 12 and 7 = 4
    assert aluout = X"00000004";
    -- DecodeS: 14: add $5,  $5, $4     # $5 = 4 + 7 = 11
    assert rds = X"00000004"; assert rdt = X"00000007";
    -- FetchS: 18: beq $5,  $7, end    # shouldnt be taken
    assert pc = X"00000018"; assert pcnext = X"0000001C";
    assert instr = X"10a7000a";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0'; assert branch_taken = '0';
    -- RegWriteBackS : 0C: or   $4, $7, $2     # $4 <= 3 or 5 = 7
    assert reg_wa = "00100"; assert reg_wd = X"00000007";
    -- (10: and $5,  $3, $4     # $5 <= 12 and 7 = 4)
    -- CalcS: 14: add $5,  $5, $4     # $5 = 4 + 7 = 11
    assert aluout = X"0000000B";
    -- DecodeS: 18: beq $5,  $7, end    # shouldnt be taken
    assert rds = X"0000000B"; assert rdt = X"00000003";
    -- FetchS: 1C: slt $4,  $3, $4     # $4 = 12 < 7 = 0
    assert pc = X"0000001C"; assert pcnext = X"00000020";
    assert instr = X"0064202a";
    wait until rising_edge(clk); wait for 1 ns;

    -- cache miss!
    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '1'; assert stall = '0'; assert branch_taken = '0';
    -- RegWriteBackS: 10: and $5,  $3, $4     # $5 <= 12 and 7 = 4)
    assert reg_wa = "00101"; assert reg_wd = X"00000004";
    -- (14: add $5,  $5, $4     # $5 = 4 + 7 = 11)
    -- CalcS: (nop)
    -- DecodeS: 1C: slt $4,  $3, $4     # $4 = 12 < 7 = 0
    assert rds = X"0000000C"; assert rdt = X"00000007";
    -- FetchS: 20: beq $4,  $0, around # should be taken [cache miss!]
    assert pc = X"00000020"; assert pcnext = X"00000024";
    assert instr /= X"10800001";
    wait until rising_edge(clk); wait for 1 ns;

    -- instr miss(Mem2CacheS)
    assert state = SuspendS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '1'; assert stall = '0';
    -- RegWriteBackS 14: add $5,  $5, $4     # $5 = 4 + 7 = 11
    assert reg_wa = "00101"; assert reg_wd = X"0000000B";
    assert icache_load_en = '0'; assert dcache_load_en = '0';
    assert pc = X"00000020"; assert pcnext = X"00000024";
    wait until rising_edge(clk); wait for 1 ns;

    -- instr: CacheWriteBackS
    assert state = SuspendS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '1'; assert stall = '0';
    assert icache_load_en = '1'; assert dcache_load_en = '0';
    assert pc = X"00000020"; assert pcnext = X"00000024";
    wait until rising_edge(clk); wait for 1 ns;

    -- instr: NormalS(cache hit!)
    assert state = SuspendS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0'; assert branch_taken = '0';
    assert icache_load_en = '0'; assert dcache_load_en = '0';
    -- FetchS : add $s1, $s0, $s1 [cache_hit!]
    assert pc = X"00000020"; assert pcnext = X"00000024";
    assert instr = X"10800001";
    wait until rising_edge(clk); wait for 1 ns;

    -- NormalS
    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0'; assert branch_taken = '1';
    -- CalcS: 1C: slt $4,  $3, $4     # $4 = 12 < 7 = 0
    assert aluout = X"00000000";
    -- DecodeS: 20: beq $4,  $0, around # should be taken
    assert rds = X"00000000"; assert rdt = X"00000000";
    -- FetchS: 24: addi $5, $0, 0      # shouldnt happen
    assert pc = X"00000024"; assert pcnext = X"00000028";
    assert instr = X"20050000";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0'; assert branch_taken = '0';
    -- (1C: slt $4,  $3, $4     # $4 = 12 < 7 = 0)
    -- CalcS: (nop)
    -- DecodeS: (purged)
    -- FetchS: 28: slt $4,  $7, $2     # $4 = 3 < 5 = 1
    assert pc = X"00000028"; assert pcnext = X"0000002C";
    assert instr = X"00e2202a";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0'; assert branch_taken = '0';
    -- RegWriteBackS: 1C: slt $4,  $3, $4     # $4 = 12 < 7 = 0
    assert reg_wa = "00100"; assert reg_wd = X"00000000";
    -- CalcS: (purged)
    -- DecodeS: 28: slt $4,  $7, $2     # $4 = 3 < 5 = 1
    assert rds = X"00000003"; assert rdt = X"00000005";
    -- FetchS: 2C: add $7,  $4, $5     # $7 = 1 + 11 = 12
    assert pc = X"0000002C"; assert pcnext = X"00000030";
    assert instr = X"00853820";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0'; assert branch_taken = '0';
    -- CalcS: 28: slt $4,  $7, $2     # $4 = 3 < 5 = 1
    assert aluout = X"00000001";
    -- DecodeS: 2C: add $7,  $4, $5     # $7 = 1 + 11 = 12
    assert rds = X"00000001"; assert rdt = X"0000000B";
    -- FetchS: 30: sub $7,  $7, $2     # $7 = 12 - 5 = 7
    assert pc = X"00000030"; assert pcnext = X"00000034";
    assert instr = X"00e23822";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0'; assert branch_taken = '0';
    -- (28: slt $4,  $7, $2     # $4 = 3 < 5 = 1)
    -- CalcS: 2C: add $7,  $4, $5     # $7 = 1 + 11 = 12
    assert aluout = X"0000000C";
    -- DecodeS: 30: sub $7,  $7, $2     # $7 = 12 - 5 = 7
    assert rds = X"0000000C"; assert rdt = X"00000005";
    -- FetchS: 34: sw   $7, 68($3)     # [80] = 7
    assert pc = X"00000034"; assert pcnext = X"00000038";
    assert instr = X"ac670044";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0'; assert branch_taken = '0';
    -- RegWriteBackS: 28: slt $4,  $7, $2     # $4 = 3 < 5 = 1
    assert reg_wa = "00100"; assert reg_wd = X"00000001";
    -- (2C: add $7,  $4, $5     # $7 = 1 + 11 = 12)
    -- CalcS: 30: sub $7,  $7, $2     # $7 = 12 - 5 = 7
    assert aluout = X"00000007";
    -- DecodeS: 34: sw   $7, 68($3)     # [80] = 7
    assert rds = X"0000000C"; assert immext = X"00000044";
    -- FetchS : 38 lw   $2, 80($0)     # $2 = [80] = 7
    assert pc = X"00000038"; assert pcnext = X"0000003C";
    assert instr = X"8c020050";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0'; assert branch_taken = '0';
    -- RegWriteBackS: 2C: add $7,  $4, $5     # $7 = 1 + 11 = 12
    assert reg_wa = "00111"; assert reg_wd = X"0000000C";
    -- (30: sub $7,  $7, $2     # $7 = 12 - 5 = 7)
    -- CalcS: 34: sw   $7, 68($3)     # [80] = 7
    assert aluout = X"00000050";
    -- DecodeS: 38: lw   $2, 80($0)     # $2 = [80] = 7
    assert rds = X"00000000"; assert immext = X"00000050";
    -- FetchS: 3C: j    end            # should be taken
    assert pc = X"0000003C"; assert pcnext = X"00000040";
    assert instr = X"08000011";
    wait until rising_edge(clk); wait for 1 ns;

    -- instr & data cache miss!
    assert state = NormalS;
    assert dcache_we = '1'; assert reg_we = '1'; assert suspend = '1'; assert stall = '0'; assert branch_taken = '0';
    -- RegWriteBackS: 30: sub $7,  $7, $2     # $7 = 12 - 5 = 7
    assert reg_wa = "00111"; assert reg_wd = X"00000007";
    -- MemWriteBackS: 34: sw   $7, 68($3)     # [80] = 7
    assert addr = X"00000050"; assert dcache_wd = X"00000007"; -- cache_miss!
    -- CalcS: 38: lw   $2, 80($0)     # $2 = [80] = 7
    assert aluout = X"00000050";
    -- DecodeS: 3C: j    end            # should be taken
    assert ja = X"00000044";
    -- FetchS: addi $2, $0, 1      # shouldnt happen -- cache_miss!
    assert pc = X"00000040"; assert pcnext = X"00000044";
    assert instr /= X"20020001";
    wait until rising_edge(clk); wait for 1 ns;

    -- (instr: Mem2CacheS, mem : NormalS)
    assert state = SuspendS;
    assert dcache_we = '1'; assert reg_we = '0'; assert suspend = '1'; assert stall = '0';
    assert icache_load_en = '0'; assert dcache_load_en = '0';
    wait until rising_edge(clk); wait for 1 ns;

    -- (instr: CacheWriteBackS, mem : Mem2CacheS)
    assert state = SuspendS;
    assert dcache_we = '1'; assert reg_we = '0'; assert suspend = '1'; assert stall = '0';
    assert icache_load_en = '1'; assert dcache_load_en = '0';
    wait until rising_edge(clk); wait for 1 ns;

    -- (instr: NormalS, mem : CacheWriteBackS)
    assert state = SuspendS;
    assert dcache_we = '1'; assert reg_we = '0'; assert suspend = '1'; assert stall = '0';
    assert icache_load_en = '0'; assert dcache_load_en = '1';
    wait until rising_edge(clk); wait for 1 ns;

    -- (FetchS, InitS) (restore from SuspendS)
    assert state = SuspendS;
    assert dcache_we = '1'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    assert icache_load_en = '0'; assert dcache_load_en = '0';
    -- MemWriteBackS: 34: sw   $7, 68($3)     # [80] = 7
    assert addr = X"00000050"; assert dcache_wd = X"00000007"; -- cache hit!
    -- CalcS: 38: lw   $2, 80($0)     # $2 = [80] = 7
    -- assert aluout = X"00000050";
    -- -- DecodeS: 3C: j    end            # should be taken
    -- assert ja = X"00000044";
    -- -- FetchS: 40: addi $2, $0, 1      # shouldnt happen -- cache_miss!
    -- assert pc = X"00000040"; assert pcnext = X"00000044";
    -- assert instr = X"20020001";
    -- wait until rising_edge(clk); wait for 1 ns;

    -- -- NormalS
    -- assert state = NormalS;
    -- assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    -- -- MemWeadS: 38: lw   $2, 80($0)     # $2 = [80] = 7
    -- assert addr = X"00000050"; assert dcache_rd = X"00000007"; -- cache_hit!
    -- -- CalcS: (nop)
    -- -- DecodeS: (purged)
    -- assert rds = X"00000000"; assert immext = X"00000000";
    -- -- FetchS: 44: sw   $2, 84($0)     # write adr 84 = 7
    -- assert pc = X"00000044"; assert pcnext = X"00000048";
    -- assert instr = X"ac020054";
    -- wait until rising_edge(clk); wait for 1 ns;

    -- assert state = NormalS;
    -- assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0';
    -- assert halt = '1';
    -- -- RegWriteBackS: 38: lw   $2, 80($0)     # $2 = [80] = 7
    -- assert reg_wa = "00010"; assert reg_wd = X"00000007";
    -- -- CalcS: (purged)
    -- -- DecodeS: 44 sw   $2, 84($0)     # write adr 84 = 7
    -- assert rds = X"00000000"; assert immext = X"00000054";
    -- assert pc = X"00000044"; assert pcnext = X"00000048";
    -- assert instr = X"00000000";



    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
