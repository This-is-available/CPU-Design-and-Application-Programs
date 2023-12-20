`timescale 1ns / 1ps

module DB(//È¥¶¶¶¯
    input x,
    input rstn,
    input clk,
    output reg y
    );
    reg flag1;
    reg [19:0] cnt1,cnt2;
    reg [25:0] cnt;
    
    initial
    begin
        flag1 = 0;
        y = 0;
        cnt1 = 0;
        cnt2 = 0;    
    end
    
    always@( posedge clk )
    begin
        if(~rstn)
        begin
            cnt1 <= 1'b0;
            cnt2 <= 1'b0;
            flag1 <= 0;
            if( y ) y <= 1'b0;
        end
        else  if( x==1 )
        begin
            cnt1 = cnt1 + 1;
            cnt = cnt + 1;
            cnt2 = 1'b0;
            if( cnt1 == 1000000 && flag1 == 0 )
            begin
                cnt1 = 1'b0;
                y = ~y;
                flag1 = 1'b1;
            end
            if (cnt == 40000000 && flag1 == 1 )
            begin
                cnt = 1'b0;
                y = ~y;
            end
        end
        else
        begin
            cnt2 = cnt2 + 1;
            cnt1 = 1'b0;
            cnt = 1'b0;
            flag1 = 1'b0;
            if( cnt2 == 1000000 )
            begin
                cnt2 = 1'b0;
                if( y==1 ) y = ~y;
            end
        end
    end
    
endmodule
