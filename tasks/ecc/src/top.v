module top (
    input  [63:0] data_in,        // 64-bit data input
    input  [6:0]  ecc_in,         // 7-bit ECC parity input
    output reg [63:0] data_out,   // 64-bit corrected data output
    output reg error_detected,    // 1 if error is detected
    output reg error_corrected    // 1 if error is corrected
);
    reg [6:0] syndrome;           //  syndrome
    reg [71:0] received_word;     // combined ecc-data word (1-indexed)
    reg [71:0] corrected_word;    // Corrected word
    integer i;                    // Loop index
    integer data_idx;             // Loop index for data word
    
    always @* begin
        // * Inline the ECC into the data word for reconstruction

        // Hamming code positions: parity bits at powers of 2 
        // Position 0 is not used (positions are 1-indexed)
        
        received_word[0] = 1'b0;  // Position 0 unused
        
        // Set parity bits at power of 2 positions
        received_word[1]  = ecc_in[0];   
        received_word[2]  = ecc_in[1];   
        received_word[4]  = ecc_in[2];   
        received_word[8]  = ecc_in[3];   
        received_word[16] = ecc_in[4];   
        received_word[32] = ecc_in[5];   
        received_word[64] = ecc_in[6];   
        
        // Fill data bits at non-parity positions 
        data_idx = 0;
        for (i = 1; i <= 71; i = i + 1) begin
            // Check if position is not a parity position and insert data
            if ((i & (i - 1)) != 0) begin
                received_word[i] = data_in[data_idx];
                data_idx = data_idx + 1;
            end
        end
        
        // * Calculate syndrome

        // Each syndrome bit checks parity for specific positions
        // syndrome[i]: check positions where the i'th bit of the received word is 1
        // -> i = 0: check pos 1, 3, 5, 7, 9, 11, ...
        // -> i = 1: check pos 2, 3, 6, 7, 10, 11, ...
        // -> i = 2: check pos 4-7, 12-15, 20-23, ...
        // -> i = 3: check pos 8-15, 24-31, 48-63
        // -> i = 4: check pos 16-31, 48-63, ...
        // -> i = 5: check pos 32-63, ...
        // -> i = 6: check pos 64-71, ...
        
        syndrome = 7'b0000000;
        
        for (i = 1; i <= 71; i = i + 1) begin
            if (i & 1)  syndrome[0] = syndrome[0] ^ received_word[i];
            if (i & 2)  syndrome[1] = syndrome[1] ^ received_word[i];
            if (i & 4)  syndrome[2] = syndrome[2] ^ received_word[i];
            if (i & 8)  syndrome[3] = syndrome[3] ^ received_word[i];
            if (i & 16) syndrome[4] = syndrome[4] ^ received_word[i];
            if (i & 32) syndrome[5] = syndrome[5] ^ received_word[i];
            if (i & 64) syndrome[6] = syndrome[6] ^ received_word[i];
        end
        
        // * Error correction & Error detection signaling

        // If syndrome is zero, bypass correction logic
        if (syndrome == 7'b0000000) begin
            // No error detected -> clear error signals
            error_detected = 1'b0;
            error_corrected = 1'b0;

            // No error -> pass through original data
            data_out = data_in;
        end else begin
            // Error detected -> set error signals
            // Because we do not have to differentiate between correcting single 
            // bit errors and detecting two bit errors, we can set both signals
            // when any error is detected. 
            // Correction / handling of multiple bit errors is undefined behaviour.
            error_detected = 1'b1;
            error_corrected = 1'b1;  

            // Error detected at position indicated by syndrome value
            // Correct the error by flipping the bit at that position
            // We can use the syndrome directly, because the received word is 
            // 1-indexed and the syndrome value corresponds to the position of the error.
            corrected_word = received_word;
            corrected_word[syndrome] = ~received_word[syndrome];
            
            // Extract corrected data bits from corrected word using a for loop
            // Skip parity positions and extract only data positions
            data_idx = 0;
            for (i = 1; i <= 71; i = i + 1) begin
                if ((i & (i - 1)) != 0) begin
                    data_out[data_idx] = corrected_word[i];
                    data_idx = data_idx + 1;
                end
            end
        end
    end
    
endmodule
