library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity regw_buffer is
  port (
    clk, rst : in std_logic;
    en0 : in std_logic;
    en1 : in std_logic;
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
end entity;

architecture behavior of regw_buffer is
  component shift2_register_load is
    generic(N : natural);
    port (
      clk, rst : in std_logic;
      en0, en1 : in std_logic;
      s1 : in std_logic;
      a0 : in std_logic_vector(N-1 downto 0);
      load1 : in std_logic_vector(N-1 downto 0);
      a1, a2 : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component regw_buffer_search
    port (
      wa0, wa1, wa2 : in reg_vector;
      wd0, wd1, wd2 : in std_logic_vector(31 downto 0);
      we0, we1, we2 : in std_logic;
      ra : in reg_vector;
      rd : out std_logic_vector(31 downto 0)
    );
  end component;

  signal w0, w1, load1, w2 : std_logic_vector(32+CONST_REG_SIZE+1-1 downto 0);
  signal wa1_0, wa2_0 : reg_vector;
  signal wd1_0, wd2_0 : std_logic_vector(31 downto 0);
  signal we1_0, we2_0 : std_logic;
begin

  w0 <= we0 & wd0 & wa0;
  load1 <= we1 & wd1 & wa1;
  shift2_register_load0 : shift2_register_load generic map (N=>32+CONST_REG_SIZE+1)
  port map (
    clk => clk, rst => rst,
    en0 => '1', en1 => '1',
    s1 => we1,
    a0 => w0,
    load1 => load1,
    a1 => w1,
    a2 => w2
  );

  we1_0 <= w1(32+CONST_REG_SIZE);
  wd1_0 <= w1(32+CONST_REG_SIZE-1 downto CONST_REG_SIZE);
  wa1_0 <= w1(CONST_REG_SIZE-1 downto 0);
  we2_0 <= w2(32+CONST_REG_SIZE);
  wd2_0 <= w2(32+CONST_REG_SIZE-1 downto CONST_REG_SIZE);
  wa2_0 <= w2(CONST_REG_SIZE-1 downto 0);

  we2 <= we2_0; wd2 <= wd2_0; wa2 <= wa2_0;

  ra1_search : regw_buffer_search port map (
    wa0 => wa0, wa1 => wa1_0, wa2 => wa2_0,
    wd0 => wd0, wd1 => wd1_0, wd2 => wd2_0,
    we0 => we0, we1 => we1_0, we2 => we2_0,
    ra => ra1,
    rd => rd1
  );

  ra2_search : regw_buffer_search port map (
    wa0 => wa0, wa1 => wa1_0, wa2 => wa2_0,
    wd0 => wd0, wd1 => wd1_0, wd2 => wd2_0,
    we0 => we0, we1 => we1_0, we2 => we2_0,
    ra => ra2,
    rd => rd2
  );

end architecture;
