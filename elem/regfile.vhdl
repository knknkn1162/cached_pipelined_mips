library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use work.tools_pkg.ALL;

entity regfile is
  generic(filename : string := "./assets/reg/dummy.hex");
  port (
    clk, rst, load : in std_logic;
    -- 25:21(read)
    a1 : in std_logic_vector(4 downto 0);
    rd1 : out std_logic_vector(31 downto 0);
    -- 20:16(read)
    a2 : in std_logic_vector(4 downto 0);
    rd2 : out std_logic_vector(31 downto 0);

    wa : in std_logic_vector(4 downto 0);
    wd : in std_logic_vector(31 downto 0);
    we : in std_logic
  );
end entity;

architecture behavior of regfile is

  constant REGSIZE: natural := 32;
  -- $0($zero) ~ $31($ra)
  type ramtype is array(natural range<>) of std_logic_vector(31 downto 0);
begin
  process(clk, rst, load, we, wa, wd, a1, a2)
    file reg : text open READ_MODE is filename;
    variable mem : ramtype(0 to REGSIZE-1);
    variable idx : std_logic_vector(7 downto 0);
    variable lin : line;
    variable ch : character;
  begin
    if rst = '1' then
      -- initialization
      mem := (others => (others => '0'));
    elsif rising_edge(clk) then
      -- for debug
      if load = '1' then
        while not endfile(reg) loop
          readline(reg, lin);
          -- check idx
          for i in 0 to 1 loop
            read(lin, ch);
            idx(7-i*4 downto 4-i*4) := char2bits(ch);
          end loop;
          read(lin, ch); -- space
          for i in 0 to 7 loop
            read(lin, ch);
            mem(to_integer(unsigned(idx)))(31-i*4 downto 28-i*4) := char2bits(ch);
          end loop;
        end loop;
        file_close(reg);
      -- if write enables
      elsif we='1' then
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
