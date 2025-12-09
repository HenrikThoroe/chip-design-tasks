module axi_lite
#(
    parameter C_S_AXI_ADDR_WIDTH = 32,
    parameter C_S_AXI_DATA_WIDTH = 32
)
(
    input                              s_axi_aclk,
    input                              s_axi_aresetn,
    // AXI slave ports
    // {{{
    // ADDRESS WRITE CHANNEL
    input   [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input                              s_axi_awvalid,
    output                             s_axi_awready,


    // ADDRESS READ CHANNEL
    input   [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    input                              s_axi_arvalid,
    output                             s_axi_arready,


    // ADDRESS WRITE CHANNEL
    input   [C_S_AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input   [C_S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input                              s_axi_wvalid,
    output                             s_axi_wready,

    input                              s_axi_bready,
    output  [1:0]                      s_axi_bresp,
    output                             s_axi_bvalid,

     // RESPONSE READ CHANNEL
    output   [C_S_AXI_DATA_WIDTH-1:0]  s_axi_rdata,
    output                             s_axi_rvalid,
    input                              s_axi_rready,
    output  [1:0]                      s_axi_rresp
    // }}}
);
//Your internal Signals


// Write address always block
always@(posedge s_axi_aclk)
begin
    if(!s_axi_aresetn)
    begin
    end
    else
    begin
    end
end
// Write data always block
always@(posedge s_axi_aclk)
begin
    if(!s_axi_aresetn)
    begin
    end
    else
    begin        
    end
end
// Write respons block
always@(posedge s_axi_aclk)
  begin
    if (!s_axi_aresetn)
    begin
    end
    else
    begin
    end
  end
//Read address block
always @(posedge s_axi_aclk)
begin
    if (!s_axi_aresetn)
    begin
    end
    else
    begin
    end
end
// Read data always blcok
always @(posedge s_axi_aclk)
  begin
    if (!s_axi_aresetn)
    begin
    end
    else
    begin
    end
  end

endmodule