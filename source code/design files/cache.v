
`timescale 1ns / 1ps

module cache(
    input clk,
    input rstn,
    // cpu<->cache
    input [7:0]cpu_req_addr,
    input cpu_req_row,
    input cpu_req_valid,
    input [31:0]cpu_data_write,
    output reg [31:0]cpu_data_read,
    output reg cpu_ready,
    // cache<->memory
    output reg [7:0]mem_req_addr,
    output reg mem_req_row,
    output reg mem_req_valid,
    output reg [31:0]mem_data_write,
    input [31:0]mem_data_read,
    input mem_ready
    );

parameter V = 37;
parameter D = 36;
parameter TagMSB = 35;
parameter TagLSB = 32;
parameter BlockMSB = 31;
parameter BlockLSB = 0 ;

parameter IDLE=0;
parameter Compare=1;
parameter New=2;
parameter WriteBack=3;

reg [37:0] cache_data [0:15];           // 37:V, 36:D,[35:32]:TAG,[31:0]DATA
reg [1:0] state, next_state;
reg hit;

wire [3:0]cpu_req_index;
wire [3:0]cpu_req_tag;

assign cpu_req_index=cpu_req_addr[3:0];
assign cpu_req_tag=cpu_req_addr[7:4];

integer i;
//?????cache
initial
begin
    for(i = 0; i < 16; i = i + 1)
        cache_data[i] = 38'd0;
end

//???????cache??cache??§³?16?ï…?????§³?256?ï…1??=1??=32bit
//???????8¦Ë???????????????[3:0]????????[7:4]??Tag
//cache V+D+Tag+Data=1+1+4+32=38


always@(posedge clk, negedge rstn)
    if(!rstn)
        state<=IDLE;
    else
        state<=next_state;

always@(*)
case(state)
    IDLE:if(cpu_req_valid)
            next_state = Compare;
         else
            next_state = IDLE;
    Compare:if(hit)
                   next_state = IDLE;
               else if(cache_data[cpu_req_index][V:D]==2'b11)               //if the block is valid and dirty then go to WriteBack
                   next_state=WriteBack;
               else 
                   next_state=New;
    New:if(mem_ready)
                   next_state=Compare;
             else
                   next_state=New;
    WriteBack:if(mem_ready)
                   next_state=New;
              else
                   next_state=WriteBack;
      default:next_state=IDLE;
endcase

always@(*)
if(state==Compare)
    if(cache_data[cpu_req_index][37]&&cache_data[cpu_req_index][TagMSB:TagLSB]==cpu_req_tag)
        hit=1'b1;
    else
        hit=1'b0;

always@(posedge clk) begin
    if(state == New) begin                 //read new block from memory to cache
        if(!mem_ready) begin
            mem_req_addr <= cpu_req_addr;
            mem_req_row <= 1'b0;
            mem_req_valid <= 1'b1; 
        end
        else begin
            mem_req_valid <= 1'b0;
            cache_data[cpu_req_index][BlockMSB:BlockLSB] <= mem_data_read;
            cache_data[cpu_req_index][V:D] <= 2'b10;
            cache_data[cpu_req_index][TagMSB:TagLSB] <= cpu_req_tag;
        end
    end
    else if(state==WriteBack) begin                    //write dirty block to memory
        if(!mem_ready) begin
            mem_req_addr <= {cache_data[cpu_req_index][TagMSB:TagLSB],cpu_req_index};
            mem_req_row <= 1'b1;
            mem_data_write <= cache_data[cpu_req_index][BlockMSB:BlockLSB];
            mem_req_valid <= 1'b1;
        end
        else
            mem_req_valid<=1'b0;
    end
    else
        mem_req_valid=1'b0;
end

always@(posedge clk)
    if(state == Compare && hit)
        if(cpu_req_row==1'b0)              //read hit
        begin
            cpu_ready <= 1'b1;
            cpu_data_read <= cache_data[cpu_req_index][31:0];
        end
        else                               //write hit, D???1
        begin
            cpu_ready<=1'b1;
            cache_data[cpu_req_index][31:0]=cpu_data_write;
            cache_data[cpu_req_index][D]=1'b1;
        end
    else
        cpu_ready<=1'b0;

endmodule

