`timescale 1ns / 1ps

module Tetris(
    clk,
    reset,
    keyboard_state,//��L���A
    game_state,//�C�����A
    random_seed,//�üƺؤl�A��l��next
    end_signal,//�i���C������
    valid,
    h_cnt,
    v_cnt,
    vgaRed,
    vgaGreen,
    vgaBlue,
//    stacking_array_out,//���|�ϰ�
    hold,//�Ȧs�ϰ�
    next//���ݰϰ�
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
    output reg [4-1:0] hold;
    reg [4-1:0] next_hold;
    output reg [4*6-1:0] next;
    reg [4*6-1:0] next_next;
    
    //test 
//    output reg [4*10*20-1:0]stacking_array_out;
//    output [3:0] fallingblock_out;
    
    reg [3:0]fallingblock,next_fallingblock;
    reg [3:0]posx,next_posx;
    reg [4:0]posy,next_posy;
    wire [3:0]posxm1,posxm2;
    wire [4:0]posym1,posym2;
    wire [3:0]posxm1,posxm2,posxm3,posxp1,posxp2,posxp3;
    wire [4:0]posym1,posym2,posym3,posyp1,posyp2,posyp3;
    assign posxm1=posx-1;
    assign posxm2=posx-2;
    assign posxm3=posx-3;
    assign posxp1=posx+1;
    assign posxp2=posx+2;
    assign posxp3=posx+3;
    assign posym1=posy-1;
    assign posym2=posy-2;
    assign posym3=posy-3;
    assign posyp1=posy+1;
    assign posyp2=posy+2;
    assign posyp3=posy+3;
    reg [4:0]eposx[3:0];
    reg [4:0]eposy[3:0];
    reg [4:0]dposx[3:0];
    reg [4:0]dposy[3:0];
    reg [3:0]reposx[3:0];
    reg [4:0]reposy[3:0];
    reg [3:0]rdposx[3:0];
    reg [4:0]rdposy[3:0];
    reg [1:0]angle,next_angle;
    reg [26:0]falling_counter,next_falling_counter;
    reg [3-1:0]keyboard_state_delay,next_keyboard_state_delay,keyboard_state_delay2,next_keyboard_state_delay2;
    reg ctbr,next_ctbr;//check_touch_bottom return
    reg calr,next_calr;//check_action_legal_ return
    reg drawing;
//    assign fallingblock_out[3:0]={2'b00,angle};
    
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
    //game state
    parameter GET_NEXT_BLOCK=3'd0;
    parameter FALLING_CTBR=3'd1;
    parameter FALLING=3'd2;
    parameter END=3'd3;
    parameter RESTART=3'd4;
    parameter FALLING_CALR=3'd5;
    parameter ELIMINATE=3'd6;
    reg [4:0]ep1,ep2,next_ep1,next_ep2;
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
    
    
    parameter FALLING_TIME=27'd100_000_000;
    parameter ACTION_TIME_C1=27'd25_000_000;
    parameter ACTION_TIME_D1=27'd25_000_001;
    parameter ACTION_TIME_C2=27'd50_000_000;
    parameter ACTION_TIME_D2=27'd50_000_001;
    parameter ACTION_TIME_C3=27'd75_000_000;
    parameter ACTION_TIME_D3=27'd75_000_001;
//    parameter FALLING_TIME=27'd14;
//    parameter ACTION_TIME_C1=27'd2;
//    parameter ACTION_TIME_D1=27'd3;
//    parameter ACTION_TIME_C2=27'd6;
//    parameter ACTION_TIME_D2=27'd7;
//    parameter ACTION_TIME_C3=27'd10;
//    parameter ACTION_TIME_D3=27'd11;
    reg [26:0]falling_time,next_falling_time;
    
    //����
    //reg [10:0]point,next_point;
    
    reg [2:0]state,next_state;
    reg continue;
    wire [2:0] rand_out;
    wire rand_act;
    
    next_block_gen nbg(clk,reset,continue,random_seed,rand_out,rand_act);
    
    integer iep;
    integer i,ii;
//    always@(*)
//    begin
//        for(i=0;i<10;i=i+1)
//        begin
//            for(ii=0;ii<20;ii=ii+1)
//            begin
//                stacking_array_out[4*(ii*10+i)+0]=stacking_array[i][ii][0];
//                stacking_array_out[4*(ii*10+i)+1]=stacking_array[i][ii][1];
//                stacking_array_out[4*(ii*10+i)+2]=stacking_array[i][ii][2];
//                stacking_array_out[4*(ii*10+i)+3]=stacking_array[i][ii][3];
//            end
//        end
//    end
    always@(*)
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
                default:
                {vgaRed, vgaGreen, vgaBlue} = 12'hfff;
            endcase
        end
        else
            {vgaRed, vgaGreen, vgaBlue} = 12'h0;
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
            angle<=2'd0;
            falling_counter<=27'd0;
            keyboard_state_delay<=NO_ACTION;
            keyboard_state_delay2<=NO_ACTION;
            hold_block_counter<=0;
            hold<=EMPTY;
            falling_time<=FALLING_TIME;
//            for(i=0;i<16;i=i+1)
//            begin
//                for(ii=0;ii<32;ii=ii+1)
//                begin
//                    if(i<10&&ii<23)
//                    stacking_array[i][ii]<=EMPTY;
//                    else
//                    stacking_array[i][ii]<=GARBAGE;
//                end
//            end
            ctbr<=1'b0;
            calr<=1'b0;
            ep1<=5'd0;
            ep2<=5'd0;
        end
        else
        begin
            next<=next_next;
            state<=next_state;
            fallingblock<=next_fallingblock;
            posx<=next_posx;
            posy<=next_posy;
            angle<=next_angle;
            falling_counter<=next_falling_counter;
            keyboard_state_delay<=next_keyboard_state_delay;
            keyboard_state_delay2<=next_keyboard_state_delay2;
            hold_block_counter<=next_hold_block_counter;
            hold<=next_hold;
            falling_time<=next_falling_time;
            ctbr<=next_ctbr;
            calr<=next_calr;
            ep1<=next_ep1;
            ep2<=next_ep2;
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
        next_falling_counter=falling_counter;
        if(keyboard_state==NO_ACTION)
            next_keyboard_state_delay=keyboard_state_delay;
        else
            next_keyboard_state_delay=keyboard_state;
        next_keyboard_state_delay2=keyboard_state_delay2;
        next_hold_block_counter=hold_block_counter;
        next_hold=hold;
        next_falling_time=falling_time;
//        posxmove=posx;
//        posymove=posy;
        drawing=0;
        next_ctbr=0;
        next_calr=0;
        next_ep1=ep1;
        next_ep2=ep2;
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
                            stacking_array[i][ii]=EMPTY;
                            else
                            stacking_array[i][ii]=GARBAGE;
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
            FALLING_CTBR:
            begin
                next_state=FALLING;
                if(posy>0)
                next_ctbr=1;
//                case(fallingblock)
//                    I:
//                    begin
//                        case(angle)
//                            2'd0:
//                            if((stacking_array[posxm2][posym1]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)&&(stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY))
//                                next_ctbr=1;
//                            2'd1:
//                            if(stacking_array[posx][posym2]==EMPTY)
//                                next_ctbr=1;
//                            2'd2:
//                            if((stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)&&(stacking_array[posxp1][posym1]==EMPTY&&stacking_array[posxp2][posym1]==EMPTY))
//                                next_ctbr=1;
//                            2'd3:
//                            if(stacking_array[posx][posym3]==EMPTY)
//                                next_ctbr=1;
//                        endcase
//                    end
//                    J:
//                    begin
//                        case(angle)
//                            2'd0:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd1:
//                            if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posx][posym2]==EMPTY)
//                                next_ctbr=1;
//                            2'd2:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym2]==EMPTY)
//                                next_ctbr=1;
//                            2'd3:
//                            if(stacking_array[posxm1][posym2]==EMPTY&&stacking_array[posx][posym2]==EMPTY)
//                                next_ctbr=1;
//                        endcase
//                    end
//                    L:
//                    begin
//                        case(angle)
//                            2'd0:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd1:
//                            if(stacking_array[posxp1][posym2]==EMPTY&&stacking_array[posx][posym2]==EMPTY)
//                                next_ctbr=1;
//                            2'd2:
//                            if(stacking_array[posxm1][posym2]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd3:
//                            if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posx][posym2]==EMPTY)
//                                next_ctbr=1;
//                        endcase
//                    end
//                    O:
//                    begin
//                        case(angle)
//                            2'd0:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd1:
//                            if(stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd2:
//                            if(stacking_array[posx][posym2]==EMPTY&&stacking_array[posxp1][posym2]==EMPTY)
//                                next_ctbr=1;
//                            2'd3:
//                            if(stacking_array[posxm1][posym2]==EMPTY&&stacking_array[posx][posym2]==EMPTY)
//                                next_ctbr=1;
//                        endcase
//                    end
//                    S:
//                    begin
//                        case(angle)
//                            2'd0:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)
//                                next_ctbr=1;
//                            2'd1:
//                            if(stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym2]==EMPTY)
//                                next_ctbr=1;
//                            2'd2:
//                            if(stacking_array[posxm1][posym2]==EMPTY&&stacking_array[posx][posym2]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd3:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym2]==EMPTY)
//                                next_ctbr=1;
//                        endcase
//                    end
//                    T:
//                    begin
//                        case(angle)
//                            2'd0:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd1:
//                            if(stacking_array[posx][posym2]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd2:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym2]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd3:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym2]==EMPTY)
//                                next_ctbr=1;
//                        endcase
//                    end
//                    Z:
//                    begin
//                        case(angle)
//                            2'd0:
//                            if(stacking_array[posxm1][posym1+1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd1:
//                            if(stacking_array[posx][posym2]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                next_ctbr=1;
//                            2'd2:
//                            if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym2]==EMPTY&&stacking_array[posxp1][posym2]==EMPTY)
//                                next_ctbr=1;
//                            2'd3:
//                            if(stacking_array[posxm1][posym2]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                next_ctbr=1;
//                        endcase
//                    end
//                endcase
            end
            FALLING_CALR:
            begin
                next_state=FALLING;
                next_keyboard_state_delay2=keyboard_state_delay;
                next_calr=0;
//                case(next_fallingblock)
//                    I:
//                    begin
//                        case(keyboard_state_delay)
//                            MOVE_LEFT:
//                            begin
//                                case(angle)
//                                    2'd0:
//                                    if(stacking_array[posxm3][posy]==EMPTY)
//                                        next_calr=1;
//                                    2'd1:
//                                    if((stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY)&&(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm1][posyp2]==EMPTY))
//                                        next_calr=1;
//                                    2'd2:
//                                    if(stacking_array[posxm2][posy]==EMPTY)
//                                        next_calr=1;
//                                    2'd3:
//                                    if((stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY)&&(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posxm1][posym2]==EMPTY))
//                                        next_calr=1;
//                                endcase
//                            end
//                            MOVE_RIGHT:
//                            begin
//                                case(angle)
//                                    2'd0:
//                                    if(stacking_array[posxp2][posy]==EMPTY)
//                                        next_calr=1;
//                                    2'd1:
//                                    if((stacking_array[posxp1][posym1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)&&(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posxp1][posyp2]==EMPTY))
//                                        next_calr=1;
//                                    2'd2:
//                                    if(stacking_array[posxp3][posy]==EMPTY)
//                                        next_calr=1;
//                                    2'd3:
//                                    if((stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)&&(stacking_array[posxp1][posym1]==EMPTY&&stacking_array[posxp1][posym2]==EMPTY))
//                                        next_calr=1;
//                                endcase
//                            end
//                            CLOCKWISE:
//                            begin
//                                case(angle)
//                                    2'd0:
//                                    if(stacking_array[posx][posym1]==EMPTY&&stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posyp2]==EMPTY)
//                                        next_calr=1;
//                                    2'd1:
//                                    if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp2][posy]==EMPTY)
//                                        next_calr=1;
//                                    2'd2:
//                                    if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posx][posym2]==EMPTY)
//                                        next_calr=1;
//                                    2'd3:
//                                    if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)
//                                        next_calr=1;
//                                endcase
//                            end
//                            COUNTERCLOCKWISE:
//                            begin
//                                case(angle)
//                                    2'd2:
//                                    if(stacking_array[posx][posym1]==EMPTY&&stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posyp2]==EMPTY)
//                                        next_calr=1;
//                                    2'd3:
//                                    if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp2][posy]==EMPTY)
//                                        next_calr=1;
//                                    2'd0:
//                                    if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posx][posym2]==EMPTY)
//                                        next_calr=1;
//                                    2'd1:
//                                    if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)
//                                        next_calr=1;
//                                endcase
//                            end
//                        endcase
//                    end
//                    J:
//                    begin
//                        case(keyboard_state_delay)
//                            MOVE_LEFT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm2][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxm2][posym1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            MOVE_RIGHT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posx][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxp2][posyp1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp2][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posym1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            CLOCKWISE:
//                            begin
//                                case(angle)
//                                    2'd0:
//                                    if(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd1:
//                                    if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd2:
//                                    if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd3:
//                                    if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)
//                                        next_calr=1;
//                                endcase
//                            end
//                            COUNTERCLOCKWISE:
//                            begin
//                                case(angle)
//                                    2'd2:
//                                    if(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd3:
//                                    if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd0:
//                                    if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd1:
//                                    if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)
//                                        next_calr=1;
//                                endcase
//                            end
//                        endcase
//                    end
//                    L:
//                    begin
//                        case(keyboard_state_delay)
//                            MOVE_LEFT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posx][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm2][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxm2][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            MOVE_RIGHT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp2][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxp2][posym1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posym1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            CLOCKWISE:
//                            begin
//                                case(angle)
//                                    2'd0:
//                                    if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd1:
//                                    if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)
//                                        next_calr=1;
//                                    2'd2:
//                                    if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd3:
//                                    if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                        next_calr=1;
//                                endcase
//                            end
//                            COUNTERCLOCKWISE:
//                            begin
//                                case(angle)
//                                    2'd2:
//                                    if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd3:
//                                    if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)
//                                        next_calr=1;
//                                    2'd0:
//                                    if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posx][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                        next_calr=1;
//                                    2'd1:
//                                    if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                        next_calr=1;
//                                endcase
//                            end
//                        endcase
//                    end
//                    O:
//                    begin
//                        case(keyboard_state_delay)
//                            MOVE_LEFT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm2][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm2][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            MOVE_RIGHT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp2][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp2][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            CLOCKWISE:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posx][posyp1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            COUNTERCLOCKWISE:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                        endcase
//                    end
//                    S:
//                    begin
//                        case(keyboard_state_delay)
//                            MOVE_LEFT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxm2][posym1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm2][posyp1]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            MOVE_RIGHT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp2][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posxp2][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posx][posyp1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            CLOCKWISE:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posym1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            COUNTERCLOCKWISE:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                        endcase
//                    end
//                    T:
//                    begin
//                        case(keyboard_state_delay)
//                            MOVE_LEFT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            MOVE_RIGHT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            CLOCKWISE:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posy]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posx][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posy]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            COUNTERCLOCKWISE:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posy]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posx][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posy]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                        endcase
//                    end
//                    Z:
//                    begin
//                        case(keyboard_state_delay)
//                            MOVE_LEFT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxm2][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxm2][posy]==EMPTY&&stacking_array[posxm2][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            MOVE_RIGHT:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posxp2][posy]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxp2][posyp1]==EMPTY&&stacking_array[posxp2][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp2][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            CLOCKWISE:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxp1][posyp1]==EMPTY&&stacking_array[posx][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posxm1][posyp1]==EMPTY&&stacking_array[posxp1][posy]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                            COUNTERCLOCKWISE:
//                            begin
//                                case(angle)
//                                2'd0:
//                                if(stacking_array[posxm1][posy]==EMPTY&&stacking_array[posxm1][posym1]==EMPTY)
//                                    next_calr=1;
//                                2'd1:
//                                if(stacking_array[posx][posyp1]==EMPTY&&stacking_array[posxm1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd2:
//                                if(stacking_array[posxp1][posy]==EMPTY&&stacking_array[posxp1][posyp1]==EMPTY)
//                                    next_calr=1;
//                                2'd3:
//                                if(stacking_array[posx][posym1]==EMPTY&&stacking_array[posxp1][posym1]==EMPTY)
//                                    next_calr=1;
//                                endcase
//                            end
//                        endcase
//                    end
//                endcase
            end
            FALLING:
            begin
                if(falling_counter==ACTION_TIME_C1||falling_counter==ACTION_TIME_C2||falling_counter==ACTION_TIME_C3)
                    next_state=FALLING_CALR;
                else if(falling_counter==falling_time)
                    next_state=FALLING_CTBR;
                next_falling_counter=falling_counter+1;
                if(falling_counter==ACTION_TIME_D1||falling_counter==ACTION_TIME_D2||falling_counter==ACTION_TIME_D3)
                begin
                    case(keyboard_state_delay2)
                        SLOW_DOWN:
                        begin
                            next_keyboard_state_delay=NO_ACTION;
                            next_falling_counter=FALLING_TIME;
                        end
                        MOMENTARY_DROP:
                        begin
                            next_keyboard_state_delay=NO_ACTION;
                            next_falling_time=27'd10;
                            next_falling_counter=27'd0;
                        end
                        HOLD_BLOCK:
                        begin
                            if(hold_block_counter==0)
                            begin
                                next_hold_block_counter=1;
                                next_fallingblock=EMPTY;
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
                                drawing=1;
                            end
                        end
                    endcase
                    if(calr)
                    begin
                        case(keyboard_state_delay2)
                            MOVE_LEFT:
                            begin
                                next_keyboard_state_delay=NO_ACTION;
                                next_posx=posxm1;
                                drawing=1;
                            end
                            MOVE_RIGHT:
                            begin
                                next_keyboard_state_delay=NO_ACTION;
                                next_posx=posxp1;
                                drawing=1;
                            end
                            CLOCKWISE:
                            begin
                                next_keyboard_state_delay=NO_ACTION;
                                next_angle=angle+1;
                                drawing=1;
                            end
                            COUNTERCLOCKWISE:
                            begin
                                next_keyboard_state_delay=NO_ACTION;
                                next_angle=angle-1;
                                drawing=1;
                            end
                        endcase    
                    end
                end
                if(falling_counter>falling_time)
                begin
                    if(ctbr)
                    begin
                        next_posy=posym1;
                        drawing=1;
                        next_falling_counter=0;
                    end
                    else if(posy==5'd20)
                    begin
                        next_state=END;
                    end
                    else
                    begin
                        next_hold_block_counter=0;
                        next_state=ELIMINATE;
                        next_ep1=0;
                        next_ep2=0;
//                        next_state=GET_NEXT_BLOCK;
                        next_posx=4'd5;
                        next_posy=5'd20;
                        next_angle=2'd0;
                    end
                end
            end
            ELIMINATE:
            begin
                if(((stacking_array[4'd0][ep1]!=EMPTY&&stacking_array[4'd1][ep1]!=EMPTY)&&(stacking_array[4'd2][ep1]!=EMPTY&&
                stacking_array[4'd3][ep1]!=EMPTY))&&((stacking_array[4'd4][ep1]!=EMPTY&&stacking_array[4'd5][ep1]!=EMPTY)&&(
                stacking_array[4'd6][ep1]!=EMPTY&&stacking_array[4'd7][ep1]!=EMPTY))&&(stacking_array[4'd8][ep1]!=EMPTY&&stacking_array[4'd9][ep1]!=EMPTY))
                begin
                    next_ep1=ep1;
                    next_ep2=ep2+1;
                end
                else
                begin
                    next_ep1=ep1+1;
                    next_ep2=ep2+1;
                end
//                for(iep=0;iep<10;iep=iep+1)
//                stacking_array[iep][ep1]=stacking_array[iep][ep2];
                if(ep2==5'd20)
                begin
                     next_state=GET_NEXT_BLOCK;
                     next_posx=4'd5;
                    next_posy=5'd20;
                    next_angle=2'd0;
                end
            end
            END:
            begin
                end_signal=1;
            end
            
        endcase

        if(drawing||!drawing)
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
                reposx[0]=posx+eposx[0];
                reposx[1]=posx+eposx[1];
                reposx[2]=posx+eposx[2];
                reposx[3]=posx+eposx[3];
                reposy[0]=posy+eposy[0];
                reposy[1]=posy+eposy[1];
                reposy[2]=posy+eposy[2];
                reposy[3]=posy+eposy[3];
            end
            2'd1:
            begin
                // +0 +1
                // -1 +0
                reposx[0]=posx+eposy[0];
                reposx[1]=posx+eposy[1];
                reposx[2]=posx+eposy[2];
                reposx[3]=posx+eposy[3];
                reposy[0]=posy-eposx[0];
                reposy[1]=posy-eposx[1];
                reposy[2]=posy-eposx[2];
                reposy[3]=posy-eposx[3];
            end
            2'd2:
            begin
                // -1 +0
                // +0 -1
                reposx[0]=posx-eposx[0];
                reposx[1]=posx-eposx[1];
                reposx[2]=posx-eposx[2];
                reposx[3]=posx-eposx[3];
                reposy[0]=posy-eposy[0];
                reposy[1]=posy-eposy[1];
                reposy[2]=posy-eposy[2];
                reposy[3]=posy-eposy[3];
            end
            2'd3:
            begin
                // +0 -1
                // +1 +0
                reposx[0]=posx-eposy[0];
                reposx[1]=posx-eposy[1];
                reposx[2]=posx-eposy[2];
                reposx[3]=posx-eposy[3];
                reposy[0]=posy+eposx[0];
                reposy[1]=posy+eposx[1];
                reposy[2]=posy+eposx[2];
                reposy[3]=posy+eposx[3];
            end
        endcase
        stacking_array[reposx[0]][reposy[0]]=EMPTY;
        stacking_array[reposx[1]][reposy[1]]=EMPTY;
        stacking_array[reposx[2]][reposy[2]]=EMPTY;
        stacking_array[reposx[3]][reposy[3]]=EMPTY;
        case(next_fallingblock)
            I:
            begin
                dposx[0]=-2;
                dposx[1]=-1;
                dposx[2]=0;
                dposx[3]=1;
                dposy[0]=0;
                dposy[1]=0;
                dposy[2]=0;
                dposy[3]=0;
            end
            J:
            begin
                dposx[0]=-1;
                dposx[1]=-1;
                dposx[2]=0;
                dposx[3]=1;
                dposy[0]=1;
                dposy[1]=0;
                dposy[2]=0;
                dposy[3]=0;
            end
            L:
            begin
                dposx[0]=-1;
                dposx[1]=0;
                dposx[2]=1;
                dposx[3]=1;
                dposy[0]=0;
                dposy[1]=0;
                dposy[2]=0;
                dposy[3]=1;
            end
            O:
            begin
                dposx[0]=-1;
                dposx[1]=0;
                dposx[2]=-1;
                dposx[3]=0;
                dposy[0]=0;
                dposy[1]=0;
                dposy[2]=1;
                dposy[3]=1;
            end
            S:
            begin
                dposx[0]=-1;
                dposx[1]=0;
                dposx[2]=0;
                dposx[3]=1;
                dposy[0]=0;
                dposy[1]=0;
                dposy[2]=1;
                dposy[3]=1;
            end
            T:
            begin
                dposx[0]=-1;
                dposx[1]=0;
                dposx[2]=1;
                dposx[3]=0;
                dposy[0]=0;
                dposy[1]=0;
                dposy[2]=0;
                dposy[3]=1;
            end
            Z:
            begin
                dposx[0]=-1;
                dposx[1]=0;
                dposx[2]=0;
                dposx[3]=1;
                dposy[0]=1;
                dposy[1]=1;
                dposy[2]=0;
                dposy[3]=0;
            end
            default
            begin
                dposx[0]=0;
                dposx[1]=0;
                dposx[2]=0;
                dposx[3]=0;
                dposy[0]=0;
                dposy[1]=0;
                dposy[2]=0;
                dposy[3]=0;
            end
        endcase
        case(next_angle)
            2'd0:
            begin
                rdposx[0]=next_posx+dposx[0];
                rdposx[1]=next_posx+dposx[1];
                rdposx[2]=next_posx+dposx[2];
                rdposx[3]=next_posx+dposx[3];
                rdposy[0]=next_posy+dposy[0];
                rdposy[1]=next_posy+dposy[1];
                rdposy[2]=next_posy+dposy[2];
                rdposy[3]=next_posy+dposy[3];
            end
            2'd1:
            begin
                // +0 +1
                // -1 +0
                rdposx[0]=next_posx+dposy[0];
                rdposx[1]=next_posx+dposy[1];
                rdposx[2]=next_posx+dposy[2];
                rdposx[3]=next_posx+dposy[3];
                rdposy[0]=next_posy-dposx[0];
                rdposy[1]=next_posy-dposx[1];
                rdposy[2]=next_posy-dposx[2];
                rdposy[3]=next_posy-dposx[3];
            end
            2'd2:
            begin
                // -1 +0
                // +0 -1
                rdposx[0]=next_posx-dposx[0];
                rdposx[1]=next_posx-dposx[1];
                rdposx[2]=next_posx-dposx[2];
                rdposx[3]=next_posx-dposx[3];
                rdposy[0]=next_posy-dposy[0];
                rdposy[1]=next_posy-dposy[1];
                rdposy[2]=next_posy-dposy[2];
                rdposy[3]=next_posy-dposy[3];
            end
            2'd3:
            begin
                // +0 -1
                // +1 +0
                rdposx[0]=next_posx-dposy[0];
                rdposx[1]=next_posx-dposy[1];
                rdposx[2]=next_posx-dposy[2];
                rdposx[3]=next_posx-dposy[3];
                rdposy[0]=next_posy+dposx[0];
                rdposy[1]=next_posy+dposx[1];
                rdposy[2]=next_posy+dposx[2];
                rdposy[3]=next_posy+dposx[3];
            end
        endcase
        stacking_array[rdposx[0]][rdposy[0]]=next_fallingblock;
        stacking_array[rdposx[1]][rdposy[1]]=next_fallingblock;
        stacking_array[rdposx[2]][rdposy[2]]=next_fallingblock;
        stacking_array[rdposx[3]][rdposy[3]]=next_fallingblock;
        end
    end

    
endmodule
