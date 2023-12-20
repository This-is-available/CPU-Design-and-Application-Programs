`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/11 20:19:17
// Design Name: 
// Module Name: PS
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


module PC(//È¡±ßÔµ
    input s,
    input clk,
    output y
    );
    
    wire w1,w2;
    
    D_ff D( .D( s ), .clk( clk ), .Q( w1 ) );
    not G1( w2, w1 );
    and G2( y, w2, s);
    
endmodule
