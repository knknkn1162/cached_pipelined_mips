F=dummy
VHDL=vhdl
MEM=dummy
DIR=./
DEBUG=
CONTROLLER_LIST=mem_idcache alu load flopen decode shift forwarding
CONTROLLERS=$(addsuffix _controller, ${CONTROLLER_LIST})

forwarding_addi_add: mips
	make tb F=forwarding_addi_add
tb:
	make a F=tests/${F}_tb
	make er F=${F}

mips: type_pkg cache_pkg datapath mem ${CONTROLLERS}
	make a F=mips
datapath: flopr_en instr_decoder mux2 mux4 alu regfile mem_idcache_controller mem data_cache instr_cache regw_buffer
	make a F=datapath

forwarding_controller: type_pkg
	make a F=forwarding_controller DIR=controller/
instr_decoder: type_pkg slt2 sgnext
	make a F=instr_decoder DIR=component/
load_controller: bflopr
	make aer F=load_controller DIR=controller/
regwe_controller: type_pkg
	make a F=regwe_controller DIR=controller/
decode_controller: type_pkg
	make a F=decode_controller DIR=controller/
flopen_controller: state_pkg debug_pkg
	make a F=flopen_controller DIR=controller/
shift_controller: type_pkg flopr_en
	make a F=shift_controller DIR=controller/

cache_decoder: cache_pkg
	make aer F=cache_decoder DIR=cache/
mem_idcache_controller: mem_cache_controller flopr_en
	make aer F=mem_idcache_controller DIR=controller/
mem_cache_controller:
	make aer F=mem_cache_controller DIR=controller/
mem: tools_pkg cache_pkg
	make aer F=mem DIR=general/
regfile: type_pkg
	make aer F=regfile DIR=general/

regw_buffer: type_pkg shift2_register_load regw_buffer_search
	make aer F=regw_buffer DIR=component/
regw_buffer_search: type_pkg
	make a F=regw_buffer_search DIR=general/
shift2_register_load: flopr_en mux2
	make aer F=shift2_register_load DIR=component/

cache_pkg:
	make a F=cache_pkg DIR=pkg/
data_cache: cache_pkg tools_pkg cache_decoder mux8 mux2 cache_controller
	make aer F=data_cache DIR=cache/
instr_cache: cache_pkg tools_pkg cache_decoder mux8 cache_controller
	make aer F=instr_cache DIR=cache/
cache_controller: cache_pkg
	make aer F=cache_controller DIR=controller/
alu_controller: type_pkg
	make a F=alu_controller DIR=controller/
alu: type_pkg
	make aer F=alu DIR=general/
flopr_en:
	make aer F=flopr_en DIR=general/
flopr:
	make aer F=flopr DIR=general/
bflopr:
	make aer F=bflopr DIR=general/
sgnext:
	make aer F=sgnext DIR=general/
slt2:
	make aer F=slt2 DIR=general/
mux2:
	make aer F=mux2 DIR=general/
mux4:
	make aer F=mux4 DIR=general/
mux8:
	make aer F=mux8 DIR=general/
debug_pkg: state_pkg
	make a F=debug_pkg DIR=pkg/
tools_pkg:
	make aer F=tools_pkg DIR=pkg/
type_pkg:
	make a F=type_pkg DIR=pkg/
state_pkg:
	make a F=state_pkg DIR=pkg/
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
