library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity shift2_register_load is
  generic(N : natural);
  port (
    clk, rst : in std_logic;
    en0, en1 : in std_logic;
    s1 : in std_logic;
    a0 : in std_logic_vector(N-1 downto 0);
    load1 : in std_logic_vector(N-1 downto 0);
    a1, a2 : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture behavior of shift2_register_load is
  component flopr_en is
    generic(N : natural);
    port (
      clk, rst, en : in std_logic;
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
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

  signal a0_1 : std_logic_vector(N-1 downto 0);
  signal a1_0 : std_logic_vector(N-1 downto 0);

begin
  reg_a0 : flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en0,
    a => a0,
    y => a0_1
  );

  a01_load1_mux : mux2 generic map (N=>N)
  port map (
    d0 => a0_1,
    d1 => load1,
    s => s1,
    y => a1_0
  );
  a1 <= a1_0;

  reg_a1 : flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en1,
    a => a1_0,
    y => a2
  );
end architecture;
