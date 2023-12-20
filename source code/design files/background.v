//即背景显示模块，为节省存储空间，我们采用了将一32*32的像素块循环显示铺满背景的方式，并且为显示效果而加上了x_offset和y_offset两组偏移量
//其中x_offset为[0,31]内不断变化的，实现背景滚动的动态效果；
//y_offset是由一外界传入的bounce信号触发，想使得击毁病毒时屏幕出现的抖动现象，这一功能我们留了端口但尚未添加；
`timescale 1ns / 1ps
module background(
    input clk,
    input rstn,
    input clk_ram,
    input bounce,   //bounce信号，击毁病毒的抖屏 To Be Done
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


    //地址的转换部分
    // assign addr = vga_x + 640 * vga_y;

    //addr_x，addr_y为将显示坐标vga_x,vga_y做mod 32操作，从而形成转换为32*32图像上的坐标值，可根据这组坐标算其显示地址
    assign addr_x = vga_x % 32;
    assign addr_y = vga_y % 32;

    //addr_x_m，addr_y_m为添加完显示效果后的坐标值，也就是添加了x_offset和y_offset变量，并做了越界判断，使得可循环显示
    assign addr_x_m = ( ( addr_x + x_offset ) >= 32 ) ? ( addr_x + x_offset - 32 ) : ( addr_x + x_offset );
    assign addr_y_m = ( ( addr_y + y_offset ) >= 32 ) ? ( addr_y + y_offset - 32 ) : ( addr_y + y_offset );

    //计算考虑了显示效果后的我们传递给ram的地址值，取出图像信息
    assign addr_ram = ( ( addr_x_m + 32 * addr_y_m ) >= 1024 ) ? ( addr_x_m + 32 * addr_y_m -1024 ) : ( addr_x_m + 32 * addr_y_m );

    //计数器做分频器，使得获得一个区间递增的count信号，上限为1000000
    counter #(20, 0, 1000000) frequency_divider_counter(.clk(clk), .rstn(rstn), .pe(1'b0), .ce(1'b1), .d(20'd0), .q(count));
    
    //y_offset的控制信号模块，同样是分频效果，具体参数因尚未启用此模块而尚待调试
    counter #(32, 0, 10000001) counter_y_offset(.clk(clk), .rstn(rstn), .pe(1'b0), .ce(1'b1), .d(32'd0), .q(count_y_offset));
    
    //接受count的信号，每次count值为1000000时使能置1，计数一次，即使x_offset增加一，32次为一个周期，正是我们图层的水平像素数
    counter #(5, 0, 31) offset_counter(.clk(clk), .rstn(rstn), .pe(1'b0), .ce(count == 1000000), .d(5'd0), .q(x_offset));

    //例化存储模块，包含有显示.mem文件的信息
    sram #(.ADDR_WIDTH(10), .DATA_WIDTH(12), .DEPTH(1024), .MEMFILE("mbackground.mem")) ram(
        .clk(clk_ram),
        .addr(addr_ram),
        .write_en(0),
        .data_in(0),
        .data_out(color)
    );

    //y_offset信号变换模块，参数因尚未启用此模块而尚待调试
    always @(posedge clk) begin
        if (bounce) begin
            y_offset <= 16;
        end
        else if (count_y_offset == 10000000 && y_offset > 0) begin
            y_offset <= y_offset - 1;
        end
    end

endmodule
