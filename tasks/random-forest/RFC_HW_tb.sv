`timescale 1ns / 1ps

module RFC_HW_tb;
  reg clk;
  reg reset;
  reg start_traversal;
  reg signed [31:0] features[0:10];
  wire prediction;
  wire done;
  reg expected_pred;

  RFC_Tree dut (
      .clk(clk),
      .reset(reset),
      .start_traversal(start_traversal),
      .features(features),
      .prediction(prediction),
      .done(done)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("RFC_HW_tb.vcd");
    $dumpvars(0, RFC_HW_tb);


    // Run test cases
    reset_dut();
    run_test_case(1);
    reset_dut();
    run_test_case(2);
    reset_dut();
    run_test_case(3);

    // End simulation
    #100;
    $display("Testbench Complete");
    $finish;
  end

  task run_test_case;
    input integer case_num;
    begin
      case (case_num)
        1: load_test_case_1();
        2: load_test_case_2();
        3: load_test_case_3();
        default: $display("Invalid test case number");
      endcase
      #10;
      $display("%0t ns\tStarting tree traversal for Test Case %0d", $time, case_num);
      start_traversal = 1;
      #100;
      start_traversal = 0;
      wait (done == 1);
      #10;
      if (prediction === expected_pred) begin
        $display("%0t ns\tTest Case %0d Passed: Prediction = %b", $time, case_num, prediction);
      end else begin
        $display("%0t ns\tTest Case %0d Failed: Expected = %b, Got = %b", $time, case_num,
                 expected_pred, prediction);
      end
    end
  endtask

  task reset_dut;
    integer i;
    begin
      reset = 0;
      start_traversal = 0;
      #10;
      reset = 1;
      #10;
      for (i = 0; i < 11; i = i + 1) begin
        features[i] = 32'h00000000;
      end
    end
  endtask

  task load_test_case_1;
    begin
      features[0]   <= 32'shffffa470;
      features[1]   <= 32'sh00002dd5;
      features[2]   <= 32'shffff04f0;
      features[3]   <= 32'shfffff7e9;
      features[4]   <= 32'sh00008f49;
      features[5]   <= 32'shffffd281;
      features[6]   <= 32'shfffffc7e;
      features[7]   <= 32'sh00002f40;
      features[8]   <= 32'shffff8a82;
      features[9]   <= 32'sh00000276;
      features[10]  <= 32'shffff39c7;
      expected_pred <= 1'b1;
    end
  endtask

  task load_test_case_2;
    begin
      features[0]   <= 32'shffffb31d;
      features[1]   <= 32'shffffd837;
      features[2]   <= 32'shffff7b15;
      features[3]   <= 32'shffff5549;
      features[4]   <= 32'shffffe22a;
      features[5]   <= 32'sh00007d71;
      features[6]   <= 32'sh0001b074;
      features[7]   <= 32'shffff9a65;
      features[8]   <= 32'sh0000829f;
      features[9]   <= 32'shfffef334;
      features[10]  <= 32'shffff21cb;
      expected_pred <= 1'b0;
    end
  endtask

  task load_test_case_3;
    begin
      features[0]   <= 32'sh00015ca4;
      features[1]   <= 32'sh0000cace;
      features[2]   <= 32'shffffbcb8;
      features[3]   <= 32'sh00001c0c;
      features[4]   <= 32'sh0000696a;
      features[5]   <= 32'sh00001bc2;
      features[6]   <= 32'shffff9f12;
      features[7]   <= 32'sh0001edd4;
      features[8]   <= 32'shffffccac;
      features[9]   <= 32'sh0001e4b4;
      features[10]  <= 32'shffff81bb;
      expected_pred <= 1;
    end
  endtask


  initial begin
    #50000;  // 50 microseconds timeout
    $display("\nERROR: Simulation timeout!");
    $finish;
  end

endmodule
