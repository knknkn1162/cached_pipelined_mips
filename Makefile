F=dummy
VHDL=vhdl
MEM=dummy
DIR=./

alu: type_pkg
	make aer F=alu DIR=elem/
flopr_en:
	make aer F=flopr_en DIR=elem/
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
