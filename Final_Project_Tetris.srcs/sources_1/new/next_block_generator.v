`timescale 1ns / 1ps
module Many_To_One_LFSR(clk, reset,continue, random_seed,out);
input clk;
input reset;
input continue;
input [8-1:0] random_seed;
output reg out;
reg [8-1:0]DFF,next_DFF;
always@(posedge clk)
begin
    if(reset)
    DFF[7:0]<= random_seed;
    else
    DFF[7:0]<=next_DFF[7:0];
end

always@(*)
begin
    if(continue)
    begin
    next_DFF[7:1]=DFF[6:0];
    next_DFF[0]=(DFF[1]^DFF[2])^(DFF[3]^DFF[7]);
    out=DFF[7];
    end
    else
    begin
    next_DFF=DFF;
    out=DFF[7];
    end
end

endmodule

module next_block_gen(clk,reset,continue,random_seed,out,act);
input clk;
input reset;
input continue;
input [8-1:0] random_seed;
output [3-1:0] out;
output reg act;
reg [7-1:0]appear,next_appear;
reg [2:0]p,next_p;
wire LFSR_out;

Many_To_One_LFSR lfsr(clk,reset,continue,random_seed,LFSR_out);

always@(posedge clk)
begin
    if(reset)
    begin
        appear<=7'b0000000;
        p<=3'b000;
    end
    else
    begin
        appear<=next_appear;
        p<=next_p;
    end
end
assign out=p;
always@(*)
begin
    if(continue)
    next_p[2:0]={p[1:0],LFSR_out};
    else
    next_p=p;
    next_appear=appear;
    act=0;
    if(continue&p<3'd7)
    begin
        if(appear[p]==1'b0)
        begin
             next_appear[p]=1'b1;
             act=1'b1;
        end
    end
    if(((appear[0]&appear[1])&(appear[2]&appear[3]))&((appear[4]&appear[5])&appear[6]))
        next_appear=7'b0000000;
end
endmodule

//module next_block_gen2(clk,reset,continue,random_seed,out);
//input clk;
//input reset;
//input continue;
//input [3*7-1:0] random_seed;
//output [3-1:0] out;
//reg [3*7-1:0]arr,next_arr;
//reg [3*7-1:0]swap,next_swap;
//wire LFSR_out;

//Many_To_One_LFSR lfsr(clk,reset,continue,random_seed,LFSR_out);

//endmodule