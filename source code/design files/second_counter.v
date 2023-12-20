`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/19 20:33:44
// Design Name: 
// Module Name: second_counter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module second_counter(
    input clk,
    input rstn,
    input in,
    output sig
    );
    
    wire [27:0] cnt;
    reg [5:0] r_num;
    reg r_sig;
    
    initial begin
        r_num = 6'h0;
        r_sig = 1'b0;
    end
    
    counter #(28, 0, 99999999) divided_counter (.clk(clk), .rstn(rstn), .pe(1'b0), .ce(1'b1), .d(10'b0), .q(cnt));

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            r_num = 6'h0;
            r_sig = 1'b0;
        end
        else if(in == 1) begin
            r_num = 6'h0;
            r_sig = 1'b0;
        end
        else if(r_num == 20)
            r_sig = 1'b1;
        else if(cnt == 99999998) 
            r_num = r_num + 1;
    end

    assign sig = r_sig;
    
endmodule
