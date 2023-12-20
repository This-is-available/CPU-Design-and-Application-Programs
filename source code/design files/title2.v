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
    // ͼ���ĸ߶ȺͿ�ȳ���
    localparam WIDTH = 80, HEIGHT = 11;

    reg [9:0] addr;

    //�����洢ģ�飬��������ʾ.mem�ļ�����Ϣ
    sram #(.ADDR_WIDTH(10), .DATA_WIDTH(12), .DEPTH(880), .MEMFILE("mlltitle.mem")) ram(
        .clk(clk_ram),
        .addr(addr),
        .write_en(0),
        .data_in(0),
        .data_out(color)
    );

    //��ʾ���֣�ifΪ��ͼ����ʾλ�õ��жϣ���vga_x��vga_yɨ����Ӧ����ʱ��Ч
    always @(posedge clk) begin
        if ((vga_x >= POS_X) & (vga_x < (POS_X + WIDTH)) & (vga_y >= POS_Y) & (vga_y < (POS_Y + HEIGHT))) begin
            addr = ( vga_y - POS_Y ) * 80 + vga_x - POS_X ;
            color_on <= 1;
        end
        else
            color_on <= 0;
    end

endmodule
