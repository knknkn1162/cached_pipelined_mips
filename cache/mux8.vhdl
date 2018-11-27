library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux8 is
  generic(N : integer);
  port (
    d000 : in std_logic_vector(N-1 downto 0);
    d001 : in std_logic_vector(N-1 downto 0);
    d010 : in std_logic_vector(N-1 downto 0);
    d011 : in std_logic_vector(N-1 downto 0);
    d100 : in std_logic_vector(N-1 downto 0);
    d101 : in std_logic_vector(N-1 downto 0);
    d110 : in std_logic_vector(N-1 downto 0);
    d111 : in std_logic_vector(N-1 downto 0);
    s : in std_logic_vector(2 downto 0);
    y : out std_logic_vector(N-1 downto 0)
       );
end entity;


architecture behavior of mux8 is
begin
  process(d000, d001, d010, d011, d100, d101, d110, d111, s)
  begin
    case s is
      when "000" => y <= d000;
      when "001" => y <= d001;
      when "010" => y <= d010;
      when "011" => y <= d011;
      when "100" => y <= d100;
      when "101" => y <= d101;
      when "110" => y <= d110;
      when "111" => y <= d111;
      when others => y <= (others => 'X');
    end case;
  end process;
end architecture;
