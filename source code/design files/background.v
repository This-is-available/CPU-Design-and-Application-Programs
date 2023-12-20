//��������ʾģ�飬Ϊ��ʡ�洢�ռ䣬���ǲ����˽�һ32*32�����ؿ�ѭ����ʾ���������ķ�ʽ������Ϊ��ʾЧ����������x_offset��y_offset����ƫ����
//����x_offsetΪ[0,31]�ڲ��ϱ仯�ģ�ʵ�ֱ��������Ķ�̬Ч����
//y_offset����һ��紫���bounce�źŴ�������ʹ�û��ٲ���ʱ��Ļ���ֵĶ���������һ�����������˶˿ڵ���δ��ӣ�
`timescale 1ns / 1ps
module background(
    input clk,
    input rstn,
    input clk_ram,
    input bounce,   //bounce�źţ����ٲ����Ķ��� To Be Done
    input [9:0] vga_x,
    input [8:0] vga_y,
    output [11:0] color
    );
    wire [18:0] addr;
    wire [19:0] count;
    wire [23:0] count_y_offset;
    wire [4:0] x_offset;
    wire [9:0] addr_ram;
    wire [4:0] addr_x;
    wire [4:0] addr_x_m;
    wire [4:0] addr_y;
    wire [4:0] addr_y_m;
    reg [3:0] y_offset;
    
    initial begin
        y_offset = 0;
    end


    //��ַ��ת������
    // assign addr = vga_x + 640 * vga_y;

    //addr_x��addr_yΪ����ʾ����vga_x,vga_y��mod 32�������Ӷ��γ�ת��Ϊ32*32ͼ���ϵ�����ֵ���ɸ�����������������ʾ��ַ
    assign addr_x = vga_x % 32;
    assign addr_y = vga_y % 32;

    //addr_x_m��addr_y_mΪ�������ʾЧ���������ֵ��Ҳ���������x_offset��y_offset������������Խ���жϣ�ʹ�ÿ�ѭ����ʾ
    assign addr_x_m = ( ( addr_x + x_offset ) >= 32 ) ? ( addr_x + x_offset - 32 ) : ( addr_x + x_offset );
    assign addr_y_m = ( ( addr_y + y_offset ) >= 32 ) ? ( addr_y + y_offset - 32 ) : ( addr_y + y_offset );

    //���㿼������ʾЧ��������Ǵ��ݸ�ram�ĵ�ֵַ��ȡ��ͼ����Ϣ
    assign addr_ram = ( ( addr_x_m + 32 * addr_y_m ) >= 1024 ) ? ( addr_x_m + 32 * addr_y_m -1024 ) : ( addr_x_m + 32 * addr_y_m );

    //����������Ƶ����ʹ�û��һ�����������count�źţ�����Ϊ1000000
    counter #(20, 0, 1000000) frequency_divider_counter(.clk(clk), .rstn(rstn), .pe(1'b0), .ce(1'b1), .d(20'd0), .q(count));
    
    //y_offset�Ŀ����ź�ģ�飬ͬ���Ƿ�ƵЧ���������������δ���ô�ģ����д�����
    counter #(32, 0, 10000001) counter_y_offset(.clk(clk), .rstn(rstn), .pe(1'b0), .ce(1'b1), .d(32'd0), .q(count_y_offset));
    
    //����count���źţ�ÿ��countֵΪ1000000ʱʹ����1������һ�Σ���ʹx_offset����һ��32��Ϊһ�����ڣ���������ͼ���ˮƽ������
    counter #(5, 0, 31) offset_counter(.clk(clk), .rstn(rstn), .pe(1'b0), .ce(count == 1000000), .d(5'd0), .q(x_offset));

    //�����洢ģ�飬��������ʾ.mem�ļ�����Ϣ
    sram #(.ADDR_WIDTH(10), .DATA_WIDTH(12), .DEPTH(1024), .MEMFILE("mbackground.mem")) ram(
        .clk(clk_ram),
        .addr(addr_ram),
        .write_en(0),
        .data_in(0),
        .data_out(color)
    );

    //y_offset�źű任ģ�飬��������δ���ô�ģ����д�����
    always @(posedge clk) begin
        if (bounce) begin
            y_offset <= 16;
        end
        else if (count_y_offset == 10000000 && y_offset > 0) begin
            y_offset <= y_offset - 1;
        end
    end

endmodule
