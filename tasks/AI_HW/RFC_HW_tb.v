`timescale 1ns/1ps

module RFC_HW_tb;
  reg clk;
  reg reset;
  reg start_traversal = 0;
  reg [15:0] alcohol = 0;
  reg [15:0] sulphates = 0;
  reg [15:0] fixed_acidity = 0;
  reg [15:0] citric_acid = 0;
  reg [15:0] chlorides = 0;

  wire quality_class;
  wire done;

  RFC_Tree dut (
    .clk(clk),
    .reset(reset),
    .start_traversal(start_traversal),
    .alcohol(alcohol),
    .sulphates(sulphates),
    .fixed_acidity(fixed_acidity),
    .citric_acid(citric_acid),
    .chlorides(chlorides),
    .quality_class(quality_class),
    .done(done)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset = 0;
    #10;
    reset = 1;
    #10;

    // Test vectors taken from winequality-red.csv:
    // line 2 -> fixed_acidity=7.4, citric_acid=0, chlorides=0.076, sulphates=0.56, alcohol=9.4
    apply_vector(16'd9400, 16'd560, 16'd7400, 16'd0,   16'd76);
    // line 5 -> fixed_acidity=11.2, citric_acid=0.56, chlorides=0.075, sulphates=0.58, alcohol=9.8
    apply_vector(16'd9800, 16'd580, 16'd11200,16'd560, 16'd75);
    // line 9 -> fixed_acidity=7.3, citric_acid=0, chlorides=0.065, sulphates=0.47, alcohol=10.0
    apply_vector(16'd10000,16'd470, 16'd7300, 16'd0,   16'd65);

    #50;
    $finish;
  end

  task apply_vector(
    input [15:0] a,
    input [15:0] s,
    input [15:0] fa,
    input [15:0] c,
    input [15:0] chl
  );
    integer i;
    begin
      $display("Applying vector: alcohol = %0d sulphates = %0d fixed_acidity = %0d citric_acid = %0d chlorides = %0d", a, s, fa, c, chl);

      alcohol = a; sulphates = s; fixed_acidity = fa; citric_acid = c; chlorides = chl;
      start_traversal = 1;

      while (!done) #10;

      start_traversal = 0;

      $display("Result: done = %b quality = %b", done, quality_class);

      reset = 0;
      #10;
      reset = 1;
      #10;
    end
  endtask

endmodule
