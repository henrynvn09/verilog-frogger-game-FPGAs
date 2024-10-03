`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/11/2022
//
// Purpose: receive clock BCD values, write clock on VGA screen
///////////////////////////////////////////////////////////////////////

module pixel_clk_gen(
    input clk,
    input video_on,
    //input tick_1Hz,       // use signal if blinking colon(s) is desired
    input PAUSE_sw,
    input [9:0] x, y,
    input [3:0] sec_1s, sec_10s,
    input [3:0] min_1s, min_10s,
    input [3:0] hr_1s, hr_10s,
    output reg [11:0] time_rgb
    );
  
    parameter x_offset = 100; // Adjust this value to shift the display down
    parameter y_offset = 195;
    
  
    // *** Constant Declarations ***
    // Hour 10s Digit section = 32 x 64
    localparam H10_X_L = 192 - x_offset;
    localparam H10_X_R = 223 - x_offset;
    localparam H10_Y_T = 192 + y_offset;
    localparam H10_Y_B = 256 + y_offset;
    
    // Hour 1s Digit section = 32 x 64
    localparam H1_X_L = 224 - x_offset;
    localparam H1_X_R = 255 - x_offset;
    localparam H1_Y_T = 192 + y_offset;
    localparam H1_Y_B = 256 + y_offset;
    
    // Colon 1 section = 32 x 64
    localparam C1_X_L = 256 - x_offset;
    localparam C1_X_R = 287 - x_offset;
    localparam C1_Y_T = 192 + y_offset;
    localparam C1_Y_B = 256 + y_offset;
    
    // Minute 10s Digit section = 32 x 64
    localparam M10_X_L = 288 - x_offset;
    localparam M10_X_R = 319 - x_offset;
    localparam M10_Y_T = 192 + y_offset;
    localparam M10_Y_B = 256 + y_offset;
    
    // Minute 1s Digit section = 32 x 64
    localparam M1_X_L = 320 - x_offset;
    localparam M1_X_R = 351 - x_offset;
    localparam M1_Y_T = 192 + y_offset;
    localparam M1_Y_B = 256 + y_offset;
    
    // Colon 2 section = 32 x 64
    localparam C2_X_L = 352 - x_offset;
    localparam C2_X_R = 383 - x_offset;
    localparam C2_Y_T = 192 + y_offset;
    localparam C2_Y_B = 256 + y_offset;
    
    // Second 10s Digit section = 32 x 64
    localparam S10_X_L = 384 - x_offset;
    localparam S10_X_R = 415 - x_offset;
    localparam S10_Y_T = 192 + y_offset;
    localparam S10_Y_B = 256 + y_offset;
    
    // Second 1s Digit section = 32 x 64
    localparam S1_X_L = 416 - x_offset;
    localparam S1_X_R = 447 - x_offset;
    localparam S1_Y_T = 192 + y_offset;
    localparam S1_Y_B = 256 + y_offset;
    
    
    // *** Constant Declarations for Second "Stopwatch" ***
    localparam H10_X_L2 = H10_X_L;
    localparam H10_X_R2 = H10_X_R;
    localparam H10_Y_T2 = H10_Y_T + 55; // Position it below the first one
    localparam H10_Y_B2 = H10_Y_B + 55;
    
    localparam H1_X_L2 = H1_X_L;
    localparam H1_X_R2 = H1_X_R;
    localparam H1_Y_T2 = H1_Y_T + 55;
    localparam H1_Y_B2 = H1_Y_B + 55;
    
    localparam C1_X_L2 = C1_X_L;
    localparam C1_X_R2 = C1_X_R;
    localparam C1_Y_T2 = C1_Y_T + 55;
    localparam C1_Y_B2 = C1_Y_B + 55;
    
    localparam M10_X_L2 = M10_X_L;
    localparam M10_X_R2 = M10_X_R;
    localparam M10_Y_T2 = M10_Y_T + 55;
    localparam M10_Y_B2 = M10_Y_B + 55;
    
    localparam M1_X_L2 = M1_X_L;
    localparam M1_X_R2 = M1_X_R;
    localparam M1_Y_T2 = M1_Y_T + 55;
    localparam M1_Y_B2 = M1_Y_B + 55;
    
    localparam C2_X_L2 = C2_X_L;
    localparam C2_X_R2 = C2_X_R;
    localparam C2_Y_T2 = C2_Y_T + 55;
    localparam C2_Y_B2 = C2_Y_B + 55;
    
    localparam S10_X_L2 = S10_X_L;
    localparam S10_X_R2 = S10_X_R;
    localparam S10_Y_T2 = S10_Y_T + 55;
    localparam S10_Y_B2 = S10_Y_B + 55;
    
    localparam S1_X_L2 = S1_X_L;
    localparam S1_X_R2 = S1_X_R;
    localparam S1_Y_T2 = S1_Y_T + 55;
    localparam S1_Y_B2 = S1_Y_B + 55;
    
    
    // Object Status Signals
    wire H10_on, H1_on, C1_on, M10_on, M1_on, C2_on, S10_on, S1_on;
    
    // ROM Interface Signals
    wire [10:0] rom_addr;
    reg [6:0] char_addr;   // 3'b011 + BCD value of time component
    wire [6:0] char_addr_h10, char_addr_h1, char_addr_m10, char_addr_m1, char_addr_s10, char_addr_s1, char_addr_c1, char_addr_c2;
    reg [3:0] row_addr;    // row address of digit
    wire [3:0] row_addr_h10, row_addr_h1, row_addr_m10, row_addr_m1, row_addr_s10, row_addr_s1, row_addr_c1, row_addr_c2;
    reg [2:0] bit_addr;    // column address of rom data
    wire [2:0] bit_addr_h10, bit_addr_h1, bit_addr_m10, bit_addr_m1, bit_addr_s10, bit_addr_s1, bit_addr_c1, bit_addr_c2;
    wire [7:0] digit_word;  // data from rom
    wire digit_bit;
    
    // Object Status Signals for Second "Stopwatch"
    wire H10_on2, H1_on2, C1_on2, M10_on2, M1_on2, C2_on2, S10_on2, S1_on2;

    // ROM Interface Signals for Second "Stopwatch"
    wire [10:0] rom_addr2;
    reg [6:0] char_addr2;
    reg [3:0] row_addr2;
    reg [2:0] bit_addr2;
    wire [7:0] digit_word2;
    wire digit_bit2;    
    
    assign char_addr_h10 = {3'b011, hr_10s};
    assign row_addr_h10 = y[5:2];   // scaling to 32x64
    assign bit_addr_h10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_h1 = {3'b011, hr_1s};
    assign row_addr_h1 = y[5:2];   // scaling to 32x64
    assign bit_addr_h1 = x[4:2];   // scaling to 32x64
    
    assign char_addr_c1 = 7'h3a;
    assign row_addr_c1 = y[5:2];    // scaling to 32x64
    assign bit_addr_c1 = x[4:2];    // scaling to 32x64
    
    assign char_addr_m10 = {3'b011, min_10s};
    assign row_addr_m10 = y[5:2];   // scaling to 32x64
    assign bit_addr_m10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_m1 = {3'b011, min_1s};
    assign row_addr_m1 = y[5:2];   // scaling to 32x64
    assign bit_addr_m1 = x[4:2];   // scaling to 32x64
    
    assign char_addr_c2 = 7'h3a;
    assign row_addr_c2 = y[5:2];    // scaling to 32x64
    assign bit_addr_c2 = x[4:2];    // scaling to 32x64
    
    assign char_addr_s10 = {3'b011, sec_10s};
    assign row_addr_s10 = y[5:2];   // scaling to 32x64
    assign bit_addr_s10 = x[4:2];   // scaling to 32x64
    
    assign char_addr_s1 = {3'b011, sec_1s};
    assign row_addr_s1 = y[5:2];   // scaling to 32x64
    assign bit_addr_s1 = x[4:2];   // scaling to 32x64
   
    
    // Instantiate digit rom
    clock_digit_rom cdr(.clk(clk), .addr(rom_addr), .data(digit_word));
    clock_digit_rom cdr2(.clk(clk), .addr(rom_addr2), .data(digit_word2));
    
    // Hour sections assert signals
    assign H10_on = (H10_X_L <= x) && (x <= H10_X_R) &&
                    (H10_Y_T <= y) && (y <= H10_Y_B) && (hr_10s != 0); // turn off digit if hours 10s = 1-9
    assign H1_on =  (H1_X_L <= x) && (x <= H1_X_R) &&
                    (H1_Y_T <= y) && (y <= H1_Y_B);
    
    // Colon 1 ROM assert signals
    assign C1_on = (C1_X_L <= x) && (x <= C1_X_R) &&
                   (C1_Y_T <= y) && (y <= C1_Y_B);
                               
    // Minute sections assert signals
    assign M10_on = (M10_X_L <= x) && (x <= M10_X_R) &&
                    (M10_Y_T <= y) && (y <= M10_Y_B);
    assign M1_on =  (M1_X_L <= x) && (x <= M1_X_R) &&
                    (M1_Y_T <= y) && (y <= M1_Y_B);                             
    
    // Colon 2 ROM assert signals
    assign C2_on = (C2_X_L <= x) && (x <= C2_X_R) &&
                   (C2_Y_T <= y) && (y <= C2_Y_B);
                  
    // Second sections assert signals
    assign S10_on = (S10_X_L <= x) && (x <= S10_X_R) &&
                    (S10_Y_T <= y) && (y <= S10_Y_B);
    assign S1_on =  (S1_X_L <= x) && (x <= S1_X_R) &&
                    (S1_Y_T <= y) && (y <= S1_Y_B);
                          
                      
    // Duplicate the hour sections for the second "stopwatch"
    assign H10_on2 = (H10_X_L2 <= x) && (x <= H10_X_R2) &&
                    (H10_Y_T2 <= y) && (y <= H10_Y_B2);
    assign H1_on2 =  (H1_X_L2 <= x) && (x <= H1_X_R2) &&
                    (H1_Y_T2 <= y) && (y <= H1_Y_B2);
    
    // Duplicate the colon section for the second "stopwatch"
    assign C1_on2 = (C1_X_L2 <= x) && (x <= C1_X_R2) &&
                   (C1_Y_T2 <= y) && (y <= C1_Y_B2);
    
    // Duplicate the minute sections for the second "stopwatch"
    assign M10_on2 = (M10_X_L2 <= x) && (x <= M10_X_R2) &&
                    (M10_Y_T2 <= y) && (y <= M10_Y_B2);
    assign M1_on2 =  (M1_X_L2 <= x) && (x <= M1_X_R2) &&
                    (M1_Y_T2 <= y) && (y <= M1_Y_B2);
    
    // Duplicate the colon section for the second "stopwatch"
    assign C2_on2 = (C2_X_L2 <= x) && (x <= C2_X_R2) &&
                   (C2_Y_T2 <= y) && (y <= C2_Y_B2);
    
    // Duplicate the second sections for the second "stopwatch"
    assign S10_on2 = (S10_X_L2 <= x) && (x <= S10_X_R2) &&
                    (S10_Y_T2 <= y) && (y <= S10_Y_B2);
    assign S1_on2 =  (S1_X_L2 <= x) && (x <= S1_X_R2) &&
                    (S1_Y_T2 <= y) && (y <= S1_Y_B2);                      
      
      
    // Mux for ROM Addresses and RGB  
    always @* begin  
        time_rgb = 12'h222;             // black background
        if(H10_on2) begin
            char_addr = char_addr_h10;
            row_addr = row_addr_h10;
            bit_addr = bit_addr_h10;
            if(digit_bit)
                time_rgb = 12'h0F0;     // green
        end
        else if(H1_on2) begin
            char_addr = char_addr_h1;
            row_addr = row_addr_h1;
            bit_addr = bit_addr_h1;
            if(digit_bit)
                time_rgb = 12'h0F0;     // green
        end
        else if(C1_on2) begin
            char_addr = char_addr_c1;
            row_addr = row_addr_c1;
            bit_addr = bit_addr_c1;
            if(digit_bit)
                time_rgb = 12'h0F0;     // green
        end
        else if(M10_on2) begin
            char_addr = char_addr_m10;
            row_addr = row_addr_m10;
            bit_addr = bit_addr_m1;
            if(digit_bit)
                time_rgb = 12'h0F0;     // green
        end
        else if(M1_on2) begin
            char_addr = char_addr_m1;
            row_addr = row_addr_m1;
            bit_addr = bit_addr_m1;
            if(digit_bit)
                time_rgb = 12'h0F0;     // green
        end
        else if(C2_on2) begin
            char_addr = char_addr_c2;
            row_addr = row_addr_c2;
            bit_addr = bit_addr_c2;
            if(digit_bit)
                time_rgb = 12'h0F0;     // green
        end
        else if(S10_on2) begin
            char_addr = char_addr_s10;
            row_addr = row_addr_s10;
            bit_addr = bit_addr_s10;
            if(digit_bit)
                time_rgb = 12'h0F0;     // green
        end
        else if(S1_on2) begin
            char_addr = char_addr_s1;
            row_addr = row_addr_s1;
            bit_addr = bit_addr_s1;
            if(digit_bit)
                time_rgb = 12'h0F0;     // green
        end       
        
    end    
    
    // ROM Interface    
    assign rom_addr = {char_addr, row_addr};
    assign digit_bit = digit_word[~bit_addr];    
    
    // ROM Interface for the second "stopwatch"
    assign rom_addr2 = {char_addr2, row_addr2};
    assign digit_bit2 = digit_word2[~bit_addr2]; 
                          
endmodule
