module RFC_Tree (
    input wire clk,
    input wire reset,
    input wire start_traversal,
    input wire signed [31:0] features[0:10],

    output reg prediction,
    output reg done
);

  wire tree_0_pred, tree_0_done;
  wire tree_1_pred, tree_1_done;
  wire tree_2_pred, tree_2_done;
  wire tree_3_pred, tree_3_done;

  tree_0 t0 (
      .clk(clk),
      .reset(reset),
      .start_traversal(start_traversal),
      .features(features),
      .prediction(tree_0_pred),
      .done(tree_0_done)
  );
  tree_1 t1 (
      .clk(clk),
      .reset(reset),
      .start_traversal(start_traversal),
      .features(features),
      .prediction(tree_1_pred),
      .done(tree_1_done)
  );
  tree_2 t2 (
      .clk(clk),
      .reset(reset),
      .start_traversal(start_traversal),
      .features(features),
      .prediction(tree_2_pred),
      .done(tree_2_done)
  );
  tree_3 t3 (
      .clk(clk),
      .reset(reset),
      .start_traversal(start_traversal),
      .features(features),
      .prediction(tree_3_pred),
      .done(tree_3_done)
  );

  always @(posedge clk or negedge reset) begin
    if (!reset) begin
      prediction <= 0;
      done <= 0;
    end else if (tree_0_done && tree_1_done && tree_2_done && tree_3_done) begin
      prediction <= ((tree_0_pred + tree_1_pred + tree_2_pred + tree_3_pred) >= 2) ? 1 : 0;
      done <= 1;
    end else begin
      done <= 0;
    end
  end

endmodule

module tree_0 (
    input wire clk,
    input wire reset,
    input wire start_traversal,
    input wire signed [31:0] features[0:10],
    output reg prediction,
    output reg done
);

  reg [4:0] current_node;
  always @(posedge clk or negedge reset) begin
    if (!reset) begin
      current_node <= 5'd0;
      done <= 1'b0;
      prediction <= 1'b0;
    end else begin
      if (start_traversal && !done) begin
        case (current_node)

          0: begin
            if (features[9] <= 32'shffff825e) begin
              current_node <= 1;
            end else begin
              current_node <= 8;
            end
          end
          1: begin
            if (features[7] <= 32'shffff7326) begin
              current_node <= 2;
            end else begin
              current_node <= 5;
            end
          end
          2: begin
            if (features[1] <= 32'shfffff4c1) begin
              current_node <= 3;
            end else begin
              current_node <= 4;
            end
          end
          3: begin
            prediction <= 1;
            done <= 1;
          end
          4: begin
            prediction <= 0;
            done <= 1;
          end
          5: begin
            if (features[3] <= 32'sh00077c56) begin
              current_node <= 6;
            end else begin
              current_node <= 7;
            end
          end
          6: begin
            prediction <= 0;
            done <= 1;
          end
          7: begin
            prediction <= 1;
            done <= 1;
          end
          8: begin
            if (features[6] <= 32'sh0001bc21) begin
              current_node <= 9;
            end else begin
              current_node <= 12;
            end
          end
          9: begin
            if (features[7] <= 32'shffff6a5b) begin
              current_node <= 10;
            end else begin
              current_node <= 11;
            end
          end
          10: begin
            prediction <= 1;
            done <= 1;
          end
          11: begin
            prediction <= 1;
            done <= 1;
          end
          12: begin
            if (features[3] <= 32'shffff3a2e) begin
              current_node <= 13;
            end else begin
              current_node <= 14;
            end
          end
          13: begin
            prediction <= 1;
            done <= 1;
          end
          14: begin
            prediction <= 0;
            done <= 1;
          end
        endcase
      end
    end
  end
endmodule


module tree_1 (
    input wire clk,
    input wire reset,
    input wire start_traversal,
    input wire signed [31:0] features[0:10],
    output reg prediction,
    output reg done
);

  reg [4:0] current_node;
  always @(posedge clk or negedge reset) begin
    if (!reset) begin
      current_node <= 5'd0;
      done <= 1'b0;
      prediction <= 1'b0;
    end else begin
      if (start_traversal && !done) begin
        case (current_node)

          0: begin
            if (features[6] <= 32'sh0000bb39) begin
              current_node <= 1;
            end else begin
              current_node <= 8;
            end
          end
          1: begin
            if (features[10] <= 32'sh0000c585) begin
              current_node <= 2;
            end else begin
              current_node <= 5;
            end
          end
          2: begin
            if (features[10] <= 32'shffff75bd) begin
              current_node <= 3;
            end else begin
              current_node <= 4;
            end
          end
          3: begin
            prediction <= 0;
            done <= 1;
          end
          4: begin
            prediction <= 1;
            done <= 1;
          end
          5: begin
            if (features[2] <= 32'shffffd069) begin
              current_node <= 6;
            end else begin
              current_node <= 7;
            end
          end
          6: begin
            prediction <= 1;
            done <= 1;
          end
          7: begin
            prediction <= 1;
            done <= 1;
          end
          8: begin
            if (features[7] <= 32'shfffe2db0) begin
              current_node <= 9;
            end else begin
              current_node <= 10;
            end
          end
          9: begin
            prediction <= 1;
            done <= 1;
          end
          10: begin
            if (features[6] <= 32'sh00019534) begin
              current_node <= 11;
            end else begin
              current_node <= 12;
            end
          end
          11: begin
            prediction <= 0;
            done <= 1;
          end
          12: begin
            prediction <= 0;
            done <= 1;
          end
        endcase
      end
    end
  end
endmodule


module tree_2 (
    input wire clk,
    input wire reset,
    input wire start_traversal,
    input wire signed [31:0] features[0:10],
    output reg prediction,
    output reg done
);

  reg [4:0] current_node;
  always @(posedge clk or negedge reset) begin
    if (!reset) begin
      current_node <= 5'd0;
      done <= 1'b0;
      prediction <= 1'b0;
    end else begin
      if (start_traversal && !done) begin
        case (current_node)

          0: begin
            if (features[9] <= 32'shffffdcca) begin
              current_node <= 1;
            end else begin
              current_node <= 8;
            end
          end
          1: begin
            if (features[6] <= 32'sh0000944c) begin
              current_node <= 2;
            end else begin
              current_node <= 5;
            end
          end
          2: begin
            if (features[7] <= 32'shffff2ecf) begin
              current_node <= 3;
            end else begin
              current_node <= 4;
            end
          end
          3: begin
            prediction <= 1;
            done <= 1;
          end
          4: begin
            prediction <= 0;
            done <= 1;
          end
          5: begin
            if (features[1] <= 32'shffff7b75) begin
              current_node <= 6;
            end else begin
              current_node <= 7;
            end
          end
          6: begin
            prediction <= 1;
            done <= 1;
          end
          7: begin
            prediction <= 0;
            done <= 1;
          end
          8: begin
            if (features[6] <= 32'sh00007528) begin
              current_node <= 9;
            end else begin
              current_node <= 12;
            end
          end
          9: begin
            if (features[1] <= 32'sh00001bfe) begin
              current_node <= 10;
            end else begin
              current_node <= 11;
            end
          end
          10: begin
            prediction <= 1;
            done <= 1;
          end
          11: begin
            prediction <= 1;
            done <= 1;
          end
          12: begin
            if (features[0] <= 32'shfffe68f6) begin
              current_node <= 13;
            end else begin
              current_node <= 14;
            end
          end
          13: begin
            prediction <= 1;
            done <= 1;
          end
          14: begin
            prediction <= 0;
            done <= 1;
          end
        endcase
      end
    end
  end
endmodule


module tree_3 (
    input wire clk,
    input wire reset,
    input wire start_traversal,
    input wire signed [31:0] features[0:10],
    output reg prediction,
    output reg done
);

  reg [4:0] current_node;
  always @(posedge clk or negedge reset) begin
    if (!reset) begin
      current_node <= 5'd0;
      done <= 1'b0;
      prediction <= 1'b0;
    end else begin
      if (start_traversal && !done) begin
        case (current_node)

          0: begin
            if (features[2] <= 32'sh00001f2c) begin
              current_node <= 1;
            end else begin
              current_node <= 8;
            end
          end
          1: begin
            if (features[1] <= 32'sh00005513) begin
              current_node <= 2;
            end else begin
              current_node <= 5;
            end
          end
          2: begin
            if (features[8] <= 32'shfffefde8) begin
              current_node <= 3;
            end else begin
              current_node <= 4;
            end
          end
          3: begin
            prediction <= 0;
            done <= 1;
          end
          4: begin
            prediction <= 1;
            done <= 1;
          end
          5: begin
            if (features[10] <= 32'shffffd5ad) begin
              current_node <= 6;
            end else begin
              current_node <= 7;
            end
          end
          6: begin
            prediction <= 0;
            done <= 1;
          end
          7: begin
            prediction <= 1;
            done <= 1;
          end
          8: begin
            if (features[1] <= 32'shffff45f2) begin
              current_node <= 9;
            end else begin
              current_node <= 12;
            end
          end
          9: begin
            if (features[6] <= 32'sh000110dc) begin
              current_node <= 10;
            end else begin
              current_node <= 11;
            end
          end
          10: begin
            prediction <= 1;
            done <= 1;
          end
          11: begin
            prediction <= 0;
            done <= 1;
          end
          12: begin
            if (features[9] <= 32'shffffcdb8) begin
              current_node <= 13;
            end else begin
              current_node <= 14;
            end
          end
          13: begin
            prediction <= 0;
            done <= 1;
          end
          14: begin
            prediction <= 1;
            done <= 1;
          end
        endcase
      end
    end
  end
endmodule
