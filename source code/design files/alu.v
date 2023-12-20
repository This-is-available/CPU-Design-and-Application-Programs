`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/12 16:14:32
// Design Name: 
// Module Name: alu
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


module alu 
#(parameter WIDTH = 32     )
(
input [WIDTH-1 : 0] a, b,       
input [2:0] s,                      
output reg [WIDTH-1 : 0] y,     
output reg [2:0] f                     
);
reg [WIDTH : 0] z;
always @(*)
begin
    f = 0;
    z = {a[WIDTH-1],a} - {b[WIDTH-1],b};
        if(z[WIDTH] == 0)f[1] = 0;
        else 
            begin 
            f[1] = 1;
            f[0] =0;
            end
        if(a < b)
            begin 
            f[2] = 1;
            f[0] = 0;
            end
        else f[2] = 0;
        if(z == 0)f = 1;
    case(s)
        0: y = z[WIDTH-1 : 0];
        1: y = a + b;
        2: y = a & b;
        3: y = a | b;
        4: y = a ^ b;
        5: y = a >> b;
        6: y = a << b;
        7: y = $signed(a) >>> b;
    endcase
end
endmodule
