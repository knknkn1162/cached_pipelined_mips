library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

entity cache_decoder_tb is
end entity;


architecture testbench of cache_decoder_tb is
  component cache_decoder
    port (
      addr : in std_logic_vector(31 downto 0);
      tag : out std_logic_vector(CONST_CACHE_TAG_SIZE-1 downto 0);
      index : out cache_index_vector;
      offset : out cache_offset_vector
    );
  end component;

  signal addr : std_logic_vector(31 downto 0);
  signal tag : std_logic_vector(19 downto 0);
  signal index : std_logic_vector(6 downto 0);
  signal offset : std_logic_vector(2 downto 0);

begin
  uut : cache_decoder port map (
    addr => addr,
    tag => tag,
    index => index,
    offset => offset
  );

  stim_proc : process
  begin
    wait for 20 ns;
    addr <= X"12345678"; wait for 10 ns;
    -- X"678"=b"/0110_011/1_10/00"
    assert tag = X"12345"; assert index = "0110011"; assert offset = "110";

    assert false report "end of test" severity note;
    wait;
  end process;


end architecture;
