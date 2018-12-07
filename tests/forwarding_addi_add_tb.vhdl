library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.debug_pkg.ALL;
use work.type_pkg.ALL;

entity forwarding_addi_add_tb is
end entity;

architecture testbench of forwarding_addi_add_tb is
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
      icache_miss_en, dcache_miss_en : out std_logic;
      icache_load_en, dcache_load_en : out std_logic;
      suspend_flag : out std_logic
    );
  end component;

  constant memfile : string := "./assets/forwarding_addi_add.hex";
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
  signal flopen_state : flopen_state_vector;
  signal icache_miss_en, dcache_miss_en : std_logic;
  signal icache_load_en, dcache_load_en : std_logic;
  signal suspend_flag : std_logic;
  constant clk_period : time := 10 ns;
  signal stop : boolean;

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
    icache_miss_en => icache_miss_en, dcache_miss_en => dcache_miss_en,
    icache_load_en => icache_load_en, dcache_load_en => dcache_load_en,
    suspend_flag => suspend_flag
  );

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
    assert pc = X"00000000"; assert pcnext = X"00000004";
    assert dcache_miss_en = '0'; assert icache_miss_en = '0';
    wait until rising_edge(clk); wait for 1 ns;
    -- Load (cache_miss)
    assert dcache_miss_en = '1'; assert icache_miss_en = '1'; assert suspend_flag = '1';
    wait until rising_edge(clk);
    assert suspend_flag = '1';
    wait for 1 ns;
    -- (instr: Mem2CacheS, mem : NormalS)
    assert icache_load_en = '0'; assert dcache_load_en = '0'; assert suspend_flag = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- (instr: CacheWriteBackS, mem : Mem2CacheS)
    assert icache_load_en = '1'; assert dcache_load_en = '0'; assert suspend_flag = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- (instr: NormalS, mem : CacheWriteBackS)
    assert icache_load_en = '0'; assert dcache_load_en = '1'; assert suspend_flag = '1';
    wait until rising_edge(clk); wait for 1 ns;
    -- NormalS (restore from SuspendS)
    wait until rising_edge(clk); wait for 1 ns;
    assert icache_load_en = '0'; assert dcache_load_en = '0'; assert suspend_flag = '0';

    -- (FetchS, InitS)
    -- -- FetchS : addi $t0, $0, 5
    -- assert pc = X"00000000"; assert pcnext = X"00000004";
    -- -- cache miss!
    -- assert instr = X"20100005";
    -- -- (not yet)
    -- assert rds = X"00000000"; assert immext = X"00000000";
    -- wait for clk_period;

    -- -- (DecodeS, FetchS)
    -- -- -- DecodeS : addi $s0, $0, 5
    -- assert rds = X"00000000"; assert immext = X"00000005";
    -- -- -- FetchS : add $s1, $s0, $s0
    -- assert pc = X"00000004"; assert pcnext = X"00000008";
    -- assert instr = X"02108800";
    -- wait for clk_period;

    -- -- (CalcS, DecodeS)
    -- assert pc = X"00000008"; assert pcnext = X"0000000C";
    -- -- CalcS(AddiCalcS) : addi $t0, $s0, 5
    -- assert aluout = X"0000000A";
    -- -- DecodeS : add $s1, $s0, $s0
    -- assert rds = X"00000005"; assert rdt = X"00000005"; -- forwarding for pipeline
    -- assert dcache_we = '0'; assert reg_we = '0';
    -- wait for clk_period;

    -- -- (- , CalcS(RtypeCalcS))
    -- -- CalcS : add $s1, $s0, $s0
    -- assert aluout = X"0000000A";
    -- assert dcache_we = '0'; assert reg_we = '0';
    -- wait for clk_period;

    -- assert reg_wa = "10000"; assert reg_wd = X"00000005";
    -- assert reg_we = '1'; assert dcache_we = '0';
    -- wait for clk_period;

    -- assert reg_wa = "10001"; assert reg_wd = X"0000000A";
    -- assert reg_we = '1'; assert dcache_we = '0';
    -- skip
    stop <= TRUE;
    -- success message
    assert false report "end of test" severity note;
    wait;
  end process;
end architecture;
