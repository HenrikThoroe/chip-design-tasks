IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave
RTL_SRC = RFC_HW.sv
TB_SRC = RFC_HW_tb.sv
TB_OUT = RFC_HW_tb
VCD_FILE = RFC_HW_tb.vcd

.PHONY: all
all: compile simulate

.PHONY: compile
compile:
	$(IVERILOG) -g 2012 -o $(TB_OUT) $(RTL_SRC) $(TB_SRC)

.PHONY: simulate
simulate: compile
	$(VVP) $(TB_OUT)

.PHONY: wave
wave:
	@if [ -f $(VCD_FILE) ]; then \
		$(GTKWAVE) $(VCD_FILE) &; \
	else \
		echo "Error: VCD file not found. Run 'make simulate' first."; \
	fi

.PHONY: clean
clean:
	rm -f $(TB_OUT) $(VCD_FILE)

