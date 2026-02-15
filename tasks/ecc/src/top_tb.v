`timescale 1ns/1ps

module top_tb;

    // Testbench signals
    reg [63:0] data_in;
    reg [6:0] ecc_in;
    wire [63:0] data_out;
    wire error_detected;
    wire error_corrected;
    
    // Test counters
    integer test_num;
    integer pass_count;
    integer fail_count;
    integer i;
    
    // Variables for test loops
    reg [63:0] original_data;
    reg [6:0] original_ecc;
    
    top dut (
        .data_in(data_in),
        .ecc_in(ecc_in),
        .data_out(data_out),
        .error_detected(error_detected),
        .error_corrected(error_corrected)
    );
    
    // Function to calculate ECC parity bits for 64-bit data
    function [6:0] calculate_ecc;
        input [63:0] data;
        reg [71:0] codeword;
        reg [6:0] parity;
        integer j, k;
        begin
            // Initialize codeword
            codeword = 72'b0;
            
            // Place data bits at non-parity positions
            j = 0;  // data index
            for (k = 3; k < 72; k = k + 1) begin
                // Skip parity positions 
                if (k != 1 && k != 2 && k != 4 && k != 8 && k != 16 && k != 32 && k != 64) begin
                    codeword[k] = data[j];
                    j = j + 1;
                end
            end
            
            // Calculate parity bits
            parity[0] = 1'b0;
            parity[1] = 1'b0;
            parity[2] = 1'b0;
            parity[3] = 1'b0;
            parity[4] = 1'b0;
            parity[5] = 1'b0;
            parity[6] = 1'b0;
            
            for (j = 1; j <= 71; j = j + 1) begin
                if (j & 1)  parity[0] = parity[0] ^ codeword[j];
                if (j & 2)  parity[1] = parity[1] ^ codeword[j];
                if (j & 4)  parity[2] = parity[2] ^ codeword[j];
                if (j & 8)  parity[3] = parity[3] ^ codeword[j];
                if (j & 16) parity[4] = parity[4] ^ codeword[j];
                if (j & 32) parity[5] = parity[5] ^ codeword[j];
                if (j & 64) parity[6] = parity[6] ^ codeword[j];
            end
            
            calculate_ecc = parity;
        end
    endfunction
    
    // Task to run a test case
    task run_test;
        input [63:0] test_data;
        input [6:0] test_ecc;
        input [63:0] expected_data;
        input expected_error_det;
        input expected_error_corr;
        input [200*8:1] test_description;
        begin
            test_num = test_num + 1;
            data_in = test_data;
            ecc_in = test_ecc;
            #10;  // Wait for decoder to finish processing
            
            if (data_out === expected_data && 
                error_detected === expected_error_det && 
                error_corrected === expected_error_corr) begin
                $display("Test %3d PASS: %0s", test_num, test_description);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %3d FAIL: %0s", test_num, test_description);
                $display("  Input Data: 0x%016h, ECC: 0x%02h", test_data, test_ecc);
                $display("  Expected: Data=0x%016h, Err_Det=%b, Err_Corr=%b", 
                         expected_data, expected_error_det, expected_error_corr);
                $display("  Got:      Data=0x%016h, Err_Det=%b, Err_Corr=%b", 
                         data_out, error_detected, error_corrected);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        // Setup waveform dump
        $dumpfile("wave.vcd");
        $dumpvars(0, top_tb);
        
        // Initialize counters
        test_num = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("\n========================================");
        $display("ECC Decoder Testbench");
        $display("========================================\n");
        
        // ? No errors 
        $display("\n--- Test Category 1: No Errors ---");
        
        // Test with all zeros
        data_in = 64'h0000000000000000;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "All zeros, no error");
        
        // Test with all ones
        data_in = 64'hFFFFFFFFFFFFFFFF;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "All ones, no error");
        
        // Test with alternating pattern 0xAA...
        data_in = 64'hAAAAAAAAAAAAAAAA;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Pattern 0xAA, no error");
        
        // Test with alternating pattern 0x55...
        data_in = 64'h5555555555555555;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Pattern 0x55, no error");
        
        // Test with sequential pattern
        data_in = 64'h0123456789ABCDEF;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Sequential pattern, no error");
        
        // Test with random patterns 
        for (i = 0; i < 32; i = i + 1) begin
            data_in = {$random, $random};
            ecc_in = calculate_ecc(data_in);
            run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Random pattern, no error");
        end
        
        // ? Single-bit errors in data 
        $display("\n--- Test Category 2: Single-bit Errors in Data ---");
        
        // Test with a known data pattern and inject errors in each data bit position
        original_data = 64'h123456789ABCDEF0;
        original_ecc = calculate_ecc(original_data);
        
        // Inject errors in each of the 64 data bit positions
        for (i = 0; i < 64; i = i + 1) begin
            run_test(original_data ^ (64'h1 << i), original_ecc, original_data, 1'b1, 1'b1, 
                     "Single-bit error in data");
        end
        
        // ? Single-bit errors in ECC 
        $display("\n--- Test Category 3: Single-bit Errors in ECC ---");
        
        original_data = 64'hFEDCBA9876543210;
        original_ecc = calculate_ecc(original_data);
        
        // Inject errors in each of the 7 ECC bit positions
        for (i = 0; i < 7; i = i + 1) begin
            run_test(original_data, original_ecc ^ (7'h1 << i), original_data, 1'b1, 1'b1, 
                     "Single-bit error in ECC");
        end
        
        // ? Edge cases
        $display("\n--- Test Category 4: Additional Tests ---");
        
        // Test 1: Data with single 1 bit
        data_in = 64'h0000000000000001;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Single bit set, no error");
        
        // Test 2: Same but with error in MSB
        run_test(data_in ^ 64'h8000000000000000, ecc_in, data_in, 1'b1, 1'b1, 
                 "Error in MSB of data");
        
        // Test 3: Checker pattern with no error
        data_in = 64'hA5A5A5A5A5A5A5A5;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Checker pattern, no error");
        
        // Test 4: Same with error in LSB
        run_test(data_in ^ 64'h1, ecc_in, data_in, 1'b1, 1'b1, "Error in LSB of data");
        
        // Test 5: Walking ones pattern
        data_in = 64'h0000000000000001;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Walking ones - bit 0");
        
        data_in = 64'h0000000000000002;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Walking ones - bit 1");
        
        data_in = 64'h0000000000000004;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Walking ones - bit 2");
        
        data_in = 64'h8000000000000000;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in, ecc_in, data_in, 1'b0, 1'b0, "Walking ones - bit 63");
        
        // Test 6: Edge case - all ones with error in middle bit
        data_in = 64'hFFFFFFFFFFFFFFFF;
        ecc_in = calculate_ecc(data_in);
        run_test(data_in ^ 64'h0000000100000000, ecc_in, data_in, 1'b1, 1'b1, 
                 "Error in middle bit of all-ones data");
        
        // ? Display Results

        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total Tests: %d", test_num);
        $display("Passed:      %d", pass_count);
        $display("Failed:      %d", fail_count);
        
        if (fail_count == 0) begin
            $display("\nALL TESTS PASSED!");
        end else begin
            $display("\nSOME TESTS FAILED!");
        end
        $display("========================================\n");
        
        #100;
        $finish;
    end

endmodule