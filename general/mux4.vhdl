library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux4 is
  generic (N : natural);
  port (
    d00 : in std_logic_vector(N-1 downto 0);
    d01 : in std_logic_vector(N-1 downto 0);
    d10 : in std_logic_vector(N-1 downto 0);
    d11 : in std_logic_vector(N-1 downto 0);
    s : in std_logic_vector(1 downto 0);
    y : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture behavior of mux4 is
begin
  process(d00, d01, d10, d11, s)
  begin
    case s is
      when "00" => y <= d00;
      when "01" => y <= d01;
      when "10" => y <= d10;
      when "11" => y <= d11;
      when others => y <= (others => 'X');
    end case;
  end process;
end architecture;
