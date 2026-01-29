import common_pkg::*;

module control_unit (
    opcode,
    ctrl_ALU_op,
    ctrl_ALU_src,
    ctrl_reg_w,
    ctrl_mem_w,
    ctrl_mem_r,
    ctrl_mem_to_reg,
    ctrl_branch
);

  input opcode_t opcode;

  output  reg [1:0] ctrl_ALU_op;
  output reg ctrl_ALU_src;
  output reg ctrl_reg_w;
  output reg ctrl_mem_w;
  output reg ctrl_mem_r;
  output reg ctrl_mem_to_reg;
  output reg ctrl_branch;

  //TODO: set the correct control signals in each state
  always @(*) begin
    case (opcode)
      LOAD: begin
        ctrl_ALU_op     <= 2'b00;  // Add for address calculation
        ctrl_ALU_src    <= 1'b1;  // Use immediate offset
        ctrl_reg_w      <= 1'b1;  // Write to register
        ctrl_mem_w      <= 1'b0;  // No memory write
        ctrl_mem_r      <= 1'b1;  // Read from memory
        ctrl_mem_to_reg <= 1'b1;  // Write memory data to register
        ctrl_branch     <= 1'b0;  // Not a branch
      end

      STORE: begin
        ctrl_ALU_op     <= 2'b00;  // Add for address calculation
        ctrl_ALU_src    <= 1'b1;  // Use immediate offset
        ctrl_reg_w      <= 1'b0;  // No register write
        ctrl_mem_w      <= 1'b1;  // Write to memory
        ctrl_mem_r      <= 1'b0;  // No memory read
        ctrl_mem_to_reg <= 1'b0;  // Don't care (no reg write)
        ctrl_branch     <= 1'b0;  // Not a branch
      end

      ARITH: begin
        ctrl_ALU_op     <= 2'b10;  // Use funct3/funct7 for ALU operation
        ctrl_ALU_src    <= 1'b0;  // Use register rs2
        ctrl_reg_w      <= 1'b1;  // Write to register
        ctrl_mem_w      <= 1'b0;  // No memory write
        ctrl_mem_r      <= 1'b0;  // No memory read
        ctrl_mem_to_reg <= 1'b0;  // Write ALU result to register
        ctrl_branch     <= 1'b0;  // Not a branch
      end

      BRANCH: begin
        ctrl_ALU_op     <= 2'b01;  // Subtract for comparison
        ctrl_ALU_src    <= 1'b0;  // Use register rs2
        ctrl_reg_w      <= 1'b0;  // No register write
        ctrl_mem_w      <= 1'b0;  // No memory write
        ctrl_mem_r      <= 1'b0;  // No memory read
        ctrl_mem_to_reg <= 1'b0;  // Don't care (no reg write)
        ctrl_branch     <= 1'b1;  // This is a branch
      end


      default: begin
        ctrl_ALU_op     <= 2'b00;
        ctrl_ALU_src    <= 1'b0;
        ctrl_reg_w      <= 1'b0;
        ctrl_mem_w      <= 1'b0;
        ctrl_mem_r      <= 1'b0;
        ctrl_mem_to_reg <= 1'b0;
        ctrl_branch     <= 1'b0;
      end

    endcase

  end


endmodule
