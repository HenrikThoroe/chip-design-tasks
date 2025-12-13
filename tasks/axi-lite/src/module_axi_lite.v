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
//Your internal Signals

reg [C_S_AXI_DATA_WIDTH-1:0] memory [2 ** C_S_AXI_ADDR_WIDTH - 1:0];

reg [C_S_AXI_ADDR_WIDTH-1:0] w_addr;
reg [C_S_AXI_ADDR_WIDTH-1:0] r_addr;

reg write_state = 0;
localparam WRITE_WAITING = 0;
localparam WRITE_WAIT_FOR_ADDRESS = 1;

reg [1:0]write_response_state = 0;
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
      s_axi_awready <= 1'b0;
  	else if (s_axi_awvalid) begin
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
      s_axi_arready <= 0;
    else if (s_axi_arvalid) begin
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
            s_axi_wready <= 0;
          end else if (s_axi_wvalid && !s_axi_awready) begin
            // Address transfer is in progress. Wait for it to finish
            write_state <= WRITE_WAIT_FOR_ADDRESS;
          end else if (s_axi_wvalid && !s_axi_wready) begin
            // TODO: Implement strobing
            memory[w_addr] <= s_axi_wdata;
            s_axi_wready <= 1;
          end
        end
        WRITE_WAIT_FOR_ADDRESS: begin
          if (!s_axi_wvalid) begin
            write_state <= WRITE_WAITING;
          end else if (s_axi_awready) begin
            memory[w_addr] <= s_axi_wdata;
            s_axi_wready <= 1;
            write_state <= WRITE_WAITING;
          end
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
            write_response_state <= WRITE_RESPONSE_ADDRESS_VALID;
        end
        WRITE_RESPONSE_ADDRESS_VALID: begin
          if (s_axi_wready) begin
            write_response_state <= WRITE_RESPOSNE_VALID;
            s_axi_bvalid <= 1;
          end
        end
        WRITE_RESPOSNE_VALID: begin
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
          if (s_axi_rready) s_axi_rvalid <= 0;
          else if (s_axi_arvalid && !s_axi_arready)
            // Read Address Transfer is in progress. Wait for it to finish
            read_state <= READ_WAIT_FOR_ADDRESS;
          else if (!s_axi_rvalid && s_axi_arready) begin
            s_axi_rdata <= memory[r_addr];
            s_axi_rvalid <= 1;
          end
        end
        READ_WAIT_FOR_ADDRESS : begin
          if (s_axi_arready) begin
            s_axi_rdata <= memory[r_addr];
            s_axi_rvalid <= 1;
            read_state <= READ_WAITING;
          end
        end
      endcase
    end
  end

endmodule