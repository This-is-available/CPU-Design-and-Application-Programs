`timescale 1ns / 1ps
module title1#(
    parameter POS_X = 159, POS_Y = 215
    )(
    input clk,
    input clk_ram,
    input [9:0] vga_x,
    input [8:0] vga_y,
    output reg color_on,
    output [11:0] color
    );
    // 图样的高度和宽度常数
    localparam WIDTH = 320, HEIGHT = 36;

    reg [13:0] addr;

    //例化存储模块，包含有显示.mem文件的信息
    sram #(.ADDR_WIDTH(14), .DATA_WIDTH(12), .DEPTH(11520), .MEMFILE("mltitle.mem")) ram(
        .clk(clk_ram),
        .addr(addr),
        .write_en(0),
        .data_in(0),
        .data_out(color)
    );

    //显示部分，if为对图层显示位置的判断，当vga_x和vga_y扫到对应区域时有效
    always @(posedge clk) begin
        if ((vga_x >= POS_X) & (vga_x < (POS_X + WIDTH)) & (vga_y >= POS_Y) & (vga_y < (POS_Y + HEIGHT))) begin
            addr = ( vga_y - POS_Y ) * 320 + vga_x - POS_X ;
            color_on <= 1;
        end
        else
            color_on <= 0;
    end

endmodule
