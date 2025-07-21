`timescale 1ns / 1ps


module test;
    reg clk=0;
    reg reset=0;
    reg continue=1;
    reg [8-1:0]random_seed=8'b10111101;
    wire [2:0]out;
    wire act;
    next_block_gen nbg(clk,reset,continue,random_seed,out,act);
    parameter cyc=10;
    always #(cyc/2) clk=!clk;
    initial
    begin
        @(negedge clk);
        reset=1;
        #cyc;
        reset=0;
        repeat(10)
        begin
        #cyc;
        if(act)
            $display(out);
        end
        continue=0;
        repeat(10)
        begin
        #cyc;
        if(act)
            $display(out);
        end
        continue=1;
        repeat(10)
        begin
        #cyc;
        if(act)
            $display(out);
        end
        
        $finish;
    end
endmodule
