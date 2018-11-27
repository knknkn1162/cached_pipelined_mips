F=dummy
VHDL=vhdl
MEM=dummy
DIR=./

cache_decoder: cache_pkg
	make aer F=cache_decoder DIR=elem/

cache_pkg:
	make aer F=cache_pkg DIR=elem/

data_cache: tools_pkg
	make aer F=data_cache DIR=elem/
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
tools_pkg:
	make aer F=tools_pkg
type_pkg:
	make a F=type_pkg
aer:
	ghdl -a ${DIR}$(F).${VHDL} ${DIR}${F}_tb.$(VHDL)
	make er F=${F}
clean:
	rm -f work-obj93.cf *.o *.vcd
open:
	open out.vcd
e:
	ghdl -e ${F}_tb
r:
	ghdl -r ${F}_tb --vcd=out.vcd
a:
	ghdl -a ${F}.${VHDL}
er:
	make e
	make r
