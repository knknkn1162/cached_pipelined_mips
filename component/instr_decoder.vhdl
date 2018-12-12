library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.type_pkg.ALL;

entity instr_decoder is
  port (
    instr : in std_logic_vector(31 downto 0);
    opcode : out opcode_vector;
    rs, rt, rd : out reg_vector;
    immext : out std_logic_vector(31 downto 0);
    brplus: out std_logic_vector(31 downto 0);
    shamt : out shamt_vector;
    funct : out funct_vector
  );
end entity;

architecture behavior of instr_decoder is
  component sgnext
    port (
      a : in std_logic_vector(15 downto 0);
      y : out std_logic_vector(31 downto 0)
        );
  end component;

  signal imm : imm_vector;
  signal immext0 : std_logic_vector(31 downto 0);
begin
  opcode <= instr(31 downto 26);
  rs <= instr(25 downto 21);
  rt <= instr(20 downto 16);
  imm <= instr(15 downto 0);

  sgnext0 : sgnext port map (
    a => imm,
    y => immext0
  );
  immext <= immext0;

  rd <= instr(15 downto 11);
  shamt <= instr(10 downto 6);
  funct <= instr(5 downto 0);

  brplus <= immext0(29 downto 0) & "00";
end architecture;
