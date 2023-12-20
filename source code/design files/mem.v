`timescale 1ns / 1ps

module mem(
    input clk,
    input rstn,
    // past data_mem
    input [7:0] dpra,
    output [31:0] dpo,
    // cache <-> memory
    input [7:0] mem_req_addr,
    input mem_req_row,
    input mem_req_valid,
    input [31:0] mem_data_write,
    output reg [31:0] mem_data_read,
    output reg mem_ready
    );

reg [31:0] mem [0:255];                 //255?φΧΦ??255?φ?ι

integer i;
initial
begin
    for(i = 0; i < 256; i = i + 1)
        mem[i] = 32'd0;
end

initial begin
    if("data_v5.mem" > 0)
    begin
        $display("Loading memory init file '" + "data_v5.mem" + "' into array.");
        $readmemh("data_v5.mem", mem);
    end
end

always@(posedge clk, negedge rstn) begin
    if(!rstn)
        mem_ready <= 1'b0;
    else if(mem_req_valid && mem_req_row==1'b1 && !mem_ready)                      //write
    begin
        mem[mem_req_addr] = mem_data_write[31:0];
        mem_ready <= 1'b1;
    end
    else if(mem_req_valid && mem_req_row==1'b0 && !mem_ready)                      //read
    begin
        mem_data_read = mem[mem_req_addr];
        mem_ready <= 1'b1;
    end
    else if(mem_req_valid && mem_ready)
        mem_ready <= 1'b0;
end

assign dpo = mem[dpra];


//always@(posedge clk) begin
//    if(we)
//        mem[a] = d;
//end

//assign spo = mem[a];

//assign dpo = (a == dpra && we) ? d : mem[dpra];

endmodule


