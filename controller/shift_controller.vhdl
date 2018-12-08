library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity shift_controller is
  port (
    clk, rst : in std_logic;
    decode_en, calc_en, calc_clr, dcache_en : in std_logic;
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

  component flopr_en_clr
    generic(N : natural);
    port (
      clk, rst, en, clr: in std_logic;
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;

  signal instr_valid0_vec, instr_valid1_vec : std_logic_vector(0 downto 0);
begin
  instr_valid0_vec <= instr_valid0 & "";
  flopr_instr_valid : flopr_en generic map(N=>1)
  port map (
    clk => clk, rst => rst, en => decode_en,
    a => instr_valid0_vec,
    y => instr_valid1_vec
  );
  instr_valid1 <= instr_valid1_vec(0);

  cont0 <= dcache_we0 & reg_we2_0 & calc_rdt_immext_s0 & reg_we1_0 & alu_s0;

  -- shift
  flopr_cont0 : flopr_en_clr generic map (N=>N0)
  port map (
    clk => clk, rst => rst, en => calc_en, clr => calc_clr,
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
