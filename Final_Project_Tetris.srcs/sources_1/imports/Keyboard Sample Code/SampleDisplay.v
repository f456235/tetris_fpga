module KeyBoard(
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input wire rst,
    input wire clk,
    output reg [3-1:0]keyboard_state
    );
    
    parameter [8:0] LEFT_SHIFT_CODES  = 9'b0_0001_0010;
    
    reg [3-1:0]last_keyboard_state,next_last_keyboard_state,last_keyboard_state_decode;
    reg [27:0]keyboard_state_counter,next_keyboard_state_counter;
    parameter NO_ACTION=3'd0;
    parameter MOVE_LEFT=3'd1;
    parameter MOVE_RIGHT=3'd2;
    parameter CLOCKWISE=3'd3;
    parameter COUNTERCLOCKWISE=3'd4;
    parameter SLOW_DOWN=3'd5;
    parameter MOMENTARY_DROP=3'd6;
    parameter HOLD_BLOCK=3'd7;
    
    wire shift_down;
    wire [511:0] key_down;
    wire [8:0] last_change;
    reg [8:0] last_change_delay,next_last_change_delay;
    wire been_ready;
    
    
        
    KeyboardDecoder key_de (
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );

    always @ (posedge clk) begin
        if (rst) begin
            last_keyboard_state <= NO_ACTION;
            keyboard_state_counter <= 27'd0;
            last_change_delay <= last_change;
        end else begin
            last_keyboard_state<=next_last_keyboard_state;
            keyboard_state_counter<=next_keyboard_state_counter;
            last_change_delay<=next_last_change_delay;
        end
    end
    always @ (*) begin
        keyboard_state=NO_ACTION;
        next_last_keyboard_state=last_keyboard_state;
        next_keyboard_state_counter=keyboard_state_counter+1;
        next_last_change_delay=last_change_delay;
        if (been_ready && key_down[last_change] == 1'b1)
        begin
            keyboard_state=last_keyboard_state_decode;
            next_last_keyboard_state=last_keyboard_state_decode;
            next_keyboard_state_counter=27'd0;
            next_last_change_delay=last_change;
        end
//        if(keyboard_state_counter>=27'd200_000_000)
//        begin
//            next_keyboard_state_counter=27'd200_000_000;
//            if(key_down[last_change_delay] == 1'b1)
//            begin
//            keyboard_state=last_keyboard_state;
//            end
//        end
    end
    always @ (*) begin
        case (last_change)
        {1'b0,8'h6b}:
        last_keyboard_state_decode=MOVE_LEFT;
        {1'b1,8'h6b}:
        last_keyboard_state_decode=MOVE_LEFT;
        {1'b0,8'h74}:
        last_keyboard_state_decode=MOVE_RIGHT;
        {1'b1,8'h74}:
        last_keyboard_state_decode=MOVE_RIGHT;
        {1'b1,8'h75}:
        last_keyboard_state_decode=CLOCKWISE;
        {1'b0,8'h22}:
        last_keyboard_state_decode=CLOCKWISE;
        {1'b0,8'h73}:
        last_keyboard_state_decode=CLOCKWISE;
        {1'b0,8'h69}:
        last_keyboard_state_decode=CLOCKWISE;
        {1'b0,8'h7d}:
        last_keyboard_state_decode=CLOCKWISE;
        {1'b0,8'h14}:
        last_keyboard_state_decode=COUNTERCLOCKWISE;
        {1'b1,8'h14}:
        last_keyboard_state_decode=COUNTERCLOCKWISE;
        {1'b0,8'h1a}:
        last_keyboard_state_decode=COUNTERCLOCKWISE;
        {1'b0,8'h7a}:
        last_keyboard_state_decode=COUNTERCLOCKWISE;
        {1'b0,8'h6c}:
        last_keyboard_state_decode=COUNTERCLOCKWISE;
        {1'b1,8'h72}:
        last_keyboard_state_decode=SLOW_DOWN;
        {1'b0,8'h72}:
        last_keyboard_state_decode=SLOW_DOWN;
        {1'b0,8'h29}:
        last_keyboard_state_decode=MOMENTARY_DROP;
        {1'b0,8'h75}:
        last_keyboard_state_decode=CLOCKWISE;
        {1'b0,8'h12}:
        last_keyboard_state_decode=HOLD_BLOCK;
        {1'b0,8'h59}:
        last_keyboard_state_decode=HOLD_BLOCK;
        {1'b0,8'h21}:
        last_keyboard_state_decode=HOLD_BLOCK;
        {1'b0,8'h70}:
        last_keyboard_state_decode=HOLD_BLOCK;
        default:
        last_keyboard_state_decode=NO_ACTION;
        endcase
    end
endmodule
