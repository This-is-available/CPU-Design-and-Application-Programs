`timescale 1ns / 1ps


module counter #(
    parameter DATA_WIDTH = 16, RST_VLU = 0, LIMIT = 1024
    )(
    input clk, 
    input rstn,
    input pe, 
    input ce,
    input [DATA_WIDTH-1:0] d,
    output reg [DATA_WIDTH-1:0] q
    );
    
    initial q = 1'b0;
    
    always @(posedge clk, negedge rstn) begin
        if (!rstn) q <= RST_VLU;
        else if (pe) q <= d;
        else if (ce) begin
            if (q == LIMIT) q <= 0;
            else q <= q + 1;
        end
    end
    
endmodule
