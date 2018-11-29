library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flopr8_en is
  generic(N : natural);
  port (
    clk, rst, en : in std_logic;
    a1, a2, a3, a4, a5, a6, a7, a8 : in std_logic_vector(N-1 downto 0);
    y1, y2, y3, y4, y5, y6, y7, y8 : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture behavior of flopr8_en is
  component flopr_en
    generic(N : natural);
    port (
      clk, rst, en: in std_logic;
      a : in std_logic_vector(N-1 downto 0);
      y : out std_logic_vector(N-1 downto 0)
    );
  end component;
begin
  flopr_en1: flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en,
    a => a1,
    y => y1
  );

  flopr_en2: flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en,
    a => a2,
    y => y2
  );

  flopr_en3: flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en,
    a => a3,
    y => y3
  );

  flopr_en4: flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en,
    a => a4,
    y => y4
  );

  flopr_en5: flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en,
    a => a5,
    y => y5
  );

  flopr_en6: flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en,
    a => a6,
    y => y6
  );

  flopr_en7: flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en,
    a => a7,
    y => y7
  );

  flopr_en8: flopr_en generic map (N=>N)
  port map (
    clk => clk, rst => rst, en => en,
    a => a8,
    y => y8
  );

end architecture;
