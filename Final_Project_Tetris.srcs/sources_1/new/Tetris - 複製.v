`timescale 1ns / 1ps

module Tetris(
    clk,
    reset,
    keyboard_state,//鍵盤狀態
    game_state,//遊戲狀態
    random_seed,//亂數種子，初始化next
    end_signal,//告知遊戲結束
    stacking_array_out,//堆疊區域
    hold,//暫存區域
    next//等待區域
    //test
    ,fallingblock_out
    );
    input clk;
    input reset;
    input [3-1:0] keyboard_state;
    input [4-1:0] game_state;
    input [8-1:0] random_seed;
    output reg end_signal;
    output reg [4*10*20-1:0]stacking_array_out;
    reg [4-1:0]stacking_array[10-1:0][22-1:0];
    output [4-1:0] hold;
    output reg [4*6-1:0] next;
    reg [4*6-1:0] next_next;
    
    //test 
    output [3:0] fallingblock_out;
    
    reg [3:0]fallingblock,next_fallingblock;
    reg [3:0]posx,next_posx,posxmove,posxdraw;
    reg [4:0]posy,next_posy,posymove,posydraw;
    reg [1:0]angle,next_angle;
    reg [26:0]falling_counter,next_falling_counter;
    reg ctbr,next_ctbr;//check_touch_bottom return
    reg drawing;
    assign fallingblock_out=fallingblock;
    
    //block
    parameter I=4'b0000;
    parameter J=4'b0001;
    parameter L=4'b0010;
    parameter O=4'b0011;
    parameter S=4'b0100;
    parameter T=4'b0101;
    parameter Z=4'b0110;
    parameter GARBAGE=4'b0111;
    parameter EMPTY=4'b1000;
    
    parameter GET_NEXT_BLOCK=3'd0;
    parameter FALLING_CTBR=3'd1;
    parameter FALLING=3'd2;
    parameter END=3'd3;
    parameter RESTART=3'd4;
    
    parameter FALLING_TIME=27'd0;
    
    reg [2:0]state,next_state;
    reg continue;
    wire [2:0] rand_out;
    wire rand_act;
    
    next_block_gen nbg(clk,reset,continue,random_seed,rand_out,rand_act);
    
    integer i,ii;
    always@(*)
    begin
        for(i=0;i<10;i=i+1)
        begin
            for(ii=0;ii<20;ii=ii+1)
            begin
                stacking_array_out[4*(ii*10+i)+0]=stacking_array[i][ii][0];
                stacking_array_out[4*(ii*10+i)+1]=stacking_array[i][ii][1];
                stacking_array_out[4*(ii*10+i)+2]=stacking_array[i][ii][2];
                stacking_array_out[4*(ii*10+i)+3]=stacking_array[i][ii][3];
            end
        end
    end
    
    always@(posedge clk)
    begin
        if(reset)
        begin
            next<={EMPTY,EMPTY,EMPTY,EMPTY,EMPTY,EMPTY};
            state<=RESTART;
            fallingblock<=EMPTY;
            posx<=4'd5;
            posy<=5'd20;
            falling_counter<=27'd0;
            for(i=0;i<10;i=i+1)
            begin
                for(ii=0;ii<21;ii=ii+1)
                begin
                    stacking_array[i][ii]<=EMPTY;
                end
            end
            ctbr<=1'b0;
        end
        else
        begin
            next<=next_next;
            state<=next_state;
            fallingblock<=next_fallingblock;
            posx<=next_posx;
            posy<=next_posy;
            falling_counter<=next_falling_counter;
            ctbr<=next_ctbr;
        end
    end
    always@(*)
    begin
        end_signal=0;
        continue=0;
        next_next=next;
        next_state=state;
        next_fallingblock=fallingblock;
        next_posx=posx;
        next_posy=posy;
        next_falling_counter=27'd0;
        posxmove=posx;
        posymove=posy;
        drawing=0;
        next_ctbr=0;
        case(state)
            RESTART:
            begin
                if(next[4*6-1:4*5]==4'b1000)
                begin
                    continue=1;
                    if(rand_act==1)
                    begin
                        next_next={next[4*5-1:4*0],1'b0,rand_out};
                    end
                end
                else
                begin
                    next_state=GET_NEXT_BLOCK;
                    next_posx=4'd5;
                    next_posy=5'd20;
                end
            end
            GET_NEXT_BLOCK:
            begin
                continue=1;
                if(rand_act==1)
                begin
                    next_fallingblock=next[4*6-1:4*5];
                    next_next={next[4*5-1:4*0],1'b0,rand_out};
                    next_state=FALLING_CTBR;
                    next_falling_counter=27'd0;
                    drawing=1;
                end
            end
            FALLING_CTBR:
            begin
                next_state=FALLING;
                case(next_fallingblock)
                    I:
                    begin
                        if(posy==0)
                            next_ctbr=0;
                        else if(stacking_array[posx-2][posy-1]==EMPTY&&stacking_array[posx-1][posy-1]==EMPTY&&stacking_array[posx][posy-1]==EMPTY&&stacking_array[posx+1][posy-1]==EMPTY)
                            next_ctbr=1;
                    end
                    J:
                    begin
                        if(posy==0)
                            next_ctbr=0;
                        else if(stacking_array[posx-1][posy-1]==EMPTY&&stacking_array[posx][posy-1]==EMPTY&&stacking_array[posx+1][posy-1]==EMPTY)
                            next_ctbr=1;
                    end
                    L:
                    begin
                        if(posy==0)
                            next_ctbr=0;
                        else if(stacking_array[posx-1][posy-1]==EMPTY&&stacking_array[posx][posy-1]==EMPTY&&stacking_array[posx+1][posy-1]==EMPTY)
                            next_ctbr=1;
                    end
                    O:
                    begin
                        if(posy==0)
                            next_ctbr=0;
                        else if(stacking_array[posx-1][posy-1]==EMPTY&&stacking_array[posx][posy-1]==EMPTY)
                            next_ctbr=1;
                    end
                    S:
                    begin
                        if(posy==0)
                            next_ctbr=0;
                        else if(stacking_array[posx-1][posy-1]==EMPTY&&stacking_array[posx][posy-1]==EMPTY&&stacking_array[posx+1][posy-1+1]==EMPTY)
                            next_ctbr=1;
                    end
                    T:
                    begin
                        if(posy==0)
                            next_ctbr=0;
                        else if(stacking_array[posx-1][posy-1]==EMPTY&&stacking_array[posx][posy-1]==EMPTY&&stacking_array[posx+1][posy-1]==EMPTY)
                            next_ctbr=1;
                    end
                    Z:
                    begin
                        if(posy==0)
                            next_ctbr=0;
                        else if(stacking_array[posx-1][posy-1+1]==EMPTY&&stacking_array[posx][posy-1]==EMPTY&&stacking_array[posx+1][posy-1]==EMPTY)
                            next_ctbr=1;
                    end
                endcase
            end
            FALLING:
            begin
                next_state=FALLING_CTBR;
                next_falling_counter=falling_counter+1;
                if(falling_counter>=FALLING_TIME)
                begin
                    if(ctbr)
                    begin
                        next_posy=posy-1;
                        drawing=1;
                        next_falling_counter=0;
                    end
                    else if(posy==5'd20)
                    begin
                        next_state=END;
                    end
                    else
                    begin
                        next_state=GET_NEXT_BLOCK;
                        next_posx=4'd5;
                        next_posy=5'd20;
                    end
                end
            end
            END:
            begin
                end_signal=1;
            end
            
        endcase

        if(drawing)
        case(next_fallingblock)
            I:
            begin
                stacking_array[posx-2][posy]=EMPTY;
                stacking_array[posx-1][posy]=EMPTY;
                stacking_array[posx][posy]=EMPTY;
                stacking_array[posx+1][posy]=EMPTY;
                stacking_array[next_posx-2][next_posy]=I;
                stacking_array[next_posx-1][next_posy]=I;
                stacking_array[next_posx][next_posy]=I;
                stacking_array[next_posx+1][next_posy]=I;
            end
            J:
            begin
                stacking_array[posx-1][posy+1]=EMPTY;
                stacking_array[posx-1][posy]=EMPTY;
                stacking_array[posx][posy]=EMPTY;
                stacking_array[posx+1][posy]=EMPTY;
                stacking_array[next_posx-1][next_posy+1]=J;
                stacking_array[next_posx-1][next_posy]=J;
                stacking_array[next_posx][next_posy]=J;
                stacking_array[next_posx+1][next_posy]=J;
            end
            L:
            begin
                stacking_array[posx-1][posy]=EMPTY;
                stacking_array[posx][posy]=EMPTY;
                stacking_array[posx+1][posy]=EMPTY;
                stacking_array[posx+1][posy+1]=EMPTY;
                stacking_array[next_posx-1][next_posy]=L;
                stacking_array[next_posx][next_posy]=L;
                stacking_array[next_posx+1][next_posy]=L;
                stacking_array[next_posx+1][next_posy+1]=L;
            end
            O:
            begin
                stacking_array[posx-1][posy]=EMPTY;
                stacking_array[posx][posy]=EMPTY;
                stacking_array[posx-1][posy+1]=EMPTY;
                stacking_array[posx][posy+1]=EMPTY;
                stacking_array[next_posx-1][next_posy]=O;
                stacking_array[next_posx][next_posy]=O;
                stacking_array[next_posx-1][next_posy+1]=O;
                stacking_array[next_posx][next_posy+1]=O;
            end
            S:
            begin
                stacking_array[posx-1][posy]=EMPTY;
                stacking_array[posx][posy]=EMPTY;
                stacking_array[posx][posy+1]=EMPTY;
                stacking_array[posx+1][posy+1]=EMPTY;
                stacking_array[next_posx-1][next_posy]=S;
                stacking_array[next_posx][next_posy]=S;
                stacking_array[next_posx][next_posy+1]=S;
                stacking_array[next_posx+1][next_posy+1]=S;
            end
            T:
            begin
                stacking_array[posx-1][posy]=EMPTY;
                stacking_array[posx][posy]=EMPTY;
                stacking_array[posx+1][posy]=EMPTY;
                stacking_array[posx][posy+1]=EMPTY;
                stacking_array[next_posx-1][next_posy]=T;
                stacking_array[next_posx][next_posy]=T;
                stacking_array[next_posx+1][next_posy]=T;
                stacking_array[next_posx][next_posy+1]=T;
            end
            Z:
            begin
                stacking_array[posx-1][posy+1]=EMPTY;
                stacking_array[posx][posy+1]=EMPTY;
                stacking_array[posx][posy]=EMPTY;
                stacking_array[posx+1][posy]=EMPTY;
                stacking_array[next_posx-1][next_posy+1]=Z;
                stacking_array[next_posx][next_posy+1]=Z;
                stacking_array[next_posx][next_posy]=Z;
                stacking_array[next_posx+1][next_posy]=Z;
            end
        endcase
    end

    
endmodule
