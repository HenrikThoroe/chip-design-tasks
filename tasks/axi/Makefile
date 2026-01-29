test: 
	verilator -Wno-fatal --cc --binary --timing --build -Wall --trace axi_lite.v axi_lite_tb.sv -o sim > build.log 2>&1
	./obj_dir/sim

clean:
	rm -rf obj_dir sim build.log dump.vcd
