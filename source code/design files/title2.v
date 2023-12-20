`timescale 1ns / 1ps
module title2#(
    parameter POS_X = 399, POS_Y = 252
    )(
    input clk,
    input clk_ram,
    input [9:0] vga_x,
    input [8:0] vga_y,
    output reg color_on,
    output [11:0] color
    );
    // 图样的高度和宽度常数
    localparam WIDTH = 80, HEIGHT = 11;

    reg [9:0] addr;

    //例化存储模块，包含有显示.mem文件的信息
    sram #(.ADDR_WIDTH(10), .DATA_WIDTH(12), .DEPTH(880), .MEMFILE("mlltitle.mem")) ram(
        .clk(clk_ram),
        .addr(addr),
        .write_en(0),
        .data_in(0),
        .data_out(color)
    );

    //显示部分，if为对图层显示位置的判断，当vga_x和vga_y扫到对应区域时有效
    always @(posedge clk) begin
        if ((vga_x >= POS_X) & (vga_x < (POS_X + WIDTH)) & (vga_y >= POS_Y) & (vga_y < (POS_Y + HEIGHT))) begin
            addr = ( vga_y - POS_Y ) * 80 + vga_x - POS_X ;
            color_on <= 1;
        end
        else
            color_on <= 0;
    end

endmodule
