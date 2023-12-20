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
    // ͼ���ĸ߶ȺͿ�ȳ���
    localparam WIDTH = 320, HEIGHT = 36;

    reg [13:0] addr;

    //�����洢ģ�飬��������ʾ.mem�ļ�����Ϣ
    sram #(.ADDR_WIDTH(14), .DATA_WIDTH(12), .DEPTH(11520), .MEMFILE("mltitle.mem")) ram(
        .clk(clk_ram),
        .addr(addr),
        .write_en(0),
        .data_in(0),
        .data_out(color)
    );

    //��ʾ���֣�ifΪ��ͼ����ʾλ�õ��жϣ���vga_x��vga_yɨ����Ӧ����ʱ��Ч
    always @(posedge clk) begin
        if ((vga_x >= POS_X) & (vga_x < (POS_X + WIDTH)) & (vga_y >= POS_Y) & (vga_y < (POS_Y + HEIGHT))) begin
            addr = ( vga_y - POS_Y ) * 320 + vga_x - POS_X ;
            color_on <= 1;
        end
        else
            color_on <= 0;
    end

endmodule
