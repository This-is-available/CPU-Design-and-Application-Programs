`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/27 14:39:52
// Design Name: 
// Module Name: register
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

module  rf  #(
    parameter AW = 5,		
    parameter DW = 32	
)(
    input  clk,			//时钟
    input [AW-1:0]  ra0, ra1,ra_debug,//读地址
    output [DW-1:0]  rd0, rd1,rd_debug,	//读数据
    input [AW-1:0]  wa,		//写地址
    input [DW-1:0]  wd,		//写数据
    input we			//写使能
);
reg [DW-1:0]  rf [0:31]; 	//寄存器堆

assign rd0 = (ra0 == wa && we && wa != 0) ? wd : rf[ra0];
assign rd1 = (ra1 == wa && we && wa != 0) ? wd : rf[ra1];
assign rd_debug = (ra_debug == wa && we && wa != 0) ? wd : rf[ra_debug];
always  @(posedge  clk)
    begin
    rf[0]<=0;
    if(we&&wa!=0)rf[wa]<=wd;
    end
endmodule

