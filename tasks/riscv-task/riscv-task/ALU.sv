import common_pkg::*;

module ALU (data_in_A, data_in_B, data_out, zero, ALU_ctrl);

  input  signed [RISC_V_DATA_WIDTH - 1 : 0]  data_in_A;
  input  signed [RISC_V_DATA_WIDTH - 1 : 0]  data_in_B;
  input         ALU_ctrl_t                   ALU_ctrl;

  output signed [RISC_V_DATA_WIDTH - 1 : 0]  data_out;
  output                                     zero;

  reg signed [RISC_V_DATA_WIDTH - 1 : 0] result;


  assign data_out = result;

  // -------------------zero flag---------------------
  assign zero = (result == 0);
  // -------------------------------------------

  always @(*)
    begin
      case (ALU_ctrl)
        // -------------------------------------------
        AND: result = data_in_A & data_in_B;
        OR:  result = data_in_A | data_in_B;
        ADD: result = data_in_A + data_in_B;
        SUB: result = data_in_A - data_in_B;
        // -------------------------------------------
        default: result = RISC_V_DATA_WIDTH'('b0);
      endcase
    end

endmodule



