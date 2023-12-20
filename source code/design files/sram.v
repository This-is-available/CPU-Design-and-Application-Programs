`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/16 12:42:59
// Design Name: 
// Module Name: sram
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


module sram #(
    parameter ADDR_WIDTH = 8, DATA_WIDTH = 8, DEPTH = 256, MEMFILE = ""
    )(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire write_en,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
    );
    reg [DATA_WIDTH-1:0] memory_array[0:DEPTH-1];

    initial begin
        if (MEMFILE > 0)
        begin
            $display("Loading memory init file '" + MEMFILE + "' into array.");
            $readmemh(MEMFILE, memory_array);
        end
    end

    always @(posedge clk) begin
        if(write_en) begin
            memory_array[addr] <= data_in;
        end
        else begin
            data_out <= memory_array[addr];
        end
    end
endmodule

