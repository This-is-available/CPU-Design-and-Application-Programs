`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/11 20:58:44
// Design Name: 
// Module Name: cpu
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


module  cpu (
  input clk, 
  input rstn,

  //interrupt
  input int_keyboard,//键盘中断产生
  input int_btn,//有按键按下时为1



  //IO_BUS
  output reg [7:0]  io_addr,	//外设地址   
  output reg [31:0]  io_dout,	//向外设输出的数据  
  output  reg io_we,		//向外设输出数据时的写使能信号  
  output  reg io_rd,		//从外设输入数据时的读使能信号
  input [31:0]  io_din,	//来自外设输入的数据

  //Debug_BUS
  output [31:0] pc, 	//当前执行指令地址
  input [15:0] chk_addr,	//数据通路状态的编码地址
  output reg [31:0] chk_data,    //数据通路状态的数据

  //data memory wires
  output [14:0] a,
  output reg [14:0] read_addr,
  output [31:0] d,
  output we,
  input  [31:0] spo, dpo
);

//分支历史
reg [1:0] BHT [31:0];

//中断原因
parameter KEYBOARD_INT = 1;//键盘
parameter BUTTON_INT   = 2;//按键
//parameter SWITCH_INT   = 3;//开关
parameter KEYBOARD_I_HIT = 8;//键盘输入了按键I

//interrupt return address
reg [31:0] addr_int_return;
reg [1:0] SCAUSE;
wire int_signal;
reg int_return;
assign int_signal = int_keyboard | int_btn;

//instruction wires
wire [31:0] instr;
reg [31:0] pc_r_next;
reg  [31:0] pc_r;
reg  and_in;
wire [4:0]rs1,rs2,rd;
reg [4:0] ra_debug;
wire [7:0]pc_readrf;
wire [6:0]opcode;
wire [2:0]funct3;
wire [6:0]funct7;
wire [31:0] imm_i,imm_s,imm_sb,imm_u,imm_uj;
reg  [31:0]imm_gen_out;

//register file wires
wire [31:0]read_data1,read_data2,rd_debug;
reg  [31:0] write_data;

//alu_ID wires
wire [2:0]alu_ID_mark;
wire [31:0]alu_ID_result, alu_ID_in2;
reg [31:0]alu_ID_in1, alu_ID_in2_in;
reg alu_ID_in2_sel;

//alu_EX wires
wire [31:0]alu_EX_in2,alu_result;//alu_EX_in2_in可能是ID_EX_Reg2，也可能是前递的数值
reg [31:0] alu_EX_in1,alu_EX_in2_in;

//data memory
//reg [7:0]data_mem_debug_a;
wire [31:0]data_mem_debug_d,read_data;

//control signals
reg RegWrite,MemRead,MemWrite,Branch,  ALUSrc,JalrEn,JalEn;
reg [2:0] AndMux;//取值决定于不同的分支跳转指令
reg [2:0] ALUOp;
reg [2:0] MemtoReg;
wire PCSrc;
reg Addr_Test;

//ID_EX register
reg [2:0]ID_EX_ALUOp,ID_EX_AndMux, ID_EX_MemtoReg;
reg ID_EX_RegWrite, ID_EX_MemRead,ID_EX_MemWrite,ID_EX_Branch,  ID_EX_ALUSrc,ID_EX_JalrEn,ID_EX_JalEn;
reg [4:0]ID_EX_rs1, ID_EX_rs2, ID_EX_rd;
reg [31:0]ID_EX_Reg1, ID_EX_Reg2, ID_EX_imm, ID_EX_pc,ID_EX_io_din,ID_EX_instr;
reg [6:0]ID_EX_funct7;
reg [2:0]ID_EX_funct3;

//ID_EX interrupt store register
reg [2:0]ID_EX_ALUOp_int,ID_EX_AndMux_int, ID_EX_MemtoReg_int;
reg ID_EX_RegWrite_int, ID_EX_MemRead_int,ID_EX_MemWrite_int,ID_EX_Branch_int,  ID_EX_ALUSrc_int,ID_EX_JalrEn_int,ID_EX_JalEn_int;
reg [4:0]ID_EX_rs1_int, ID_EX_rs2_int, ID_EX_rd_int;
reg [31:0]ID_EX_Reg1_int, ID_EX_Reg2_int, ID_EX_imm_int, ID_EX_pc_int,ID_EX_io_din_int,ID_EX_instr_int;
reg [6:0]ID_EX_funct7_int;
reg [2:0]ID_EX_funct3_int;

//IF_ID register
reg [31:0]IF_ID_pc, IF_ID_instr;

//IF_ID interrupt store register
reg [31:0]IF_ID_pc_int, IF_ID_instr_int;

//EX_MEM register
reg [2:0]EX_MEM_ALUOp,EX_MEM_AndMux, EX_MEM_MemtoReg;
reg EX_MEM_RegWrite, EX_MEM_MemRead,EX_MEM_MemWrite,EX_MEM_Branch,  EX_MEM_ALUSrc,EX_MEM_JalrEn,EX_MEM_JalEn;
reg [4:0]EX_MEM_rs1, EX_MEM_rs2, EX_MEM_rd;
reg [31:0]EX_MEM_Reg1, EX_MEM_Reg2, EX_MEM_imm, EX_MEM_alu_result, EX_MEM_alu_EX_in2, EX_MEM_pc,EX_MEM_io_din,EX_MEM_instr;
reg [6:0]EX_MEM_funct7;
reg [2:0]EX_MEM_funct3;

//EX_MEM interrupt store register
reg [2:0]EX_MEM_ALUOp_int,EX_MEM_AndMux_int, EX_MEM_MemtoReg_int;
reg EX_MEM_RegWrite_int, EX_MEM_MemRead_int,EX_MEM_MemWrite_int,EX_MEM_Branch_int,  EX_MEM_ALUSrc_int,EX_MEM_JalrEn_int,EX_MEM_JalEn_int;
reg [4:0]EX_MEM_rs1_int, EX_MEM_rs2_int, EX_MEM_rd_int;
reg [31:0]EX_MEM_Reg1_int, EX_MEM_Reg2_int, EX_MEM_imm_int, EX_MEM_alu_result_int, EX_MEM_alu_EX_in2_int, EX_MEM_pc_int,EX_MEM_io_din_int,EX_MEM_instr_int;
reg [6:0]EX_MEM_funct7_int;
reg [2:0]EX_MEM_funct3_int;


//MEM_WB register
reg [2:0]MEM_WB_ALUOp,MEM_WB_AndMux, MEM_WB_MemtoReg;
reg MEM_WB_RegWrite, MEM_WB_MemRead,MEM_WB_MemWrite,MEM_WB_Branch,  MEM_WB_ALUSrc,MEM_WB_JalrEn,MEM_WB_JalEn;
reg [4:0]MEM_WB_rs1, MEM_WB_rs2, MEM_WB_rd;
reg [31:0]MEM_WB_Reg1, MEM_WB_Reg2, MEM_WB_imm, MEM_WB_alu_result, MEM_WB_alu_EX_in2, MEM_WB_read_data, MEM_WB_pc,MEM_WB_instr;
reg [31:0]MEM_WB_io_din;

//MEM_WB interrupt store register
reg [2:0]MEM_WB_ALUOp_int,MEM_WB_AndMux_int, MEM_WB_MemtoReg_int;
reg MEM_WB_RegWrite_int, MEM_WB_MemRead_int,MEM_WB_MemWrite_int,MEM_WB_Branch_int,  MEM_WB_ALUSrc_int,MEM_WB_JalrEn_int,MEM_WB_JalEn_int;
reg [4:0]MEM_WB_rs1_int, MEM_WB_rs2_int, MEM_WB_rd_int;
reg [31:0]MEM_WB_Reg1_int, MEM_WB_Reg2_int, MEM_WB_imm_int, MEM_WB_alu_result_int, MEM_WB_alu_EX_in2_int, MEM_WB_read_data_int, MEM_WB_pc_int,MEM_WB_instr_int;
reg [31:0]MEM_WB_io_din_int;


//hazard detection unit
reg stall;
reg branch_error;
always@(*)//stall信号的产生
    begin
    if(ID_EX_MemRead==1&&(ID_EX_rd==rs1||ID_EX_rd==rs2))stall=1;
    else if((opcode==7'b1100011||Addr_Test==1)&&((ID_EX_rd==rs1&&rs1!=0)||(ID_EX_rd==rs2&&rs2!=0)))stall=1;//此处用opcode，不能用funct7！！！！！
    else if((opcode==7'b1100011||Addr_Test==1)&&((EX_MEM_rd==rs1&&rs1!=0)||(EX_MEM_rd==rs2&&rs2!=0))&&EX_MEM_MemRead==1)stall=1;
    else stall=0;
    end
wire IF_FLUSH;
wire PCWrite, IF_ID_Write, ID_EX_Mux;
assign IF_FLUSH = (  ((JalrEn==1)||((opcode==7'b1100011)&&(PCSrc ^ BHT[IF_ID_pc[4:0]][1])))  &&  (stall!=1)  ) ? 1 : 0;//((JalEn==1||JalrEn==1||PCSrc==1)&&stall!=1)?1:0;
//此处BHT[IF_ID_pc[4:0]][1]不要忘记加下标
assign IF_ID_Write=stall==1?0:1;
assign ID_EX_Mux=stall==1?0:1;
assign PCWrite=stall==1?0:1;

//BHT的更新
always@(posedge clk)begin       
    if(opcode == 7'b1100011)begin   //遇到条件分支指令时
        if( (PCSrc == 1) && (BHT[IF_ID_pc[4:0]] < 3) && (stall != 1) )  //发生跳转，则BHT对应地址的值加1   
            BHT[IF_ID_pc[4:0]] <= BHT[IF_ID_pc[4:0]] + 1;    
        else if( (PCSrc == 0) && (BHT[IF_ID_pc[4:0]] > 0) && (stall != 1) )  //不跳转，减1   
            BHT[IF_ID_pc[4:0]] <= BHT[IF_ID_pc[4:0]] - 1;
    end
end

//forwarding unit
reg [1:0]Forward_EX_A, Forward_EX_B, Forward_ID_A, Forward_ID_B;
always@(*)//前递信号生成
    begin
    Forward_EX_A=0; Forward_EX_B=0; Forward_ID_A=0; Forward_ID_B=0;
    //前递到EX阶段给ALU用于执行算术指令
    if(EX_MEM_RegWrite==1&&EX_MEM_rd!=0&&EX_MEM_rd==ID_EX_rs1)Forward_EX_A[1]=1;
    if(EX_MEM_RegWrite==1&&EX_MEM_rd!=0&&EX_MEM_rd==ID_EX_rs2)Forward_EX_B[1]=1;
    if(MEM_WB_RegWrite==1&&MEM_WB_rd!=0&&MEM_WB_rd==ID_EX_rs1)Forward_EX_A[0]=1;
    if(MEM_WB_RegWrite==1&&MEM_WB_rd!=0&&MEM_WB_rd==ID_EX_rs2)Forward_EX_B[0]=1;
    //前递到ID阶段给ALU用于判断分支是否发生
    if(EX_MEM_RegWrite==1&&EX_MEM_rd!=0&&EX_MEM_rd==rs1)Forward_ID_A[1]=1;
    if(EX_MEM_RegWrite==1&&EX_MEM_rd!=0&&EX_MEM_rd==rs2)Forward_ID_B[1]=1;
    if(MEM_WB_RegWrite==1&&MEM_WB_rd!=0&&MEM_WB_rd==rs1)Forward_ID_A[0]=1;
    if(MEM_WB_RegWrite==1&&MEM_WB_rd!=0&&MEM_WB_rd==rs2)Forward_ID_B[0]=1;
    end

always@(posedge clk or negedge rstn)//MEM_WB register
    begin 
    if(rstn==0||int_signal==1)
        begin
        MEM_WB_ALUOp=0;MEM_WB_AndMux=0; MEM_WB_MemtoReg=0;
        MEM_WB_RegWrite=0; MEM_WB_MemRead=0;MEM_WB_MemWrite=0;MEM_WB_Branch=0;
        MEM_WB_ALUSrc=0;MEM_WB_JalrEn=0;MEM_WB_JalEn=0;
        MEM_WB_rs1=0; MEM_WB_rs2=0; MEM_WB_rd=0;MEM_WB_instr=0;
        MEM_WB_Reg1=0; MEM_WB_Reg2=0; MEM_WB_imm=0;MEM_WB_pc=0;MEM_WB_io_din=0;MEM_WB_alu_result=0;
        end
    else if(MEM_WB_instr[6:0] == 7'b1111111)//从中断服务程序中返回
        begin
        MEM_WB_ALUOp=MEM_WB_ALUOp_int;MEM_WB_AndMux=MEM_WB_AndMux_int; MEM_WB_MemtoReg=MEM_WB_MemtoReg_int;
        MEM_WB_RegWrite=MEM_WB_RegWrite_int; MEM_WB_MemRead=MEM_WB_MemRead_int;MEM_WB_MemWrite=MEM_WB_MemWrite_int;MEM_WB_Branch=MEM_WB_Branch_int;
        MEM_WB_ALUSrc=MEM_WB_ALUSrc_int;MEM_WB_JalrEn=MEM_WB_JalrEn_int;MEM_WB_JalEn=MEM_WB_JalEn_int;
        MEM_WB_rs1=MEM_WB_rs1_int; MEM_WB_rs2=MEM_WB_rs2_int; MEM_WB_rd=MEM_WB_rd_int;MEM_WB_instr=MEM_WB_instr_int;
        MEM_WB_Reg1=MEM_WB_Reg1_int; MEM_WB_Reg2=MEM_WB_Reg2_int; MEM_WB_imm=MEM_WB_imm_int;
        MEM_WB_alu_result=MEM_WB_alu_result_int;MEM_WB_read_data=MEM_WB_read_data_int;MEM_WB_pc=MEM_WB_pc_int;MEM_WB_io_din=MEM_WB_io_din_int;
        end
    else 
        begin
        MEM_WB_ALUOp=EX_MEM_ALUOp;MEM_WB_AndMux=EX_MEM_AndMux; MEM_WB_MemtoReg=EX_MEM_MemtoReg;
        MEM_WB_RegWrite=EX_MEM_RegWrite; MEM_WB_MemRead=EX_MEM_MemRead;MEM_WB_MemWrite=EX_MEM_MemWrite;MEM_WB_Branch=EX_MEM_Branch;
        MEM_WB_ALUSrc=EX_MEM_ALUSrc;MEM_WB_JalrEn=EX_MEM_JalrEn;MEM_WB_JalEn=EX_MEM_JalEn;
        MEM_WB_rs1=EX_MEM_rs1; MEM_WB_rs2=EX_MEM_rs2; MEM_WB_rd=EX_MEM_rd;MEM_WB_instr=EX_MEM_instr;
        MEM_WB_Reg1=EX_MEM_Reg1; MEM_WB_Reg2=EX_MEM_Reg2; MEM_WB_imm=EX_MEM_imm;
        MEM_WB_alu_result=EX_MEM_alu_result;MEM_WB_read_data=read_data;MEM_WB_pc=EX_MEM_pc;MEM_WB_io_din=EX_MEM_io_din;
        end
    end

always@(posedge clk or negedge rstn)//MEM_WB interrupt store register
    begin 
    if(rstn==0)
        begin
        MEM_WB_ALUOp_int=0;MEM_WB_AndMux_int=0; MEM_WB_MemtoReg_int=0;
        MEM_WB_RegWrite_int=0; MEM_WB_MemRead_int=0;MEM_WB_MemWrite_int=0;MEM_WB_Branch_int=0;
        MEM_WB_ALUSrc_int=0;MEM_WB_JalrEn_int=0;MEM_WB_JalEn_int=0;
        MEM_WB_rs1_int=0; MEM_WB_rs2_int=0; MEM_WB_rd_int=0;MEM_WB_instr_int=0;
        MEM_WB_Reg1_int=0; MEM_WB_Reg2_int=0; MEM_WB_imm_int=0;MEM_WB_pc_int=0;MEM_WB_io_din_int=0;
        end
    else if(int_signal==1)
        begin
        MEM_WB_ALUOp_int=MEM_WB_ALUOp;MEM_WB_AndMux_int=MEM_WB_AndMux; MEM_WB_MemtoReg_int=MEM_WB_MemtoReg;
        MEM_WB_RegWrite_int=MEM_WB_RegWrite; MEM_WB_MemRead_int=MEM_WB_MemRead;MEM_WB_MemWrite_int=MEM_WB_MemWrite;MEM_WB_Branch_int=MEM_WB_Branch;
        MEM_WB_ALUSrc_int=MEM_WB_ALUSrc;MEM_WB_JalrEn_int=MEM_WB_JalrEn;MEM_WB_JalEn_int=MEM_WB_JalEn;
        MEM_WB_rs1_int=MEM_WB_rs1; MEM_WB_rs2_int=MEM_WB_rs2; MEM_WB_rd_int=MEM_WB_rd;MEM_WB_instr_int=MEM_WB_instr;
        MEM_WB_Reg1_int=MEM_WB_Reg1; MEM_WB_Reg2_int=MEM_WB_Reg2; MEM_WB_imm_int=MEM_WB_imm;
        MEM_WB_alu_result_int=MEM_WB_alu_result;MEM_WB_read_data_int=MEM_WB_read_data;MEM_WB_pc_int=MEM_WB_pc;MEM_WB_io_din_int=MEM_WB_io_din;
        end
    end


always@(posedge clk or negedge rstn)//EX_MEM register
    begin 
    if(rstn==0||int_signal==1)
        begin
        EX_MEM_ALUOp=0;EX_MEM_AndMux=0; EX_MEM_MemtoReg=0;
        EX_MEM_RegWrite=0; EX_MEM_MemRead=0;EX_MEM_MemWrite=0;EX_MEM_Branch=0;
        EX_MEM_ALUSrc=0;EX_MEM_JalrEn=0;EX_MEM_JalEn=0;
        EX_MEM_rs1=0; EX_MEM_rs2=0; EX_MEM_rd=0;EX_MEM_instr=0;
        EX_MEM_Reg1=0; EX_MEM_Reg2=0; EX_MEM_imm=0;EX_MEM_pc=0;EX_MEM_io_din=0;
        end
    else if(MEM_WB_instr[6:0] == 7'b1111111)//从中断程序中返回
        begin
        EX_MEM_ALUOp=EX_MEM_ALUOp_int;EX_MEM_AndMux=EX_MEM_AndMux_int; EX_MEM_MemtoReg=EX_MEM_MemtoReg_int;
        EX_MEM_RegWrite=EX_MEM_RegWrite_int; EX_MEM_MemRead=EX_MEM_MemRead_int;EX_MEM_MemWrite=EX_MEM_MemWrite_int;EX_MEM_Branch=EX_MEM_Branch_int;
        EX_MEM_ALUSrc=EX_MEM_ALUSrc_int;EX_MEM_JalrEn=EX_MEM_JalrEn_int;EX_MEM_JalEn=EX_MEM_JalEn_int;
        EX_MEM_rs1=EX_MEM_rs1_int; EX_MEM_rs2=EX_MEM_rs2_int; EX_MEM_rd=EX_MEM_rd_int;EX_MEM_instr=EX_MEM_instr_int;
        EX_MEM_Reg1=EX_MEM_Reg1_int; EX_MEM_Reg2=EX_MEM_Reg2_int; EX_MEM_imm=EX_MEM_imm_int;
        EX_MEM_alu_result=EX_MEM_alu_result_int;EX_MEM_alu_EX_in2=EX_MEM_alu_EX_in2_int;EX_MEM_pc=EX_MEM_pc_int;EX_MEM_io_din=EX_MEM_io_din_int;
        end
    else 
        begin
        EX_MEM_ALUOp=ID_EX_ALUOp;EX_MEM_AndMux=ID_EX_AndMux; EX_MEM_MemtoReg=ID_EX_MemtoReg;
        EX_MEM_RegWrite=ID_EX_RegWrite; EX_MEM_MemRead=ID_EX_MemRead;EX_MEM_MemWrite=ID_EX_MemWrite;EX_MEM_Branch=ID_EX_Branch;
        EX_MEM_ALUSrc=ID_EX_ALUSrc;EX_MEM_JalrEn=ID_EX_JalrEn;EX_MEM_JalEn=ID_EX_JalEn;
        EX_MEM_rs1=ID_EX_rs1; EX_MEM_rs2=ID_EX_rs2; EX_MEM_rd=ID_EX_rd;EX_MEM_instr=ID_EX_instr;
        EX_MEM_Reg1=ID_EX_Reg1; EX_MEM_Reg2=alu_EX_in2_in; EX_MEM_imm=ID_EX_imm;
        EX_MEM_alu_result=alu_result;EX_MEM_alu_EX_in2=alu_EX_in2;EX_MEM_pc=ID_EX_pc;EX_MEM_io_din=ID_EX_io_din;
        end
    end

always@(posedge clk or negedge rstn)//EX_MEM interrupt store register
    begin 
    if(rstn==0)
        begin
        EX_MEM_ALUOp_int=0;EX_MEM_AndMux_int=0; EX_MEM_MemtoReg_int=0;
        EX_MEM_RegWrite_int=0; EX_MEM_MemRead_int=0;EX_MEM_MemWrite_int=0;EX_MEM_Branch_int=0;
        EX_MEM_ALUSrc_int=0;EX_MEM_JalrEn_int=0;EX_MEM_JalEn_int=0;
        EX_MEM_rs1_int=0; EX_MEM_rs2_int=0; EX_MEM_rd_int=0;EX_MEM_instr_int=0;
        EX_MEM_Reg1_int=0; EX_MEM_Reg2_int=0; EX_MEM_imm_int=0;EX_MEM_pc_int=0;EX_MEM_io_din_int=0;
        end
    else if(int_signal==1)
        begin
        EX_MEM_ALUOp_int=EX_MEM_ALUOp;EX_MEM_AndMux_int=EX_MEM_AndMux; EX_MEM_MemtoReg_int=EX_MEM_MemtoReg;
        EX_MEM_RegWrite_int=EX_MEM_RegWrite; EX_MEM_MemRead_int=EX_MEM_MemRead;EX_MEM_MemWrite_int=EX_MEM_MemWrite;EX_MEM_Branch_int=EX_MEM_Branch;
        EX_MEM_ALUSrc_int=EX_MEM_ALUSrc;EX_MEM_JalrEn_int=EX_MEM_JalrEn;EX_MEM_JalEn_int=EX_MEM_JalEn;
        EX_MEM_rs1_int=EX_MEM_rs1; EX_MEM_rs2_int=EX_MEM_rs2; EX_MEM_rd_int=EX_MEM_rd;EX_MEM_instr_int=EX_MEM_instr;
        EX_MEM_Reg1_int=EX_MEM_Reg1; EX_MEM_Reg2_int=EX_MEM_Reg2; EX_MEM_imm_int=EX_MEM_imm;
        EX_MEM_alu_result_int=EX_MEM_alu_result;EX_MEM_alu_EX_in2_int=EX_MEM_alu_EX_in2;EX_MEM_pc_int=EX_MEM_pc;EX_MEM_io_din_int=EX_MEM_io_din;
        end
    end

always@(posedge clk or negedge rstn)//ID_EX register
    begin
    if(rstn==0||int_signal==1)
        begin
        ID_EX_ALUOp=0;ID_EX_AndMux=0; ID_EX_MemtoReg=0;
        ID_EX_RegWrite=0; ID_EX_MemRead=0;ID_EX_MemWrite=0;ID_EX_Branch=0;
        ID_EX_ALUSrc=0;ID_EX_JalrEn=0;ID_EX_JalEn=0;
        ID_EX_rs1=0; ID_EX_rs2=0; ID_EX_rd=0;ID_EX_instr=0;
        ID_EX_Reg1=0; ID_EX_Reg2=0; ID_EX_imm=0;ID_EX_pc=0;ID_EX_io_din=0;
        end
    else if(MEM_WB_instr[6:0] == 7'b1111111)//从中断处理程序中返回
        begin
        ID_EX_ALUOp=ID_EX_ALUOp_int;ID_EX_AndMux=ID_EX_AndMux_int; ID_EX_MemtoReg=ID_EX_MemtoReg_int;
        ID_EX_RegWrite=ID_EX_RegWrite_int; ID_EX_MemRead=ID_EX_MemRead_int;ID_EX_MemWrite=ID_EX_MemWrite_int;ID_EX_Branch=ID_EX_Branch_int;
        ID_EX_ALUSrc=ID_EX_ALUSrc_int;ID_EX_JalrEn=ID_EX_JalrEn_int;ID_EX_JalEn=ID_EX_JalEn_int;
        ID_EX_rs1=ID_EX_rs1_int; ID_EX_rs2=ID_EX_rs2_int; ID_EX_rd=ID_EX_rd_int;ID_EX_instr=ID_EX_instr_int;
        ID_EX_Reg1=ID_EX_Reg1_int; ID_EX_Reg2=ID_EX_Reg2_int; ID_EX_imm=ID_EX_imm_int;ID_EX_pc=ID_EX_pc_int;ID_EX_io_din=ID_EX_io_din_int;
        end
    else if(ID_EX_Mux==0)
        begin
        ID_EX_ALUOp=0;ID_EX_AndMux=0; ID_EX_MemtoReg=0;
        ID_EX_RegWrite=0; ID_EX_MemRead=0;ID_EX_MemWrite=0;ID_EX_Branch=0;
        ID_EX_ALUSrc=0;ID_EX_JalrEn=0;ID_EX_JalEn=0;
        ID_EX_rs1=0; ID_EX_rs2=0; ID_EX_rd=0;ID_EX_instr=0;
        ID_EX_Reg1=0; ID_EX_Reg2=0; ID_EX_imm=0;ID_EX_pc=0;ID_EX_io_din=0;
        end
    else
        begin
        ID_EX_ALUOp=ALUOp;ID_EX_AndMux=AndMux; ID_EX_MemtoReg=MemtoReg;
        ID_EX_RegWrite=RegWrite; ID_EX_MemRead=MemRead;ID_EX_MemWrite=MemWrite;ID_EX_Branch=Branch;
        ID_EX_ALUSrc=ALUSrc;ID_EX_JalrEn=JalrEn;ID_EX_JalEn=JalEn;
        ID_EX_rs1=rs1; ID_EX_rs2=rs2; ID_EX_rd=rd;ID_EX_instr=IF_ID_instr;
        ID_EX_Reg1=read_data1; ID_EX_Reg2=read_data2; ID_EX_imm=imm_gen_out;ID_EX_pc=IF_ID_pc;ID_EX_io_din=io_din;
        end
    end

always@(posedge clk or negedge rstn)//ID_EX interrupt store register
    begin
    if(rstn==0)
        begin
        ID_EX_ALUOp_int=0;ID_EX_AndMux_int=0; ID_EX_MemtoReg_int=0;
        ID_EX_RegWrite_int=0; ID_EX_MemRead_int=0;ID_EX_MemWrite_int=0;ID_EX_Branch_int=0;
        ID_EX_ALUSrc_int=0;ID_EX_JalrEn_int=0;ID_EX_JalEn_int=0;
        ID_EX_rs1_int=0; ID_EX_rs2_int=0; ID_EX_rd_int=0;ID_EX_instr_int=0;
        ID_EX_Reg1_int=0; ID_EX_Reg2_int=0; ID_EX_imm_int=0;ID_EX_pc_int=0;ID_EX_io_din_int=0;
        end
    else if(int_signal==1)
        begin
        ID_EX_ALUOp_int=ID_EX_ALUOp;ID_EX_AndMux_int=ID_EX_AndMux; ID_EX_MemtoReg_int=ID_EX_MemtoReg;
        ID_EX_RegWrite_int=ID_EX_RegWrite; ID_EX_MemRead_int=ID_EX_MemRead;ID_EX_MemWrite_int=ID_EX_MemWrite;ID_EX_Branch_int=ID_EX_Branch;
        ID_EX_ALUSrc_int=ID_EX_ALUSrc;ID_EX_JalrEn_int=ID_EX_JalrEn;ID_EX_JalEn_int=ID_EX_JalEn;
        ID_EX_rs1_int=ID_EX_rs1; ID_EX_rs2_int=ID_EX_rs2; ID_EX_rd_int=ID_EX_rd;ID_EX_instr_int=ID_EX_instr;
        ID_EX_Reg1_int=ID_EX_Reg1; ID_EX_Reg2_int=ID_EX_Reg2; ID_EX_imm_int=ID_EX_imm;ID_EX_pc_int=ID_EX_pc;ID_EX_io_din_int=ID_EX_io_din;
        end
    end

always@(posedge clk or negedge rstn)//IF_ID register
    begin
    if(rstn==0||int_signal==1)//||opcode==7'b1111111||ID_EX_instr[6:0]==7'b1111111||EX_MEM_instr[6:0]==7'b1111111)
        begin
        IF_ID_pc=0;IF_ID_instr=0;
        end
    else if(MEM_WB_instr[6:0] == 7'b1111111)
        begin
        IF_ID_pc=IF_ID_pc_int;
        IF_ID_instr=IF_ID_instr_int;
        end
    else if(IF_FLUSH==1)
        begin
        IF_ID_pc=0;IF_ID_instr=0;
        end
    else if(IF_ID_Write!=0)
        begin
        IF_ID_pc=pc_r;
        IF_ID_instr=instr;
        end
    end

always@(posedge clk or negedge rstn)//IF_ID interrupt store register
    begin
    if(rstn==0)
        begin
        IF_ID_pc_int=0;IF_ID_instr_int=0;
        end
    else if(int_signal==1)
        begin 
        IF_ID_pc_int=IF_ID_pc;
        IF_ID_instr_int=IF_ID_instr;
        end
    end

always@(posedge clk or negedge rstn)//PC register and addr_int_return register
    begin
    if(rstn==0)
        begin
        pc_r = 0;
        end
    else if(int_signal==1)      //中断，转到对应处理程序
        begin
        addr_int_return = pc_r;     //将返回地址存入 addr_int_return 中
        pc_r = int_keyboard == 1 ? 32'h3c : (int_btn == 1? 32'h244 : 32'h94);    //选择对应的中断处理程序起始地址
        SCAUSE = int_keyboard == 1 ? KEYBOARD_INT : (int_btn == 1 ? BUTTON_INT : 1'b0);    //保存中断原因
        end 
    else if(MEM_WB_instr[6:0] == 7'b1111111) pc_r = addr_int_return;    //当ret指令运行到WB阶段时，返回主程序
    else if(PCWrite==1) pc_r = pc_r_next;   //没有中断的情况
    end


assign pc_readrf = pc_r[9:2];   //除以4之后取低8位
assign rs1 = IF_ID_instr[19:15];
assign rs2 = IF_ID_instr[24:20];
assign rd  = IF_ID_instr[11:7];
assign opcode = IF_ID_instr[6:0];
assign funct3 = IF_ID_instr[14:12];
assign funct7 = IF_ID_instr[31:25];
assign imm_i  = {{20{IF_ID_instr[31]}},IF_ID_instr[31:20]};
assign imm_s  = {{20{IF_ID_instr[31]}},IF_ID_instr[31:25],IF_ID_instr[11:7]};
assign imm_sb = {{20{IF_ID_instr[31]}},IF_ID_instr[31],IF_ID_instr[7],IF_ID_instr[30:25],IF_ID_instr[11:8]};
assign imm_u  = {1'b0,IF_ID_instr[31:12],11'b0};
assign imm_uj = {{12{IF_ID_instr[31]}},IF_ID_instr[31],IF_ID_instr[19:12],IF_ID_instr[20],IF_ID_instr[30:21]};

assign alu_EX_in2 = ID_EX_ALUSrc==0?alu_EX_in2_in:ID_EX_imm;      //与门输入信号选择，用ID_EX阶段的ALUSrc！！！
assign alu_ID_in2 = alu_ID_in2_sel==0?alu_ID_in2_in:imm_gen_out; 
//assign pc_r_next = rstn==0?0:(JalrEn==0?(PCSrc==0?(pc_r+4):(IF_ID_pc+(imm_gen_out<<1))):alu_ID_result);//选择下一条PC信号

//分支预测错误信号
wire error_should_branch, error_should_not_branch;   

//本该跳转
assign error_should_branch = (opcode == 7'b1100011) && (PCSrc == 1) && (BHT[IF_ID_pc[4:0]][1] == 0) && (stall != 1); 

//本不应该跳转
assign error_should_not_branch = (opcode == 7'b1100011)  && (PCSrc == 0) && (BHT[IF_ID_pc[4:0]][1] == 1) && (stall != 1);

//下一条PC的选择
always@(*)begin     
    if(error_should_branch == 1 && stall != 1)      //之前的分支预测错误，本应该该跳转
        pc_r_next = IF_ID_pc + (imm_gen_out<<1);
    else if(error_should_not_branch == 1 && stall != 1)     //之前的分支预测错误，本不应该跳转
        pc_r_next = IF_ID_pc + 4;
    else if(JalrEn == 1)        //Jalr
        pc_r_next = alu_ID_result;
    else if(instr[6:0] == 7'b1101111)       //jal
        pc_r_next = pc_r + ({{12{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21]} << 1);
    else if(instr[6:0] == 7'b1100011)begin      //IF阶段取出条件分支
        if(BHT[pc_r[4:0]][1] == 1)      //BHT高位为1，则预测跳转
            pc_r_next = pc_r + ({{20{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8]} << 1);
        else pc_r_next = pc_r + 4;       //高位为0，预测不跳转 
    end
    else pc_r_next = pc_r + 4;           //其他情况，PC正常加4
end

assign pc = pc_r;//当前执行的指令定义??????
assign PCSrc = Branch & and_in;//PCSrc选择

always@(*)//EX阶段ALU第一个输入选择
    begin
    if(Forward_EX_A[1]==1)
        begin
        if(EX_MEM_JalrEn==0&&EX_MEM_JalEn==0)
            case(EX_MEM_MemtoReg)
                0:alu_EX_in1=EX_MEM_alu_result;
                3:alu_EX_in1={EX_MEM_imm[30:11],12'b0};//lui
                4:alu_EX_in1=EX_MEM_io_din;
                5:alu_EX_in1=EX_MEM_pc + (EX_MEM_imm<<1);//auipc
                default:alu_EX_in1=EX_MEM_alu_result;
            endcase
        else alu_EX_in1=EX_MEM_pc+4;
        end
    else if(Forward_EX_A[0]==1)
        begin
        alu_EX_in1=write_data;
        end
    else alu_EX_in1=ID_EX_Reg1;
    end

always@(*)//EX阶段ALU第二个输入端口的寄存器输入信号选择
    begin
    if(Forward_EX_B[1]==1)
        begin
        if(EX_MEM_JalrEn==0&&EX_MEM_JalEn==0)
            case(EX_MEM_MemtoReg)
                0:alu_EX_in2_in=EX_MEM_alu_result;
                3:alu_EX_in2_in={EX_MEM_imm[30:11],12'b0};//lui
                4:alu_EX_in2_in=EX_MEM_io_din;
                5:alu_EX_in2_in=EX_MEM_pc + (EX_MEM_imm<<1);//auipc
                default:alu_EX_in2_in=EX_MEM_alu_result;
            endcase
        else alu_EX_in2_in=EX_MEM_pc+4;
        end
    else if(Forward_EX_B[0]==1)
        begin
        alu_EX_in2_in=write_data;
        end
    else alu_EX_in2_in=ID_EX_Reg2;
    end

always@(*)//ID阶段ALU第一个输入选择
    begin
    if(Forward_ID_A[1]==1)
        begin
        if(EX_MEM_JalrEn==0&&EX_MEM_JalEn==0)
            case(EX_MEM_MemtoReg)
                0:alu_ID_in1=EX_MEM_alu_result;
                3:alu_ID_in1={EX_MEM_imm[30:11],12'b0};//lui
                4:alu_ID_in1=EX_MEM_io_din;//外设写入
                5:alu_ID_in1=EX_MEM_pc + (EX_MEM_imm<<1);//auipc
                default:alu_ID_in1=EX_MEM_alu_result;
            endcase
        else alu_ID_in1=EX_MEM_pc+4;
        end
    else if(Forward_ID_A[0]==1)
        begin
        alu_ID_in1=write_data;
        end
    else alu_ID_in1=read_data1;
    end

always@(*)//ID阶段ALU第二个输入端口的寄存器输入信号选择
    begin
    if(JalrEn==1||Addr_Test==1)alu_ID_in2_sel = 1;
    else alu_ID_in2_sel = 0;
    if(Forward_ID_B[1]==1)
        begin
        if(EX_MEM_JalrEn==0&&EX_MEM_JalEn==0)
            case(EX_MEM_MemtoReg)
                0:alu_ID_in2_in=EX_MEM_alu_result;
                3:alu_ID_in2_in={EX_MEM_imm[30:11],12'b0};//lui
                4:alu_ID_in2_in=EX_MEM_io_din;//外设写入
                5:alu_ID_in2_in=EX_MEM_pc + (EX_MEM_imm<<1);//auipc
                default:alu_ID_in2_in=EX_MEM_alu_result;
        endcase
        else alu_ID_in2_in= EX_MEM_pc+4;
        end
    else if(Forward_ID_B[0]==1)
        begin
        alu_ID_in2_in=write_data;
        end
    else alu_ID_in2_in=read_data2;
    end


alu alu_ID(.a(alu_ID_in1),.b(alu_ID_in2),.s(3'b1),.y(alu_ID_result),.f(alu_ID_mark));//用于判断是否要发生跳转的ALU
alu alu_EX(.a(alu_EX_in1),.b(alu_EX_in2),.s(ID_EX_ALUOp),.y(alu_result),.f());//用于计算的ALU
dist_mem_gen_0 instruction_memory(.a(pc_readrf),.d(0),.dpra(5'b0),.spo(instr),.dpo(),.clk(clk),.we(0));
rf rf(.clk(clk),.ra0(rs1),.ra1(rs2),.rd0(read_data1),.rd1(read_data2),.wa(MEM_WB_rd),.wd(write_data),.we(MEM_WB_RegWrite),.ra_debug(ra_debug),.rd_debug(rd_debug));
//rf 中的write_data已经处理过，没问题


always@(*)//debug
    begin
    read_addr = chk_addr;//读数据存储器
    ra_debug = chk_addr[4:0];//读寄存器堆
    if(chk_addr[15:12]==0)//00xx    pcs
        case(chk_addr[7:0])
            0:chk_data = pc_r_next;//pcin
            1:chk_data = pc;//pc
            2:chk_data = IF_ID_pc;//pcd
            3:chk_data = IF_ID_instr;//ir
            4:chk_data = {int_signal,Addr_Test,JalrEn,ID_EX_Mux, Forward_ID_A,Forward_ID_B, Forward_EX_A,Forward_EX_B,  IF_FLUSH,stall,PCWrite,IF_ID_Write,  MemRead,MemWrite,Branch,PCSrc,  RegWrite,MemtoReg,  ALUSrc,ALUOp,  JalEn,AndMux};
            //ctrl
            5:chk_data = ID_EX_pc;//pce
            6:chk_data = alu_EX_in1;//a
            7:chk_data = alu_EX_in2_in;//b
            8:chk_data = imm_gen_out;//imm
            9:chk_data = ID_EX_instr;//ire
            10:chk_data= {EX_MEM_MemRead,EX_MEM_MemWrite,EX_MEM_Branch,PCSrc,  EX_MEM_RegWrite,EX_MEM_MemtoReg,  EX_MEM_ALUSrc,EX_MEM_ALUOp,  EX_MEM_JalEn,EX_MEM_AndMux};
            //ctrlm
            11:chk_data= alu_result;//y
            12:chk_data= EX_MEM_Reg2;//mdw
            13:chk_data= EX_MEM_instr;//irm
            14:chk_data= {MEM_WB_MemRead,MEM_WB_MemWrite,MEM_WB_Branch,PCSrc,  MEM_WB_RegWrite,MEM_WB_MemtoReg,  MEM_WB_ALUSrc,MEM_WB_ALUOp,  MEM_WB_JalEn,MEM_WB_AndMux};
            //ctrlw
            15:chk_data= read_data;//mdr
            16:chk_data= write_data;//yw
            17:chk_data= MEM_WB_instr;//irw
            18:chk_data= {rs1,rs2,rd,ID_EX_rd,EX_MEM_rd,MEM_WB_rd};
            19:chk_data= funct7;
            20:chk_data= pc_r_next;
            21:chk_data= pc_r;
            22:chk_data= IF_ID_pc;
            23:chk_data= ID_EX_pc;
            24:chk_data= EX_MEM_pc;
            25:chk_data= MEM_WB_pc;
            26:chk_data= alu_ID_in1;
            27:chk_data= alu_ID_in2;
            28:chk_data= alu_ID_result;
            29:chk_data= alu_ID_mark;
            30:chk_data= io_dout;
            31:chk_data= io_din;
            32:chk_data= io_addr;
            33:chk_data= io_we;
            34:chk_data= io_rd;
            35:chk_data= MEM_WB_io_din;
            36:chk_data= addr_int_return;
            37:chk_data= IF_ID_pc_int;
            38:chk_data= IF_ID_instr_int;
            39:chk_data= ID_EX_pc_int;
            40:chk_data= ID_EX_instr_int;
            41:chk_data= EX_MEM_pc_int;
            42:chk_data= EX_MEM_instr_int;
            43:chk_data= MEM_WB_pc_int;
            44:chk_data= MEM_WB_instr_int;
            45:chk_data= SCAUSE;
            46:chk_data= {{20{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8]} << 1;
            47:chk_data= error_should_branch;
            48:chk_data= error_should_not_branch;
            49:chk_data= {BHT[7],BHT[6],BHT[5],BHT[4],BHT[3],BHT[2],BHT[1],BHT[0]};
            50:chk_data= {BHT[15],BHT[14],BHT[13],BHT[12],BHT[11],BHT[10],BHT[9],BHT[8]};
            51:chk_data= {BHT[23],BHT[22],BHT[21],BHT[20],BHT[19],BHT[18],BHT[17],BHT[16]};
            52:chk_data= {BHT[31],BHT[30],BHT[29],BHT[28],BHT[27],BHT[26],BHT[25],BHT[24]};
            53:chk_data= {{12{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21]} << 1;
            54:chk_data= instr;
            default:chk_data = 16'hdddd;
        endcase
    else if(chk_addr[15:12]==1)//10yy  RF
            begin
//            ra_debug = chk_addr[4:0];
            chk_data = rd_debug;
            end
    else if(chk_addr[15:12]==2)//2zzz  DM
            begin
            //data_mem_debug_a = chk_addr[9:2];
            chk_data = dpo;
            end
    else
            chk_data = 16'heeee;
    end

always@(*)//根据分支指令种类选择ALU标志位
    begin
    case(AndMux)
        0:and_in = alu_ID_mark[0];     //beq
        1:and_in = alu_ID_mark[1];     //blt
        2:and_in = alu_ID_mark[2];     //bltu
        3:and_in = ~alu_ID_mark[0];    //bne
        4:and_in = ~alu_ID_mark[1];    //bge
        5:and_in = ~alu_ID_mark[2];    //bgeu
        6:and_in = 1'b0;
        default:and_in = 1'b1;
    endcase
    end

always@(*)//写回寄存器信号选择
    begin
    if(MEM_WB_JalrEn==0&&MEM_WB_JalEn==0)
        case(MEM_WB_MemtoReg)
            0: write_data = MEM_WB_alu_result;
            1: write_data = MEM_WB_read_data;
            2: write_data = {{24{MEM_WB_read_data[7]}},MEM_WB_read_data[7:0]};//lb
            3: write_data = {MEM_WB_imm[30:11],12'b0};//lui
            4: write_data = MEM_WB_io_din;
            5: write_data = MEM_WB_pc + (MEM_WB_imm<<1);//auipc
            default: write_data = MEM_WB_alu_result;
        endcase
    else write_data = MEM_WB_pc + 4;
    end

//译码
always@(IF_ID_instr)
    begin
    RegWrite=0;MemtoReg=0;MemRead=0;MemWrite=0;Branch=0;ALUSrc=0;AndMux=0;
    ALUOp=1;JalrEn=0;JalEn=0;imm_gen_out=imm_i;
    io_addr=0;io_rd=0;io_we=0;io_dout=0;Addr_Test=0;
    int_return = 0;
    case(opcode)
        7'b0110011:     //R type
            begin
            case({funct3,funct7}) 
                10'b0000000000:ALUOp = 1;   //add
                10'b0000100000:ALUOp = 0;   //sub
                10'b0010000000:ALUOp = 6;   //sll
                10'b1000000000:ALUOp = 4;   //xor
                10'b1010000000:ALUOp = 5;   //srl
                10'b1010100000:ALUOp = 7;   //sra
                10'b1100000000:ALUOp = 3;   //or
                10'b1110000000:ALUOp = 2;   //and
                default:ALUOp = 0;
            endcase
            RegWrite=1;
            end
        7'b0000011:     //lb, lw
            begin
            MemRead=1;
            case(funct3)
                3'b000://lb
                    begin
                    imm_gen_out = imm_i;
                    ALUSrc = 1;
                    MemtoReg = 2;
                    RegWrite = 1;
                    end
                3'b010://lw
                    begin
                    imm_gen_out = imm_i;
                    ALUSrc = 1;Addr_Test=1;
                    if(alu_ID_result>32'h1f20||alu_ID_result<32'h1f00)
                        begin 
                        MemtoReg = 1;
                        RegWrite = 1;
                        end
                    else    //read from I/O devices
                        begin
                        io_addr = alu_ID_result;//alu_result[7:0];使用ID阶段的alu结果作为地址读取外设，之前误用了EX阶段的alu
                        io_rd = 1;
                        MemtoReg = 4;
                        RegWrite = 1;
                        end
                    end
            endcase
            end
        7'b0010011:          
            begin
            case(funct3)
                3'b000://addi
                    begin
                    imm_gen_out = imm_i;
                    ALUSrc = 1;
                    RegWrite = 1;
                    end
                3'b001://slli
                    begin
                    imm_gen_out = {26'b0,imm_i[5:0]};
                    ALUSrc = 1;
                    ALUOp = 6;
                    RegWrite = 1;
                    end
                3'b100://xori
                    begin
                    imm_gen_out = imm_i;
                    ALUSrc = 1;
                    ALUOp = 4;
                    RegWrite = 1;
                    end
                3'b101://srli, srai
                    begin
                    imm_gen_out = {26'b0,imm_i[5:0]};
                    ALUSrc = 1;
                    ALUOp = funct7==7'b0000000 ? 3'h5 : 3'h7;
                    RegWrite = 1;
                    end
                3'b110://ori
                    begin
                    imm_gen_out = imm_i;
                    ALUSrc = 1;
                    ALUOp = 3;
                    RegWrite = 1;
                    end
                3'b111://andi
                    begin
                    imm_gen_out = imm_i;
                    ALUSrc = 1;
                    ALUOp = 2;
                    RegWrite = 1;
                    end
                default:;
            endcase
            end
        7'b1100111:              
            if(funct3==3'b000)//jalr
                begin
                JalrEn = 1;
                RegWrite = 1;
                imm_gen_out = imm_i;
                ALUSrc = 1;
                end
            else ;
        7'b0100011:     //S type         
            begin
            case(funct3)
                3'b010://sw
                    begin
                    imm_gen_out = imm_s;
                    ALUSrc = 1;Addr_Test=1;
                    if(alu_ID_result>32'h1f20||alu_ID_result<32'h1f00)
                        MemWrite = 1;
                    else
                        begin
                        io_dout = alu_ID_in2_in;//可能有前递，所以此处改为alu_ID_in2
                        io_addr = alu_ID_result;//alu_result;之前误用了EX阶段的alu
                        io_we = 1;
                        end
                    end
                default:;
            endcase
            end
        7'b1100011:     //SB type         
            begin
            case(funct3)
                3'b000://beq
                    begin
                    imm_gen_out = imm_sb;
                    Branch = 1;
                    //ALUOp = 0;
                    AndMux = 0;
                    end
                3'b001://bne
                    begin
                    imm_gen_out = imm_sb;
                    Branch = 1;
                    //ALUOp = 0;
                    AndMux = 3;
                    end
                3'b100://blt
                    begin
                    imm_gen_out = imm_sb;
                    Branch = 1;
                    //ALUOp = 0;
                    AndMux = 1;
                    end
                3'b101://bge
                    begin
                    imm_gen_out = imm_sb;
                    Branch = 1;
                    //ALUOp = 0;
                    AndMux = 4;
                    end
                3'b110://bltu
                    begin
                    imm_gen_out = imm_sb;
                    Branch = 1;
                    //ALUOp = 0;
                    AndMux = 2;
                    end
                3'b111://bgeu
                    begin
                    imm_gen_out = imm_sb;
                    Branch = 1;
                    //ALUOp = 0;
                    AndMux = 5;
                    end
                default:;
            endcase
            end
        7'b0010111:     //auipc        
            begin
            imm_gen_out = imm_u;
            MemtoReg = 5;
            RegWrite = 1;
            end
        7'b1101111:     //jal       
            begin
            //Branch = 1;
            JalEn = 1;
            //AndMux = 7;
            imm_gen_out = imm_uj;
            RegWrite = 1;
            end
        7'b0110111:     //lui
            begin
            imm_gen_out = imm_u;
            MemtoReg = 3;
            RegWrite = 1;
            end
        7'b1111111:     //ret 自定义指令，从中断处理程序返回
            begin
            int_return = 1;
            end
        default:;
    endcase
    end

assign a = EX_MEM_alu_result[14:0];
assign d = EX_MEM_Reg2;
assign read_data = spo;
assign we = EX_MEM_MemWrite;


endmodule
