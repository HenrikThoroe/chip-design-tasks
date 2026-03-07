`timescale 1ns/1ps

module RFC_Tree(
  input wire clk,
  input wire reset,
  input wire start_traversal,
  input wire [15:0] alcohol,
  input wire [15:0] sulphates,
  input wire [15:0] fixed_acidity,
  input wire [15:0] citric_acid,
  input wire [15:0] chlorides,
  
  output reg quality_class,
  output reg done
);

localparam TREE_DEPTH = 3;

// We number states from top to bottom and left to right
reg [3:0] current_state;
reg [1:0] current_depth;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
    current_state <= 0;
    current_depth <= 0;
    done <= 0;
  end else begin
    if (start_traversal) begin
      if (current_depth < TREE_DEPTH) begin
        case (current_state)
          0: current_state <= (citric_acid <= 315) ? 1 : 2;
          1: current_state <= (alcohol <= 1215) ? 3 : 4;
          2: current_state <= (alcohol <= 1075) ? 5 : 6;
          3: current_state <= (chlorides <= 25) ? 7 : 8;
          4: current_state <= (sulphates <= 805) ? 9 : 10;
          5: current_state <= (fixed_acidity <= 1465) ? 11 : 12;
          6: current_state <= (alcohol <= 1155) ? 13 : 14;
        endcase
        current_depth <= current_depth + 1;
      end else begin
        // see Tree.png for classes
        if (current_state == 14 || current_state == 12 || current_state == 10 || current_state == 7) quality_class <= 1;
        else quality_class <= 0;
        done <= 1;
      end
    end
  end
end 

endmodule
