F=dummy
VHDL=vhdl
MEM=dummy
DIR=./
DEBUG=

cache_decoder: cache_pkg
	make aer F=cache_decoder DIR=cache/
mem: tools_pkg cache_pkg
	make aer F=mem DIR=elem/

cache_pkg:
	make a F=cache_pkg DIR=cache/
data_cache: tools_pkg cache_decoder mux8
	make aer F=data_cache DIR=cache/
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
	ghdl -a ${DIR}${F}.${VHDL}
er:
	make e
	make r
