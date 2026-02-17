import common_pkg::*;

module data_memory (clk, rst, w_data, r_data, address, ctrl_mem_w, ctrl_mem_r);

  input                                     clk;
  input                                     rst;
  input                                     ctrl_mem_w;
  input                                     ctrl_mem_r;
  input [RISC_V_DATA_WIDTH - 1 : 0]         w_data;
  input [DATA_MEMORY_ADDRESS_WIDTH - 1 : 0] address;

  output reg [RISC_V_DATA_WIDTH - 1 : 0]    r_data;


  reg [RISC_V_DATA_WIDTH - 1 : 0]  rom_memory  [DATA_MEMORY_ROM_DEPTH];
  reg [RISC_V_DATA_WIDTH - 1 : 0]  ram_memory  [DATA_MEMORY_RAM_DEPTH];


  integer i;

  initial begin
    $readmemh(  "data_memory.mem",
              rom_memory, 
              DATA_MEMORY_ADDRESS_WIDTH'('h0),
              DATA_MEMORY_ADDRESS_WIDTH'('hFF)); // load ROM memory


    for (i = 0; i < DATA_MEMORY_RAM_DEPTH; i = i + 1) ram_memory[i] = RISC_V_DATA_WIDTH'('b0); // initialize RAM
  end


  always @(*) begin
    // --------------------reading ROM and RAM -----------------------
    if (ctrl_mem_r) begin
      if (address < DATA_MEMORY_ROM_DEPTH) begin
        r_data = rom_memory[address];
      end else begin
        r_data = ram_memory[address - DATA_MEMORY_ROM_DEPTH];
      end
    end else begin
      r_data = RISC_V_DATA_WIDTH'('b0);
    end
    // -------------------------------------------
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // --------------set RAM entries to zero -----------------------------
      for (i = 0; i < DATA_MEMORY_RAM_DEPTH; i = i + 1) begin
        ram_memory[i] <= RISC_V_DATA_WIDTH'('b0);
      end
      // -------------------------------------------
    end else begin
      // ---------------write data to RAM if write signal is set and address is a valid RAM address----------------------------
      if (ctrl_mem_w && (address >= DATA_MEMORY_ROM_DEPTH)) begin
        ram_memory[address - DATA_MEMORY_ROM_DEPTH] <= w_data;
      end
      // -------------------------------------------
    end
  end

endmodule

