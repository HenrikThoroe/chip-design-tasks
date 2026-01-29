test: 
	verilator -Wno-fatal --cc --binary --timing --build -Wall --trace design.sv testbench.sv -o sim > build.log 2>&1
	./obj_dir/sim

clean:
	rm -rf obj_dir sim build.log