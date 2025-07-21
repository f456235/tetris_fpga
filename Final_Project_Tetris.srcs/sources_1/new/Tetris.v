`timescale 1ns / 1ps

module Tetris(
    clk,
    reset,
    keyboard_state,//鍵盤狀態
    game_state,//遊戲狀態
    random_seed,//亂數種子，初始化next
    end_signal,//告知遊戲結束
    valid,
    h_cnt,
    v_cnt,
    vgaRed,
    vgaGreen,
    vgaBlue,
    //output reg stacking_array,//堆疊區域
    hold,//暫存區域
    next,//等待區域
    //test
//    ,fallingblock_out
    );
    input clk;
    input reset;
    input [3-1:0] keyboard_state;
    input [4-1:0] game_state;
    input [8-1:0] random_seed;
    output reg end_signal;
    input valid;
    input [9:0]h_cnt;
    input [9:0]v_cnt;
    output reg [3:0] vgaRed;
    output reg [3:0] vgaGreen;
    output reg [3:0] vgaBlue;
    reg [4-1:0]stacking_array[16-1:0][32-1:0];
    reg [4-1:0]next_stacking_array[16-1:0][32-1:0];
    reg [4-1:0]stacking_array_hidden[16-1:0][32-1:0];
    reg [4-1:0]next_stacking_array_hidden[16-1:0][32-1:0];
    output reg [4-1:0] hold;
    reg [4-1:0] next_hold;
    output reg [4*6-1:0] next;
    reg [4*6-1:0] next_next;
    reg [3:0]fallingblock,next_fallingblock;
    reg [3:0]posx,next_posx,prev_posx,prev_next_posx;
    reg [4:0]posy,next_posy,prev_posy,prev_next_posy;
    reg [1:0]angle,next_angle,prev_angle,prev_next_angle;
    reg [3-1:0]keyboard_state_delay,next_keyboard_state_delay;
    parameter unit = 10'd12;
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
    //time
    parameter FALLING_TIME=27'd100_000_000;
    reg [26:0]falling_counter,next_falling_counter;
    reg [26:0]falling_time,next_falling_time;
    parameter ACTION_TIME_C0=27'd00_000_000;
    parameter ACTION_TIME_D0=27'd00_000_001;
    parameter ACTION_TIME_C1=27'd25_000_000;
    parameter ACTION_TIME_D1=27'd25_000_001;
    parameter ACTION_TIME_C2=27'd50_000_000;
    parameter ACTION_TIME_D2=27'd50_000_001;
    parameter ACTION_TIME_C3=27'd75_000_000;
    parameter ACTION_TIME_D3=27'd75_000_001;
    //game state
    parameter GET_NEXT_BLOCK=3'd0;
    parameter FALLING_CTBR=3'd1;
    reg ctbr,next_ctbr;//check_touch_bottom return
    parameter FALLING=3'd2;
    parameter END=3'd3;
    parameter RESTART=3'd4;
    parameter FALLING_CTBR2=3'd5;
    parameter ELIMINATE=3'd6;
    reg [4:0]ep1,ep2,next_ep1,next_ep2;
    integer i,ii,iep;
    parameter DRAWING=3'd7;
    //keyboard state
    parameter NO_ACTION=3'd0;
    parameter MOVE_LEFT=3'd1;
    parameter MOVE_RIGHT=3'd2;
    parameter CLOCKWISE=3'd3;
    parameter COUNTERCLOCKWISE=3'd4;
    parameter SLOW_DOWN=3'd5;
    parameter MOMENTARY_DROP=3'd6;
    parameter HOLD_BLOCK=3'd7;
    reg hold_block_counter,next_hold_block_counter;
    
    reg [2:0]state,next_state;
    reg [4:0]eposx[3:0],delay_eposx[3:0];
    reg [4:0]eposy[3:0],delay_eposy[3:0];
    reg [3:0]reposx[3:0];
    reg [4:0]reposy[3:0];
    always@(posedge clk)
    begin
        delay_eposx[0]<=eposx[0];
        delay_eposx[1]<=eposx[1];
        delay_eposx[2]<=eposx[2];
        delay_eposx[3]<=eposx[3];
        delay_eposy[0]<=eposy[0];
        delay_eposy[1]<=eposy[1];
        delay_eposy[2]<=eposy[2];
        delay_eposy[3]<=eposy[3];
    end
    always@(*)
    begin
        case(fallingblock)
            I:
            begin
                eposx[0]=-2;
                eposx[1]=-1;
                eposx[2]=0;
                eposx[3]=1;
                eposy[0]=0;
                eposy[1]=0;
                eposy[2]=0;
                eposy[3]=0;
            end
            J:
            begin
                eposx[0]=-1;
                eposx[1]=-1;
                eposx[2]=0;
                eposx[3]=1;
                eposy[0]=1;
                eposy[1]=0;
                eposy[2]=0;
                eposy[3]=0;
            end
            L:
            begin
                eposx[0]=-1;
                eposx[1]=0;
                eposx[2]=1;
                eposx[3]=1;
                eposy[0]=0;
                eposy[1]=0;
                eposy[2]=0;
                eposy[3]=1;
            end
            O:
            begin
                eposx[0]=-1;
                eposx[1]=0;
                eposx[2]=-1;
                eposx[3]=0;
                eposy[0]=0;
                eposy[1]=0;
                eposy[2]=1;
                eposy[3]=1;
            end
            S:
            begin
                eposx[0]=-1;
                eposx[1]=0;
                eposx[2]=0;
                eposx[3]=1;
                eposy[0]=0;
                eposy[1]=0;
                eposy[2]=1;
                eposy[3]=1;
            end
            T:
            begin
                eposx[0]=-1;
                eposx[1]=0;
                eposx[2]=1;
                eposx[3]=0;
                eposy[0]=0;
                eposy[1]=0;
                eposy[2]=0;
                eposy[3]=1;
            end
            Z:
            begin
                eposx[0]=-1;
                eposx[1]=0;
                eposx[2]=0;
                eposx[3]=1;
                eposy[0]=1;
                eposy[1]=1;
                eposy[2]=0;
                eposy[3]=0;
            end
            default
            begin
                eposx[0]=0;
                eposx[1]=0;
                eposx[2]=0;
                eposx[3]=0;
                eposy[0]=0;
                eposy[1]=0;
                eposy[2]=0;
                eposy[3]=0;
            end
        endcase
        case(angle)
            2'd0:
            begin
                reposx[0]=posx+delay_eposx[0];
                reposx[1]=posx+delay_eposx[1];
                reposx[2]=posx+delay_eposx[2];
                reposx[3]=posx+delay_eposx[3];
                reposy[0]=posy+delay_eposy[0];
                reposy[1]=posy+delay_eposy[1];
                reposy[2]=posy+delay_eposy[2];
                reposy[3]=posy+delay_eposy[3];
            end
            2'd1:
            begin
                // +0 +1
                // -1 +0
                reposx[0]=posx+delay_eposy[0];
                reposx[1]=posx+delay_eposy[1];
                reposx[2]=posx+delay_eposy[2];
                reposx[3]=posx+delay_eposy[3];
                reposy[0]=posy-delay_eposx[0];
                reposy[1]=posy-delay_eposx[1];
                reposy[2]=posy-delay_eposx[2];
                reposy[3]=posy-delay_eposx[3];
            end
            2'd2:
            begin
                // -1 +0
                // +0 -1
                reposx[0]=posx-delay_eposx[0];
                reposx[1]=posx-delay_eposx[1];
                reposx[2]=posx-delay_eposx[2];
                reposx[3]=posx-delay_eposx[3];
                reposy[0]=posy-delay_eposy[0];
                reposy[1]=posy-delay_eposy[1];
                reposy[2]=posy-delay_eposy[2];
                reposy[3]=posy-delay_eposy[3];
            end
            2'd3:
            begin
                // +0 -1
                // +1 +0
                reposx[0]=posx-delay_eposy[0];
                reposx[1]=posx-delay_eposy[1];
                reposx[2]=posx-delay_eposy[2];
                reposx[3]=posx-delay_eposy[3];
                reposy[0]=posy+delay_eposx[0];
                reposy[1]=posy+delay_eposx[1];
                reposy[2]=posy+delay_eposx[2];
                reposy[3]=posy+delay_eposx[3];
            end
        endcase
    end
    //random
    reg continue;
    wire [2:0] rand_out;
    wire rand_act;
    next_block_gen nbg(clk,reset,continue,random_seed,rand_out,rand_act);
    //print
    /*always@(*)
    begin
        if(!valid)
            {vgaRed, vgaGreen, vgaBlue} = 12'h0;
        else if(h_cnt<200)
            {vgaRed, vgaGreen, vgaBlue} = 12'h0;
        else if(h_cnt<440)
        begin
            case(stacking_array[(h_cnt-200)/24][(480-v_cnt)/24])
                I:
                {vgaRed, vgaGreen, vgaBlue} = 12'h0ff;
                J:
                {vgaRed, vgaGreen, vgaBlue} = 12'h00e;
                L:
                {vgaRed, vgaGreen, vgaBlue} = 12'hf80;
                O:
                {vgaRed, vgaGreen, vgaBlue} = 12'hff0;
                S:
                {vgaRed, vgaGreen, vgaBlue} = 12'h0e0;
                T:
                {vgaRed, vgaGreen, vgaBlue} = 12'h80f;
                Z:
                {vgaRed, vgaGreen, vgaBlue} = 12'hf00;
                EMPTY:
                {vgaRed, vgaGreen, vgaBlue} = 12'hfff;
                default:
                {vgaRed, vgaGreen, vgaBlue} = 12'h0;
            endcase
        end
        else
            {vgaRed, vgaGreen, vgaBlue} = 12'h0;
    end*/
    always@(posedge clk)
    begin
        if(reset)
        begin
            next<={EMPTY,EMPTY,EMPTY,EMPTY,EMPTY,EMPTY};
            state<=RESTART;
            fallingblock<=EMPTY;
            posx<=4'd5;
            prev_posx<=4'd5;
            posy<=5'd20;
            prev_posy<=5'd20;
            angle<=2'd0;
            prev_angle<=2'd0;
            ctbr<=0;
            ep1<=5'd0;
            ep2<=5'd0;
            falling_counter<=27'd0;
            falling_time<=FALLING_TIME;
            keyboard_state_delay<=NO_ACTION;
            hold_block_counter<=0;
            hold<=EMPTY;
            for(i=0;i<16;i=i+1)
            begin
                for(ii=0;ii<32;ii=ii+1)
                begin
                    if(i<10&&ii<23)
                    stacking_array[i][ii]<=EMPTY;
                    else
                    stacking_array[i][ii]<=GARBAGE;
                end
            end
            for(i=0;i<16;i=i+1)
            begin
                for(ii=0;ii<32;ii=ii+1)
                begin
                    if(i<10&&ii<23)
                    stacking_array_hidden[i][ii]<=EMPTY;
                    else
                    stacking_array_hidden[i][ii]<=GARBAGE;
                end
            end
        end
        else
        begin
            next<=next_next;
            state<=next_state;
            fallingblock<=next_fallingblock;
            posx<=next_posx;
            prev_posx<=prev_next_posx;
            posy<=next_posy;
            prev_posy<=prev_next_posy;
            angle<=next_angle;
            prev_angle<=prev_next_angle;
            ctbr<=next_ctbr;
            ep1<=next_ep1;
            ep2<=next_ep2;
            falling_counter<=next_falling_counter;
            falling_time<=next_falling_time;
            keyboard_state_delay<=next_keyboard_state_delay;
            hold_block_counter<=next_hold_block_counter;
            hold<=next_hold;
            for(i=0;i<16;i=i+1)
            begin
                for(ii=0;ii<32;ii=ii+1)
                begin
                    if(i<10&&ii<23)
                    stacking_array[i][ii]<=next_stacking_array[i][ii];
                    else
                    stacking_array[i][ii]<=next_stacking_array[i][ii];
                end
            end
            for(i=0;i<16;i=i+1)
            begin
                for(ii=0;ii<32;ii=ii+1)
                begin
                    if(i<10&&ii<23)
                    stacking_array_hidden[i][ii]<=next_stacking_array_hidden[i][ii];
                    else
                    stacking_array_hidden[i][ii]<=next_stacking_array_hidden[i][ii];
                end
            end
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
        next_angle=angle;
        prev_next_posx=prev_posx;
        prev_next_posy=prev_posy;
        prev_next_angle=prev_angle;
        next_ctbr=ctbr;
        next_ep1=ep1;
        next_ep2=ep2;
        next_falling_counter=falling_counter;
        next_falling_time=falling_time;
        if(keyboard_state==NO_ACTION)
            next_keyboard_state_delay=keyboard_state_delay;
        else
            next_keyboard_state_delay=keyboard_state;
        next_hold_block_counter=hold_block_counter;
        next_hold=hold;
        for(i=0;i<16;i=i+1)
        begin
            for(ii=0;ii<32;ii=ii+1)
            begin
                next_stacking_array[i][ii]=stacking_array[i][ii];
            end
        end
        for(i=0;i<16;i=i+1)
        begin
            for(ii=0;ii<32;ii=ii+1)
            begin
                next_stacking_array_hidden[i][ii]=stacking_array_hidden[i][ii];
            end
        end
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
                    next_angle=2'd0;
                    next_hold_block_counter=0;
                    next_hold=EMPTY;
                    for(i=0;i<16;i=i+1)
                    begin
                        for(ii=0;ii<32;ii=ii+1)
                        begin
                            if(i<10&&ii<23)
                            next_stacking_array[i][ii]=EMPTY;
                            else
                            next_stacking_array[i][ii]=GARBAGE;
                        end
                    end
                    for(i=0;i<16;i=i+1)
                    begin
                        for(ii=0;ii<32;ii=ii+1)
                        begin
                            if(i<10&&ii<23)
                            next_stacking_array_hidden[i][ii]=EMPTY;
                            else
                            next_stacking_array_hidden[i][ii]=GARBAGE;
                        end
                    end
                end
            end
            GET_NEXT_BLOCK:
            begin
                continue=1;
                if(rand_act==1)
                begin
                    next_fallingblock=next[4*6-1:4*5];
                    next_next={next[4*5-1:4*0],1'b0,rand_out};
                    next_state=FALLING;
                    next_falling_counter=FALLING_TIME;
                    next_falling_time=FALLING_TIME;
                end
            end
            FALLING:
            begin
                next_falling_counter=falling_counter+1;
                if(falling_counter==ACTION_TIME_C0||falling_counter==ACTION_TIME_C1||falling_counter==ACTION_TIME_C2||falling_counter==ACTION_TIME_C3)
                begin
                    next_state=FALLING_CTBR;
                    prev_next_posx=posx;
                    prev_next_posy=posy;
                    prev_next_angle=angle;
                    next_keyboard_state_delay=NO_ACTION;
                    case(keyboard_state_delay)
                        MOVE_LEFT:
                        begin
                            next_posx=posx-1;
                        end
                        MOVE_RIGHT:
                        begin
                            next_posx=posx+1;
                        end
                        CLOCKWISE:
                        begin
                            next_angle=angle+1;
                        end
                        COUNTERCLOCKWISE:
                        begin
                            next_angle=angle-1;
                        end
                        SLOW_DOWN:
                        begin
                            next_falling_counter=falling_time;
                        end
                        MOMENTARY_DROP:
                        begin
                            next_falling_time=27'd0;
                        end
                        HOLD_BLOCK:
                        begin
                            if(hold_block_counter==0)
                            begin
                                next_hold_block_counter=1;
                                if(hold==EMPTY)
                                begin
                                    next_hold=fallingblock;
                                    next_state=GET_NEXT_BLOCK;
                                    next_posx=4'd5;
                                    next_posy=5'd20;
                                    next_angle=2'd0;
                                end
                                else
                                begin
                                    next_hold=fallingblock;
                                    next_fallingblock=hold;
                                    next_posx=4'd5;
                                    next_posy=5'd20;
                                    next_angle=2'd0;
                                    next_state=FALLING;
                                    next_falling_counter=FALLING_TIME;
                                    next_falling_time=FALLING_TIME;
                                end
                            end
                        end
                    endcase
                end
                if(falling_counter==ACTION_TIME_D0||falling_counter==ACTION_TIME_D1||falling_counter==ACTION_TIME_D2||falling_counter==ACTION_TIME_D3)
                begin
                    if(ctbr)
                    begin
                        next_state=DRAWING;
                    end
                end
                if(falling_counter==falling_time)
                begin
                    prev_next_posx=posx;
                    prev_next_posy=posy;
                    next_posy=posy-1;
                    next_state=FALLING_CTBR;
                end
                if(falling_counter>falling_time)
                begin
                    if(ctbr)
                    begin
                        next_state=DRAWING;
                        next_falling_counter=0;
                    end
                    else if(posy==5'd20)
                    begin
                        next_state=RESTART;
                        next_falling_time=FALLING_TIME;
                    end
                    else
                    begin
                        next_state=ELIMINATE;
                        next_ep1=0;
                        next_ep2=0;
                        next_posx=4'd5;
                        next_posy=5'd20;
                        next_angle=2'd0;
                        next_stacking_array_hidden[reposx[0]][reposy[0]]=fallingblock;
                        next_stacking_array_hidden[reposx[1]][reposy[1]]=fallingblock;
                        next_stacking_array_hidden[reposx[2]][reposy[2]]=fallingblock;
                        next_stacking_array_hidden[reposx[3]][reposy[3]]=fallingblock;
                        next_falling_time=FALLING_TIME;
                        next_hold_block_counter=0;
                    end
                end
            end
            FALLING_CTBR:
            begin
                next_state=FALLING_CTBR2;
            end
            FALLING_CTBR2:
            begin
                next_state=FALLING;
                next_ctbr=0;
                if(stacking_array_hidden[reposx[0]][reposy[0]]==EMPTY&&stacking_array_hidden[reposx[1]][reposy[1]]==EMPTY&&stacking_array_hidden[reposx[2]][reposy[2]]==EMPTY&&stacking_array_hidden[reposx[3]][reposy[3]]==EMPTY)
                begin
                    next_ctbr=1;
                end
                else
                begin
                    next_posx=prev_posx;
                    next_posy=prev_posy;
                    next_angle=prev_angle;
                end
            end
            DRAWING:
            begin
                next_state=FALLING;
                for(i=0;i<16;i=i+1)
                begin
                    for(ii=0;ii<32;ii=ii+1)
                    begin
                        next_stacking_array[i][ii]=stacking_array_hidden[i][ii];
                    end
                end
                next_stacking_array[reposx[0]][reposy[0]]=fallingblock;
                next_stacking_array[reposx[1]][reposy[1]]=fallingblock;
                next_stacking_array[reposx[2]][reposy[2]]=fallingblock;
                next_stacking_array[reposx[3]][reposy[3]]=fallingblock;
            end
            ELIMINATE:
            begin
                if(((stacking_array_hidden[4'd0][ep2]!=EMPTY&&stacking_array_hidden[4'd1][ep2]!=EMPTY)&&(stacking_array_hidden[4'd2][ep2]!=EMPTY&&
                stacking_array_hidden[4'd3][ep2]!=EMPTY))&&((stacking_array_hidden[4'd4][ep2]!=EMPTY&&stacking_array_hidden[4'd5][ep2]!=EMPTY)&&(
                stacking_array_hidden[4'd6][ep2]!=EMPTY&&stacking_array_hidden[4'd7][ep2]!=EMPTY))&&(stacking_array_hidden[4'd8][ep2]!=EMPTY&&stacking_array_hidden[4'd9][ep2]!=EMPTY))
                begin
                    next_ep1=ep1;
                    next_ep2=ep2+1;
                end
                else
                begin
                    next_ep1=ep1+1;
                    next_ep2=ep2+1;
                end
                for(iep=0;iep<10;iep=iep+1)
                next_stacking_array_hidden[iep][ep1]=next_stacking_array_hidden[iep][ep2];
                if(ep2==5'd20)
                begin
                     next_state=GET_NEXT_BLOCK;
                     next_posx=4'd5;
                     next_posy=5'd20;
                     next_angle=2'd0;
                end
            end
        endcase
    end
   
    always @(*) begin
        if(!valid)
            {vgaRed,vgaGreen,vgaBlue} = 12'h0;
        else if(h_cnt < unit*6 &&  v_cnt < unit*3) begin
            case (hold)
                4'b0000:begin
                    if(h_cnt < unit*5 && h_cnt >= unit && v_cnt >= unit && v_cnt < unit*2)
                        {vgaBlue,vgaGreen,vgaRed} = 12'hf80;
                    else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                end
                4'b0001:begin
                    if(h_cnt < unit*4 && h_cnt >= unit && v_cnt >= unit && v_cnt < unit*2)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                    else if(h_cnt <= unit*2 && h_cnt >= unit && v_cnt >= 10'd0 && v_cnt < unit)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                    else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                end
                4'b0010:begin
                    if(h_cnt < unit*4 && h_cnt >= unit && v_cnt >= unit && v_cnt < unit*2)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                    else if(h_cnt < unit*4 && h_cnt >= unit*3 && v_cnt >= 10'd0 && v_cnt < unit)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                      else {vgaBlue,vgaGreen,vgaRed} = 12'h0;    
                end
                4'b0011:begin
                    if(h_cnt < unit*4 && h_cnt >= unit*2 && v_cnt >= unit && v_cnt < unit*3)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h0ff;
                     else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                end
                4'b0100:begin
                    if(h_cnt < unit*3 && h_cnt >= unit && v_cnt >= unit && v_cnt < unit*2)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                    else if(h_cnt < unit*4 && h_cnt >= unit*2 && v_cnt >= 10'd0 && v_cnt < unit)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                     else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                end
                4'b0101:begin
                    if(h_cnt < unit*4 && h_cnt >= unit && v_cnt >= unit && v_cnt < unit*2)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                    else if(h_cnt < unit*3 && h_cnt >= unit*2 && v_cnt >= 10'd0 && v_cnt < unit)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                     else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                end
                4'b0110:begin
                    if(h_cnt < unit*3 && h_cnt >= unit && v_cnt >= 10'd0 && v_cnt < unit)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                    else if(h_cnt < unit*4 && h_cnt >= unit*2 && v_cnt >= unit && v_cnt < unit*2)
                        {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                     else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                end  
                default:
                    {vgaRed,vgaGreen,vgaBlue} = 12'h0; 
            endcase
        end
        else if (h_cnt < unit*6 && v_cnt == unit*3)
           {vgaBlue,vgaGreen,vgaRed} = 12'hfff;  
        else if(h_cnt > unit*6 && h_cnt < unit*16 ) begin
            case (stacking_array[(h_cnt-unit*6)/unit][(480-v_cnt)/unit])
                4'b0000: {vgaBlue,vgaGreen,vgaRed} = 12'hf80;
                4'b0001: {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                4'b0010: {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                4'b0011: {vgaBlue,vgaGreen,vgaRed} = 12'h0ff;
                4'b0100: {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                4'b0101: {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                4'b0110: {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                4'b0111: {vgaBlue,vgaGreen,vgaRed} = 12'h222;
                4'b1000: {vgaBlue,vgaGreen,vgaRed} = 12'h000;
                default: {vgaBlue,vgaGreen,vgaRed} = 12'h000;
            endcase
        end
        else if (h_cnt == unit*6 || h_cnt == unit*16) begin 
            {vgaBlue,vgaGreen,vgaRed} = 12'hfff;
        end
        else if(h_cnt > unit*16 && h_cnt < unit*22 && v_cnt < unit*18) begin
            if(v_cnt < unit*3) begin
                case (next[23:20])
                     4'b0000:begin
                        if(h_cnt < unit*21 && h_cnt >= unit*17 && v_cnt >= unit && v_cnt < unit*2)
                            {vgaBlue,vgaGreen,vgaRed} = 12'hf80;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0001:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit && v_cnt < unit*2)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                        else if(h_cnt <= unit*18 && h_cnt >= unit*17 && v_cnt >= 10'd0 && v_cnt < unit)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                    end
                    4'b0010:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit && v_cnt < unit*2)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                        else if(h_cnt < unit*20 && h_cnt >= unit*19 && v_cnt >= 10'd0 && v_cnt < unit)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                    end
                    4'b0011:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= 10'd0 && v_cnt < unit*2)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0ff;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0100:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17  && v_cnt >= unit && v_cnt < unit*2)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= 10'd0 && v_cnt < unit)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0101:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit && v_cnt < unit*2)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else if(h_cnt < unit*19 && h_cnt >= unit*18 && v_cnt >= 10'd0 && v_cnt < unit)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0110:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17 && v_cnt >= 10'd0 && v_cnt < unit)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit && v_cnt < unit*2)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    default: {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                endcase
            end
            else if (v_cnt >= unit *3 && v_cnt < unit*6) begin
                case (next[19:16])
      
                    4'b0000:begin
                        if(h_cnt < unit*21 && h_cnt >= unit*17 && v_cnt >= unit*4 && v_cnt < unit*5)
                            {vgaBlue,vgaGreen,vgaRed} = 12'hf80;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0001:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*4 && v_cnt < unit*5)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                        else if(h_cnt <= unit*18 && h_cnt >= unit*17 && v_cnt >= unit*3 && v_cnt < unit*4)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;  
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0010:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*4 && v_cnt < unit*5)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                        else if(h_cnt < unit*20 && h_cnt >= unit*19 && v_cnt >= unit*3 && v_cnt < unit*4)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f; 
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0; 
                    end
                    4'b0011:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*3 && v_cnt < unit*5)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0ff;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0100:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17  && v_cnt >= unit*4 && v_cnt < unit*5)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*3 && v_cnt < unit*4)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0101:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*4 && v_cnt < unit*5)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else if(h_cnt < unit*19 && h_cnt >= unit*18 && v_cnt >= unit*3 && v_cnt < unit*4)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0110:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17 && v_cnt >= unit*3 && v_cnt < unit*4)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*4 && v_cnt < unit*5)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    default: {vgaBlue,vgaRed,vgaGreen} = 12'h0;
                endcase
            end
            else if(v_cnt >= unit*6 && v_cnt < unit*9) begin
                case (next[15:12])
                    4'b0000:begin
                        if(h_cnt < unit*21 && h_cnt >= unit*17 && v_cnt >= unit*7 && v_cnt < unit*8)
                            {vgaBlue,vgaGreen,vgaRed} = 12'hf80;
                       else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0001:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*7 && v_cnt < unit*8)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                        else if(h_cnt <= unit*18 && h_cnt >= unit*17 && v_cnt >= unit*6 && v_cnt < unit*7)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                    end
                    4'b0010:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*7 && v_cnt < unit*8)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                        else if(h_cnt < unit*20 && h_cnt >= unit*19 && v_cnt >= unit*6 && v_cnt < unit*7)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f; 
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0; 
                    end
                    4'b0011:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*6 && v_cnt < unit*8)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0ff;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0100:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17  && v_cnt >= unit*7 && v_cnt < unit*8)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*6 && v_cnt < unit*7)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0101:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*7 && v_cnt < unit*8)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else if(h_cnt < unit*19 && h_cnt >= unit*18 && v_cnt >= unit*6 && v_cnt < unit*7)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0110:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17 && v_cnt >= unit*6 && v_cnt < unit*7)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*7 && v_cnt < unit*8)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    default: {vgaBlue,vgaGreen,vgaRed} =12'h0;
                endcase
            end
            else if(v_cnt >= unit*9 && v_cnt < unit*12) begin
                case (next[11:8])
                    4'b0000:begin
                        if(h_cnt < unit*21 && h_cnt >= unit*17 && v_cnt >= unit*10 && v_cnt < unit*11)
                            {vgaBlue,vgaGreen,vgaRed} = 12'hf80;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0001:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*10 && v_cnt < unit*11)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                        else if(h_cnt <= unit*18 && h_cnt >= unit*17 && v_cnt >= unit*9 && v_cnt < unit*10)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800; 
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0; 
                    end
                    4'b0010:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*10 && v_cnt < unit*11)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                        else if(h_cnt < unit*20 && h_cnt >= unit*19 && v_cnt >= unit*9 && v_cnt < unit*10)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;  
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0011:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*9 && v_cnt < unit*11)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0ff;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0100:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17  && v_cnt >= unit*10 && v_cnt < unit*11)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*9 && v_cnt < unit*10)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0101:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*10 && v_cnt < unit*11)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else if(h_cnt < unit*19 && h_cnt >= unit*18 && v_cnt >= unit*9 && v_cnt < unit*10)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0110:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17 && v_cnt >= unit*9 && v_cnt < unit*10)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*10 && v_cnt < unit*11)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    default: {vgaBlue,vgaGreen,vgaRed} =12'h0; 
                endcase
            end
            else if(v_cnt >= unit*12 && v_cnt < unit*15) begin
                case (next[7:4])
                    4'b0000:begin
                        if(h_cnt < unit*21 && h_cnt >= unit*17 && v_cnt >= unit*13 && v_cnt < unit*14)
                            {vgaBlue,vgaGreen,vgaRed} = 12'hf80;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0001:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*13 && v_cnt < unit*14)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                        else if(h_cnt <= unit*18 && h_cnt >= unit*17 && v_cnt >= unit*12 && v_cnt < unit*13)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800; 
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0; 
                    end
                    4'b0010:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*13 && v_cnt < unit*14)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                        else if(h_cnt < unit*20 && h_cnt >= unit*19 && v_cnt >= unit*12 && v_cnt < unit*13)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                    end
                    4'b0011:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*12 && v_cnt < unit*14)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0ff;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0100:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17  && v_cnt >= unit*13 && v_cnt < unit*14)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*12 && v_cnt < unit*13)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0101:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*13 && v_cnt < unit*14)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else if(h_cnt < unit*19 && h_cnt >= unit*18 && v_cnt >= unit*12 && v_cnt < unit*13)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0110:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17 && v_cnt >= unit*12 && v_cnt < unit*13)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*13 && v_cnt < unit*14)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    default: {vgaBlue,vgaGreen,vgaRed} =12'h0;
                endcase
            end
            else if(v_cnt >= unit*15 && v_cnt < unit*18) begin
                case (next[3:0])
                    4'b0000:begin
                        if(h_cnt < unit*21 && h_cnt >= unit*17 && v_cnt >= unit*16 && v_cnt < unit*17)
                            {vgaBlue,vgaGreen,vgaRed} = 12'hf80;
                       else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0001:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*16 && v_cnt < unit*17)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;
                        else if(h_cnt <= unit*18 && h_cnt >= unit*17 && v_cnt >= unit*15 && v_cnt < unit*16)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h800;  
                       else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0010:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*16 && v_cnt < unit*17)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                        else if(h_cnt < unit*20 && h_cnt >= unit*19 && v_cnt >= unit*15 && v_cnt < unit*16)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h08f;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;  
                    end
                    4'b0011:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*15 && v_cnt < unit*17)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0ff;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0100:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17  && v_cnt >= unit*16 && v_cnt < unit*17)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*15 && v_cnt < unit*16)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h0f4;
                         else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0101:begin
                        if(h_cnt < unit*20 && h_cnt >= unit*17 && v_cnt >= unit*16 && v_cnt < unit*17)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else if(h_cnt < unit*19 && h_cnt >= unit*18 && v_cnt >= unit*15 && v_cnt < unit*16)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h808;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    4'b0110:begin
                        if(h_cnt < unit*19 && h_cnt >= unit*17 && v_cnt >= unit*15 && v_cnt < unit*16)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else if(h_cnt < unit*20 && h_cnt >= unit*18 && v_cnt >= unit*16 && v_cnt < unit*17)
                            {vgaBlue,vgaGreen,vgaRed} = 12'h008;
                        else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
                    end
                    default: {vgaBlue,vgaGreen,vgaRed} =12'h0;
                endcase
            end
            else {vgaBlue,vgaGreen,vgaRed} = 12'h0;
        end
        else if((h_cnt  == unit*16 || h_cnt == unit*22) && v_cnt <= unit*18)
            {vgaBlue,vgaGreen,vgaRed} = 12'hfff;
        else if((h_cnt  >= unit*16 && h_cnt <= unit*22) && v_cnt == unit*18)
             {vgaBlue,vgaGreen,vgaRed} = 12'hfff;
        
        
        else {vgaRed,vgaGreen,vgaBlue} = 12'h0;
    end
endmodule
