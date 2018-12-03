F=dummy
VHDL=vhdl
MEM=dummy
DIR=./
DEBUG=

cache_decoder: cache_pkg
	make aer F=cache_decoder DIR=cache/
mem_cache: cache_pkg mem data_cache instr_cache mem_idcache_controller
	make a F=mem_cache DIR=toplevel/
mem_idcache_controller: mem_cache_controller flopr_en
	make aer F=mem_idcache_controller DIR=cache/
mem_cache_controller:
	make aer F=mem_cache_controller DIR=cache/
mem: flopr8_en tools_pkg cache_pkg
	make aer F=mem DIR=elem/
regfile: type_pkg
	make aer F=regfile DIR=elem/

cache_pkg:
	make a F=cache_pkg DIR=cache/
data_cache: cache_pkg tools_pkg cache_decoder mux8 mux2 cache_controller
	make aer F=data_cache DIR=cache/
instr_cache: cache_pkg tools_pkg cache_decoder mux8 cache_controller
	make aer F=instr_cache DIR=cache/
cache_controller: cache_pkg
	make aer F=cache_controller DIR=cache/
alu: type_pkg
	make aer F=alu DIR=elem/
flopr_en:
	make aer F=flopr_en DIR=elem/
sgnext:
	make aer F=sgnext DIR=elem/
slt2:
	make aer F=slt2 DIR=elem/
mux2:
	make aer F=mux2 DIR=elem/
mux8:
	make aer F=mux8 DIR=cache/
tools_pkg:
	make aer F=tools_pkg
type_pkg:
	make a F=type_pkg
aer:
	ghdl -a ${DEBUG} ${DIR}$(F).${VHDL} ${DIR}${F}_tb.$(VHDL)
	make er F=${F} DEBUG=${DEBUG}
debug:
	make aer DEBUG=--ieee=synopsys
clean:
	rm -f work-obj93.cf *.o *.vcd
open:
	open out.vcd
e:
	ghdl -e ${DEBUG} ${F}_tb
r:
	ghdl -r ${F}_tb --vcd=out.vcd
a:
	ghdl -a ${DEBUG} ${DIR}${F}.${VHDL}
er:
	make e
	make r
