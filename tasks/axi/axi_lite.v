module axi_lite
#(
    parameter C_S_AXI_ADDR_WIDTH = 32,
    parameter C_S_AXI_DATA_WIDTH = 32
)
(
    input                              s_axi_aclk,
    input                              s_axi_aresetn,
    // AXI slave ports

    // WRITE REQUEST CHANNEL
    input   [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input                              s_axi_awvalid,
    output reg                         s_axi_awready,

    // READ REQUEST CHANNEL
    input   [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    input                              s_axi_arvalid,
    output reg                         s_axi_arready,

    // WRITE DATA CHANNEL
    input   [C_S_AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input   [C_S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input                              s_axi_wvalid,
    output reg                         s_axi_wready,

    // WRITE RESPONSE CHANNEL
    input                              s_axi_bready,
    output reg [1:0]                   s_axi_bresp,
    output reg                         s_axi_bvalid,

     // READ DATA CHANNEL
    output reg [C_S_AXI_DATA_WIDTH-1:0]  s_axi_rdata,
    output reg                           s_axi_rvalid,
    input                                s_axi_rready,
    output reg [1:0]                     s_axi_rresp
);

// Internal Signals

localparam MEMORY_SIZE = 2 ** (C_S_AXI_ADDR_WIDTH - 4);
reg [C_S_AXI_DATA_WIDTH-1:0] memory [MEMORY_SIZE - 1:0];
integer k;

// Initialize memory to 0 on start
initial begin
  for (k = 0; k < MEMORY_SIZE; k = k + 1) begin
    memory[k] = 0;
  end
end

reg [C_S_AXI_ADDR_WIDTH-1:0] w_addr;
reg [C_S_AXI_ADDR_WIDTH-1:0] r_addr;

reg [1:0]write_state = 0;
localparam WRITE_WAITING = 0;
localparam WRITE_WAIT_FOR_ADDRESS = 1;
localparam WRITE_STROBE = 2;

reg [C_S_AXI_DATA_WIDTH - 1:0] input_buffer;
reg [C_S_AXI_DATA_WIDTH - 1:0] memory_buffer;

wire [C_S_AXI_DATA_WIDTH - 1:0] strobed_input;
genvar i;
generate
  for (i = 0; i < C_S_AXI_DATA_WIDTH / 8; i = i + 1) begin
    // Bytes from input and memory are combined to generate word according to strobe
    assign strobed_input[(i + 1) * 8 - 1: i * 8] = s_axi_wstrb[i] ?
      input_buffer[(i + 1) * 8 - 1: i * 8] : memory_buffer[(i + 1) * 8 - 1: i * 8];
  end
endgenerate

reg [1:0] write_response_state = 0;
localparam WRITE_RESPONSE_WAITING = 0;
localparam WRITE_RESPONSE_ADDRESS_VALID = 1;
localparam WRITE_RESPOSNE_VALID = 2;

reg read_state = 0;
localparam READ_WAITING = 0;
localparam READ_WAIT_FOR_ADDRESS = 1;

// Write request always block
always@(posedge s_axi_aclk)
begin
  if(!s_axi_aresetn) begin
    s_axi_awready <= 1'b0;
    w_addr <= 0;
  end else if (s_axi_awready && !s_axi_awvalid)
    // Ready for new write address
    s_axi_awready <= 1'b0;
  else if (s_axi_awvalid) begin
    // Save write address and confirm to master
    w_addr <= s_axi_awaddr;
    s_axi_awready <= 1'b1;
  end
end

//Read request block
always@(posedge s_axi_aclk)
begin
  if(!s_axi_aresetn) begin
    s_axi_arready <= 0;
    r_addr <= 0;
  end else if (s_axi_arready && !s_axi_arvalid)
    // Ready for new read address
    s_axi_arready <= 0;
  else if (s_axi_arvalid) begin
    // Save read address and confirm to master
    r_addr <= s_axi_araddr;
    s_axi_arready <= 1;
  end
end

// Write data always block
always @(posedge s_axi_aclk)
begin
  if (!s_axi_aresetn) begin
    s_axi_wready <= 0;
    write_state <= WRITE_WAITING;
  end else begin
    case (write_state)
      WRITE_WAITING : begin
        if (s_axi_wready && !s_axi_wvalid) begin
          // Ready for new data
          s_axi_wready <= 0;
        end else if (s_axi_wvalid && !s_axi_awready) begin
          // Address transfer is in progress. Wait for it to finish
          write_state <= WRITE_WAIT_FOR_ADDRESS;
        end else if (s_axi_wvalid && !s_axi_wready) begin
          input_buffer <= s_axi_wdata;
          memory_buffer <= memory[w_addr];
          write_state <= WRITE_STROBE;
        end
      end
      WRITE_WAIT_FOR_ADDRESS: begin
        if (!s_axi_wvalid) begin
          // While waiting for the write address, the data was invalidated.
          // Do not write to memory, wait for new data.
          write_state <= WRITE_WAITING;
        end else if (s_axi_awready) begin
          input_buffer <= s_axi_wdata;
          memory_buffer <= memory[w_addr[C_S_AXI_ADDR_WIDTH-1:2]];
          write_state <= WRITE_STROBE;
        end
      end
      WRITE_STROBE: begin
        // Write strobed input to memory and confirm to master
        memory[w_addr[C_S_AXI_ADDR_WIDTH-1:2]] <= strobed_input;
        s_axi_wready <= 1;
        write_state <= WRITE_WAITING;
      end
    endcase
  end
end

// Write response block
always@(posedge s_axi_aclk)
begin
  if (!s_axi_aresetn) begin
    s_axi_bresp <= 2'b0;
    s_axi_bvalid <= 0;
    write_response_state <= WRITE_RESPONSE_WAITING;
  end else begin
    case (write_response_state)
      WRITE_RESPONSE_WAITING: begin
        if (s_axi_bvalid && !s_axi_wvalid) s_axi_bvalid <= 0; 
        else if (s_axi_awready)
          // Write address was transferred
          write_response_state <= WRITE_RESPONSE_ADDRESS_VALID;
      end
      WRITE_RESPONSE_ADDRESS_VALID: begin
        if (s_axi_wready) begin
          // Write has been executed
          write_response_state <= WRITE_RESPOSNE_VALID;
          s_axi_bvalid <= 1;
        end
      end
      WRITE_RESPOSNE_VALID: begin
        // Master invalidated write data, ready for new write
        if (!s_axi_wvalid) write_response_state <= WRITE_RESPONSE_WAITING;
      end
    endcase
  end
end

// Read data always blcok
always @(posedge s_axi_aclk)
begin
  if (!s_axi_aresetn) begin
    s_axi_rdata <= 0;
    s_axi_rvalid <= 0;
    s_axi_rresp <= 0;
  end else begin
    case (read_state)
      READ_WAITING : begin
        if (s_axi_rvalid && !s_axi_rready) 
          // Master confirmed read, ready for next read
          s_axi_rvalid <= 0;
        else if (s_axi_arvalid && !s_axi_arready)
          // Read Address Transfer is in progress. Wait for it to finish
          read_state <= READ_WAIT_FOR_ADDRESS;
      end
      READ_WAIT_FOR_ADDRESS : begin
        if (s_axi_arready) begin
          // Read requested address from memory and validate
          s_axi_rdata <= memory[r_addr[C_S_AXI_ADDR_WIDTH-1:2]];
          s_axi_rvalid <= 1;
          read_state <= READ_WAITING;
        end
      end
    endcase
  end
end

endmodule