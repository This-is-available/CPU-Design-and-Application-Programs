`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/18 22:33:52
// Design Name: 
// Module Name: top
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


module top(
        input ps2_clk, ps2_data,
        input step,cont,chk,data,del,rstn,clk,
        input [15:0] x,
        output [15:0] led,
        output stop,
        output [7:0] an,
        output [2:0] seg_sel,
        output [6:0] seg,
        output hs, vs,
        output [11:0] prgb,
        output AUD_SD,
        output AUD_PWM
    );
    
        wire pclk;
        clk_wiz_0(
            .clk_in1(clk),
            .clk_out1(pclk)
        );
        
        wire display_en;
        wire [9:0] vga_x;
        wire [8:0] vga_y;
        // DCU
        display_control_unit DCU(
            .pclk(pclk),
            .rstn(rstn),
            .hs(hs),
            .vs(vs),
            .display_en(display_en),
            .vga_x(vga_x),
            .vga_y(vga_y)
        );
        
        

        //data memory
        wire [14:0] a, addr, display_addr, read_addr;
        wire [15:0] spo_2, dpo_2;
        wire [31:0] d, spo, dpo, spo_1, dpo_1;
        wire we, we_1, we_2;
        wire run_r;
        //assign addr = read_addr;
        assign addr = display_addr;
        assign spo = a < 15'h1f00 ? spo_1 : ( a > 15'h1f20 ? {16'b0, spo_2} : 32'heeeeeeee);
        //assign dpo = addr<15'h1f00 ? dpo_1 : (addr>15'h1f20 ? {16'b0, dpo_2} : 32'hdddddddd);
        assign dpo = dpo_1;
        assign we_1 = a < 15'h1f00 ? we : 0;
        assign we_2 = a > 15'h1f20 ? we : 0;

        wire clk_cpu;
//        dist_mem_gen_2 data_memory_1(//0-255 width = 32
//            .a(a[9:2]),
//            .d(d),
//            .dpra(addr[9:2]),
//            .spo(spo_1),
//            .dpo(dpo_1),
//            .clk(clk_cpu),// ???
//            .we(we_1)
//        );
        dist_mem_gen_3 data_memory_2(//addr >= 2000, 19200, width = 16
            .a(a-15'h2000),
            .d(d[15:0]),
            .dpra(addr),
            .spo(spo_2),
            .dpo(dpo_2),
            .clk(clk_cpu),//???
            .we(we_2)
        );
//        dist_mem_gen_1 data_memory(
//            .a(a),
//            .d(d),
//            .dpra(addr),
//            .spo(spo),
//            .dpo(dpo),
//            .clk(clk),
//            .we(we)
//        );
        assign display_addr = 160 * vga_y[8:2] + vga_x[9:2]; 
       
        //interrupt signal, PDU将外设信号处理成中断信号发???给CPU
        wire int_keyboard;
        wire int_btn;
        wire int_swt;

        //IO_BUS
        wire [7:0] io_addr;
        wire [31:0] io_dout;
        wire io_we;
        wire io_rd;
        wire [31:0] io_din;

        //Debug_BUS
        wire [31:0] chk_pc;    //连接CPU的npc
        wire [15:0] chk_addr;
        wire [31:0] chk_data; 

        wire rst_cpu_pdu,rst_cpu_cpu;
        wire x_p;
        assign rst_cpu_cpu = ~rst_cpu_pdu;
        
        wire kbd_state;
        pdu pdu(.clk(clk),.rstn(rstn),.step(step),.cont(cont),.chk(chk),.data(data),.del(del),.x(x),.stop(stop),
        .led(led),.an(an),.seg(seg),.seg_sel(seg_sel),.clk_cpu(clk_cpu),.rst_cpu(rst_cpu_pdu),.io_addr(io_addr),
        .io_dout(io_dout),.io_we(io_we),.io_rd(io_rd),.io_din(io_din),.chk_pc(chk_pc),.chk_addr(chk_addr),.chk_data(chk_data)
        ,.int_keyboard(int_keyboard),.int_btn(int_btn),.ps2_clk(ps2_clk),.ps2_data(ps2_data),.run_r(run_r),.kbd_state(kbd_state)
        ,.x_p(x_p));

        reg cpu_rdy;
        wire row, cpu_req_valid, cpu_ready;

        initial cpu_rdy = 1'b1;
        wire mclk_cpu;
        assign mclk_cpu = clk_cpu & cpu_rdy;
        cpu cpu(.clk(mclk_cpu),.rstn(rst_cpu_cpu),.io_addr(io_addr),.io_dout(io_dout),.io_we(io_we),
        .io_rd(io_rd),.io_din(io_din),.pc(chk_pc),.chk_addr(chk_addr),.chk_data(chk_data)
        ,.int_keyboard(int_keyboard),.int_btn(int_btn),.a(a),.d(d),.we(we),.spo(spo),.dpo(dpo),.read_addr(read_addr));

        always@(*) begin
            if(cpu_req_valid)
                cpu_rdy = 1'b0;
            else if(cpu_ready)
                cpu_rdy = 1'b1;
        end
        
        wire mem_req_addr, mem_req_row, mem_req_valid, mem_data_write, mem_data_read, mem_ready;
        assign cpu_req_valid = 1;
        assign row = we;
        cache Cache(
            .clk(clk),
            .rstn(rstn),
            // cpu<->cache
            .cpu_req_addr(a),
            .cpu_req_row(row),
            .cpu_req_valid(cpu_req_valid),
            .cpu_data_write(d),
            .cpu_data_read(spo),
            .cpu_ready(cpu_ready),
            // cache<->memory
            .mem_req_addr(mem_req_addr),
            .mem_req_row(mem_req_row),
            .mem_req_valid(mem_req_valid),
            .mem_data_write(mem_data_write),
            .mem_data_read(mem_data_read),
            .mem_ready(mem_ready)
        );
        
        mem Mem(
            .clk(clk),
            .rstn(rstn),
            // past data_mem
            .dpra(addr[9:2]),
            .dpo(dpo_1),
            // cache <-> memory
            .mem_req_addr(mem_req_addr),
            .mem_req_row(mem_req_row),
            .mem_req_valid(mem_req_valid),
            .mem_data_write(mem_data_write),
            .mem_data_read(mem_data_read),
            .mem_ready(mem_ready)
        );
    
        wire in;
        wire color_on_1, color_on_2;
        wire [11:0] bkg_color, bkg_color_1, bkg_color_2, bkg_color_3;
        background bkg(
            .clk(clk),
            .rstn(rstn),
            .clk_ram(pclk),
            .bounce(1'b0),
            .vga_x(vga_x),
            .vga_y(vga_y),
            .color(bkg_color_1)
        );
        
        title1 tt1(
            .clk(clk),
            .clk_ram(pclk),
            .vga_x(vga_x),
            .vga_y(vga_y),
            .color_on(color_on_1),
            .color(bkg_color_2)
        );
        
        title2 tt2(
            .clk(clk),
            .clk_ram(pclk),
            .vga_x(vga_x),
            .vga_y(vga_y),
            .color_on(color_on_2),
            .color(bkg_color_3)
        );
        
        assign bkg_color = color_on_1 ? bkg_color_2 : ( color_on_2 ? bkg_color_3 : bkg_color_1 );
        
        assign in = kbd_state | x_p | step | cont | data | chk | del;
        wire sig;
        second_counter(
            .clk(clk),
            .rstn(rstn),
            .in(in),
            .sig(sig)
        );
        
        assign prgb = display_en ? ( ~run_r ?  (sig ? bkg_color : dpo_2 ) : dpo_2 ) : 12'h000;
        
        assign AUD_SD = 1'b1;
        audio_output AUD(
            clk,
            AUD_PWM
        );
        
endmodule
