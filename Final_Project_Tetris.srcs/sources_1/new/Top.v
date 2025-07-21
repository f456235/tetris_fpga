`timescale 1ns / 1ps
module top(
   inout wire PS2_DATA,
   inout wire PS2_CLK,
   input clk,
   input rst,
   output [3:0] vgaRed,
   output [3:0] vgaGreen,
   output [3:0] vgaBlue,
   output hsync,
   output vsync
    );

    wire [4-1:0]stacking_array[16-1:0][32-1:0];
    wire [4-1:0] hold;
    wire [4*6-1:0] next;
    wire clk_25MHz;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480
    wire [3-1:0]keyboard_state;
    KeyBoard keyboard(
    .PS2_DATA(PS2_DATA),
    .PS2_CLK(PS2_CLK),
    .rst(rst),
    .clk(clk),
    .keyboard_state(keyboard_state)
    );

     clock_divisor clk_wiz_0_inst(
      .clk(clk),
      .clk1(clk_25MHz)
    );
    
   Tetris tetris(
        .clk(clk),
        .reset(rst),
        .keyboard_state(keyboard_state),
        .random_seed(8'b10110101),
       .h_cnt(h_cnt),
       .v_cnt(v_cnt),
       .valid(valid),
       .vgaRed(vgaRed),
       .vgaGreen(vgaGreen),
       .vgaBlue(vgaBlue)
    );
  
    
    
    vga_controller   vga_inst(
      .pclk(clk_25MHz),
      .reset(rst),
      .hsync(hsync),
      .vsync(vsync),
      .valid(valid),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt)
    );
      
endmodule
