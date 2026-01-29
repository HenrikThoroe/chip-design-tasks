module axi_lite_tb;
  // Parameters
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;

  // Clock and reset
  logic clk;
  logic rst_n;

  // AXI Lite signals
  logic [ADDR_WIDTH-1:0] awaddr;
  logic [DATA_WIDTH-1:0] wdata;
  logic [3:0] wstrb;
  logic awvalid;
  logic wvalid;
  logic bready;

  logic [ADDR_WIDTH-1:0] araddr;
  logic arvalid;
  logic rready;
  logic rvalid;
  logic arready;

  logic awready;
  logic wready;
  logic bvalid;
  logic [DATA_WIDTH-1:0] rdata;
  logic [1:0] rresp;
  logic bresp;
  logic [DATA_WIDTH-1:0] read_data;
  logic [DATA_WIDTH-1:0] expected_data;

  // DUT instantiation
  axi_lite #(
      .C_S_AXI_ADDR_WIDTH(ADDR_WIDTH),
      .C_S_AXI_DATA_WIDTH(DATA_WIDTH)
  ) dut (
      .s_axi_aclk(clk),
      .s_axi_aresetn(rst_n),

      .s_axi_awaddr (awaddr),
      .s_axi_wdata  (wdata),
      .s_axi_wstrb  (wstrb),
      .s_axi_awvalid(awvalid),
      .s_axi_wvalid (wvalid),
      .s_axi_bready (bready),

      .s_axi_araddr (araddr),
      .s_axi_arvalid(arvalid),
      .s_axi_arready(arready),
      .s_axi_rready (rready),

      .s_axi_awready(awready),
      .s_axi_wready (wready),
      .s_axi_bvalid (bvalid),
      .s_axi_bresp  (bresp),

      .s_axi_rdata (rdata),
      .s_axi_rvalid(rvalid),
      .s_axi_rresp (rresp)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5ns clk = ~clk;
  end

  // Reset generation
  initial begin
    rst_n = 1'b0;
    #20ns;
    rst_n = 1'b1;
  end

  // Task for performing AXI Lite write
  task automatic axi_lite_write(input logic [ADDR_WIDTH-1:0] addr,
                                input logic [DATA_WIDTH-1:0] data, input logic [3:0] strb);
    @(posedge clk);
    awaddr  <= addr;
    wdata   <= data;
    wstrb   <= strb;
    awvalid <= 1'b1;
    wvalid  <= 1'b1;

    wait (awready && wready);
    @(posedge clk);
    awvalid <= 1'b0;
    wvalid  <= 1'b0;

    bready  <= 1'b1;
    wait (bvalid);
    @(posedge clk);
    bready <= 1'b0;
  endtask

  // Task for performing AXI Lite read
  task automatic axi_lite_read(input logic [ADDR_WIDTH-1:0] addr,
                               output logic [DATA_WIDTH-1:0] data);
    @(posedge clk);
    araddr  <= addr;
    arvalid <= 1'b1;

    wait (arready);
    @(posedge clk);
    arvalid <= 1'b0;

    rready  <= 1'b1;
    wait (rvalid);
    data = rdata;
    @(posedge clk);
    rready <= 1'b0;
  endtask

  // Test sequence
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    read_data <= 0;
    expected_data <= 0;


    // Wait for reset to complete
    @(posedge rst_n);
    #20ns;

    // Test 1: Write and Read
    $display("Starting AXI Lite Slave Tests");

    // Write test data
    axi_lite_write(32'h0000_0000, 32'hDEADBEEF, 4'b1111);

    // Read back and verify
    axi_lite_read(32'h0000_0000, read_data);
    expected_data = 32'hDEADBEEF;
    assert (read_data == expected_data) $display("Test 1 Passed: Write/Read verified");
    else $error("Test 1 Failed: Expected %h, got %h", expected_data, read_data);
    $finish;

    // Test 2: Byte-level writes
    /*axi_lite_write(32'h1000_0004, 32'hFACE, 4'b1100);
        
        // Read back byte-written data
        axi_lite_read(32'h1000_0004, read_data);
        expected_data = 32'hFACE00FF;
        assert(read_data == expected_data)
            $display("Test 2 Passed: Byte-write verified")
        else begin
            $error("Test 2 Failed: Expected %h, got %h", expected_data, read_data);
            $finish;
        end*/

    $display("All tests completed successfully!");
    $dumpfile("dump.vcd");
    $dumpvars;
    $finish;
  end

endmodule
