library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.type_pkg.ALL;

entity regfile is
  port (
    clk, rst : in std_logic;
    -- 25:21(read)
    a1 : in reg_vector;
    rd1 : out std_logic_vector(31 downto 0);
    -- 20:16(read)
    a2 : in reg_vector;
    rd2 : out std_logic_vector(31 downto 0);
    wa : in reg_vector;
    wd : in std_logic_vector(31 downto 0);
    we : in std_logic
  );
end entity;

architecture behavior of regfile is

  constant REGSIZE: natural := 32;
  -- $0($zero) ~ $31($ra)
  type ramtype is array(natural range<>) of std_logic_vector(31 downto 0);
begin
  process(clk, rst, we, wa, wd, a1, a2)
    variable mem : ramtype(0 to REGSIZE-1);
  begin
    if rst = '1' then
      -- initialization
      mem := (others => (others => '0'));
    elsif rising_edge(clk) then
      -- if write enables
      if we='1' then
        -- avoid $zero register
        if (not is_X(wa)) and wa/="00000" then
          mem(to_integer(unsigned(wa))) := wd;
        end if;
      end if;
    end if;
    -- read
    if not is_X(a1) then
      rd1 <= mem(to_integer(unsigned(a1)));
    end if;
    if not is_X(a2) then
      rd2 <= mem(to_integer(unsigned(a2)));
    end if;
  end process;
end architecture;
