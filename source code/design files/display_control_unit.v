`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Science and Technology of China
// Engineer: Vincentove
// 
// Create Date: 2021/11/28 18:34:44
// Design Name: display_control_unit
// Module Name: display_control_unit
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


module display_control_unit #(
    parameter HST = 800, HSW = 96, HBP = 48, HEN= 640, HFP = 16, VST = 525, VSW = 2, VBP = 33, VEN = 480, VFP = 10                       
    )(
    input pclk, rstn,
    output wire hs, vs, display_en,
    output wire [9:0] vga_x,
    output wire [8:0] vga_y
    );
    wire [9:0] hcnt, vcnt;
    wire ce, hen, ven;

    assign ce = (hcnt == HEN + HFP - 1),
    hen = (hcnt <= HEN - 1),
    ven = (vcnt <= VEN - 1),
    display_en = hen && ven,
    hs = ((hcnt >= HEN + HFP) && (hcnt < HEN + HFP + HSW)),    
    vs = ((vcnt >= VEN + VFP) && (vcnt < VEN + VFP + VSW)),
    vga_x = (hcnt >= 640) ? 639 : hcnt,
    vga_y = (vcnt >= 480) ? 479 : vcnt[8:0];

    counter #(10, 0, HST - 1) horizontal_counter (.clk(pclk), .rstn(rstn), .pe(1'b0), .ce(1'b1), .d(10'b0), .q(hcnt));
    counter #(10, 0, VST - 1) vertical_counter (.clk(pclk), .rstn(rstn), .pe(1'b0), .ce(ce), .d(10'b0), .q(vcnt));
    
endmodule
