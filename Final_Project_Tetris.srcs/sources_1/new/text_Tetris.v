`timescale 1ns / 1ps


module test_Tetris;
    reg clk=0;
    reg reset=0;
    reg [8-1:0]random_seed=8'b10110101;
    integer seed=20;
    reg [3-1:0]keyboard_state=3'd0;
    wire [4*6-1:0] next;
    wire end_signal;
    wire [3:0]fallingblock_out;
    wire [4*10*20-1:0]stacking_array_out;
    integer i,ii,step=0,ran;
    Tetris T(.clk(clk),.reset(reset),.random_seed(random_seed),.keyboard_state(keyboard_state),.next(next),.end_signal(end_signal),.stacking_array_out(stacking_array_out),.fallingblock_out(fallingblock_out));
    parameter cyc=10;
    always #(cyc/2) clk=!clk;
    initial
    begin
        @(negedge clk);
        reset=1;
        #cyc;
        reset=0;
        repeat(10000)
        begin
        #cyc;
        $display("--------------------------%d",step);
        step=step+1;
        keyboard_state={$random}%6;
        if({$random}%20==0)
        keyboard_state=6;
        if({$random}%20==0)
        keyboard_state=7;
        $display("%d\t%d",fallingblock_out,keyboard_state);
        for(i=19;i>=0;i=i-1)
        begin
        for(ii=0;ii<10;ii=ii+1)
        begin
            if(stacking_array_out[4*(i*10+ii)+3]!=1)
            $write("%d\t",{stacking_array_out[4*(i*10+ii)+3],stacking_array_out[4*(i*10+ii)+2],stacking_array_out[4*(i*10+ii)+1],stacking_array_out[4*(i*10+ii)+0]});
            else
            $write("\t");
        end
        $write("|\n");
        end
        if(end_signal==1)
        $finish;
        end
        $finish;
    end
endmodule
