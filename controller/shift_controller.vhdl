library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity shift_controller is
  port (
    clk, rst : in std_logic;
    decode_en, decode_clr, calc_clr, dcache_en : in std_logic;
    instr_valid0 : in std_logic;
    calc_rdt_immext_s0, dcache_we0, reg_we2_0, reg_we1_0 : in std_logic;
    alu_s0 : in alucont_type;
    instr_valid1 : out std_logic;
    calc_rdt_immext_s1, reg_we1 : out std_logic;
    dcache_we2, reg_we2 : out std_logic;
    alu_s1 : out alucont_type
  );
end entity;

architecture behavior of shift_controller is
  constant N0 : natural := 7;
  constant N1 : natural := 2;
  signal cont0, cont1 : std_logic_vector(N0-1 downto 0);
  signal cont1_1, cont2 : std_logic_vector(N1-1 downto 0);

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

  component bflopr_en_clr
    port (
      clk, rst, en, clr: in std_logic;
      a : in std_logic;
      y : out std_logic
    );
  end component;

begin
  flopr_instr_valid : bflopr_en_clr port map (
    clk => clk, rst => rst, en => decode_en, clr => decode_clr,
    a => instr_valid0,
    y => instr_valid1
  );

  cont0 <= dcache_we0 & reg_we2_0 & calc_rdt_immext_s0 & reg_we1_0 & alu_s0;

  -- shift
  flopr_cont0 : flopr_clr generic map (N=>N0)
  port map (
    clk => clk, rst => rst, clr => calc_clr,
    a => cont0,
    y => cont1
  );
  cont1_1 <= cont1(N0-1 downto N0-N1);

  flopr_cont1 : flopr_en generic map (N=>N1)
  port map (
    clk => clk, rst => rst, en => dcache_en,
    a => cont1_1,
    y => cont2
  );

  alu_s1 <= cont1(2 downto 0);
  reg_we1 <= cont1(3);
  calc_rdt_immext_s1 <= cont1(4);
  reg_we2 <= cont2(0);
  dcache_we2 <= cont2(1);
end architecture;
