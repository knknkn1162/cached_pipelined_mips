library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.debug_pkg.ALL;
use work.state_pkg.ALL;
use work.type_pkg.ALL;

entity beq_tb is
end entity;

architecture testbench of beq_tb is
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
      suspend, stall, halt : out std_logic
    );
  end component;

  constant memfile : string := "./assets/beq.hex";
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
  signal suspend, stall, halt : std_logic;
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
    suspend => suspend, stall => stall, halt => halt
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
    -- addi $s0, $0, 5
    -- add $s1, $s0, $s0
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
    assert icache_load_en = '0'; assert dcache_load_en = '0'; assert suspend = '1';
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
    -- -- FetchS : addi $t0, $0, 5
    assert pc = X"00000000"; assert pcnext = X"00000004";
    assert instr = X"20100005";
    -- (not yet)
    assert rds = X"00000000"; assert immext = X"00000000";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    -- -- DecodeS : addi $s0, $0, 5
    assert rds = X"00000000"; assert immext = X"00000005";
    -- -- FetchS : addi $s1, $0, 5
    assert pc = X"00000004"; assert pcnext = X"00000008";
    assert instr = X"20110005";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    -- CalcS(AddiCalcS) : addi $s0, $0, 5
    assert aluout = X"00000005";
    -- DecodeS : addi $s1, $0, 5
    assert rds = X"00000000"; assert immext = X"00000005";
    -- FetchS : addi $s2, $0, 6
    assert pc = X"00000008"; assert pcnext = X"0000000C";
    assert instr = X"20120006";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    -- Nop : (addi $s0, $0, 5)
    -- CalcS : addi $s1, $0, 5
    assert aluout = X"00000005";
    -- DecodeS : addi $s2, $0, 6
    assert rds = X"00000000"; assert immext = X"00000006";
    -- FetchS : beq $s0, $s2, 12
    assert pc = X"0000000C"; assert pcnext = X"00000010";
    assert instr = X"1212000C";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0';
    -- RegWrite : addi $s0, $0, 5
    assert reg_wa = "10000"; assert reg_wd = X"00000005";
    -- Nop : (addi $s1, $0, 5)
    -- CalcS : addi $s2, $0, 6
    assert aluout = X"00000006";
    -- DecodeS : beq $s0, $s2, 12 [ shouldnt be taken ]
    assert rds = X"00000005";
    assert rdt = X"00000006";
    assert immext = X"0000000C";
    -- FetchS : beq $s0, $s1, 12
    assert pc = X"00000010"; assert pcnext = X"00000014";
    assert instr = X"1211000C";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0';
    -- RegWrite : addi $s1, $0, 5
    assert reg_wa = "10001"; assert reg_wd = X"00000005";
    -- Nop : (addi $s2, $0, 6)
    -- CalcS : nop
    -- DecodeS : beq $s0, $s1, 12 [ should be taken ]
    assert rds = X"00000005";
    assert rdt = X"00000004";
    assert immext = X"0000000C";
    -- FetchS : addi $s0, $0, 5
    assert pc = X"00000014"; assert pcnext = X"00000018";
    assert instr = X"20100005";
    wait until rising_edge(clk); wait for 1 ns;

    assert state = NormalS;
    assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0';
    -- RegWrite : addi $s2, $0, 6
    assert reg_wa = "10010"; assert reg_wd = X"00000006";
    -- CalcS : nop
    assert aluout = X"00000009";
    -- DecodeS : (purge)
    assert rds = X"00000000"; assert rdt = X"00000000";
    -- FetchS : add $s1, $s0, $s1
    assert pc = X"00000020"; assert pcnext = X"00000024";
    wait until rising_edge(clk); wait for 1 ns;

    -- assert state = NormalS;
    -- assert dcache_we = '0'; assert reg_we = '0'; assert suspend = '0'; assert stall = '0';
    -- -- addi $s2, $s1, 4
    -- -- CalcS : add $t1, $s1, $s2
    -- assert aluout = X"0000000E";
    -- -- DecodeS, FetchS (nop)
    -- wait until rising_edge(clk); wait for 1 ns;

    -- assert state = NormalS;
    -- assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0';
    -- -- addi $s2, $s1, 4
    -- assert reg_wa = "10010"; assert reg_wd = X"00000009";
    -- -- (add $t1, $s1, $s2)
    -- -- CalcS, DecodeS, FetchS (nop)
    -- wait until rising_edge(clk); wait for 1 ns;

    -- assert state = NormalS;
    -- assert dcache_we = '0'; assert reg_we = '1'; assert suspend = '0'; assert stall = '0';
    -- -- add $t1, $s1, $s2
    -- assert reg_wa = "01001"; assert reg_wd = X"0000000E";
    -- -- CalcS, DecodeS, FetchS (nop)

    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
