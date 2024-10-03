`timescale 1ns / 1ps
////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/11/2022
//
// Description: Top module for the VGA Clock
////////////////////////////////////////////////////////////


module top(
    input clk_100MHz,       // 100MHz on Basys 3
    input reset,            // btnC
    
    input btn_Up,
    input btn_Down,
    input btn_Left,
    input btn_Right,

    output hsync,           // to VGA Connector
    output vsync,           // to VGA Connector
    output [11:0] rgb       // to DAC, to VGA Connector
    );
    
    // Internal Connection Signals
    wire [9:0] w_x, w_y;
    wire video_on, p_tick;
    wire [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s;
    reg [11:0] rgb_reg;
    wire [11:0] rgb_next;
    wire [11:0] rgb_next_best;
    
    reg [3:0] hr_10s_best, hr_1s_best, min_10s_best, min_1s_best, sec_10s_best, sec_1s_best;
    
    //2nd clock
//    wire [3:0] sec_1s_2, sec_10s_2, min_1s_2, min_10s_2, hr_1s_2, hr_10s_2;
    
    wire reset_state, up_state, down_state, left_state, right_state;
 
    wire is_win;
    
        btn_debounce dReset(.clk(clk_100MHz), .btn_in(reset), .btn_out(reset_state));
        btn_debounce dUp(.clk(clk_100MHz), .btn_in(btn_Up), .btn_out(up_state));
        btn_debounce dDown(.clk(clk_100MHz), .btn_in(btn_Down), .btn_out(down_state));
        btn_debounce dLeft(.clk(clk_100MHz), .btn_in(btn_Left), .btn_out(left_state));
        btn_debounce dRight(.clk(clk_100MHz), .btn_in(btn_Right), .btn_out(right_state));
                

    initial begin
        hr_10s_best <= 5;
        hr_1s_best <= 9;
        min_10s_best <= 5;
        min_1s_best <= 9;
        sec_10s_best <= 5;
        sec_1s_best <= 9;
    end
    
//    reg restart_game;
//    wire [11:0] rgb_next_2;
    
    // Instantiate Modules
    vga_controller vga(
        .clk_100MHz(clk_100MHz),
        .reset(reset_state),
//        .PAUSE_sw(PAUSE_sw),
        .video_on(video_on),
        .hsync(hsync),
        .vsync(vsync),
        .p_tick(p_tick),
        .x(w_x),
        .y(w_y)
        );
 
    new_binary_clock bin(
        .clk_100MHz(clk_100MHz),
        .reset(reset_state),
        .PAUSE_sw(0),
        .tick_hr(0),
        .tick_min(0),
        .tick_1Hz(),        // not used
        .sec_1s(sec_1s),
        .sec_10s(sec_10s),
        .min_1s(min_1s),
        .min_10s(min_10s),
        .hr_1s(hr_1s),
        .hr_10s(hr_10s),
        .is_win(is_win)
        );

    pixel_clk_gen pclk(
        .clk(clk_100MHz),
        .video_on(video_on),
        //.tick_1Hz(),
        .x(w_x+50),
        .y(w_y),
        .sec_1s(sec_1s),
        .sec_10s(sec_10s),
        .min_1s(min_1s),
        .min_10s(min_10s),
        .hr_1s(hr_1s),
        .hr_10s(hr_10s),
        .PAUSE_sw(0),  // Connect PAUSE_sw signal
        .time_rgb(rgb_next)
        );
        
    pixel_clk_gen_best pclkBest(
    .clk(clk_100MHz),
    .video_on(video_on),
    //.tick_1Hz(),
    .x(w_x - 250),
    .y(w_y),
    .sec_1s(sec_1s_best),
    .sec_10s(sec_10s_best),
    .min_1s(min_1s_best),
    .min_10s(min_10s_best),
    .hr_1s(hr_1s_best),
    .hr_10s(hr_10s_best),
    .PAUSE_sw(1),  // Connect PAUSE_sw signal
    .time_rgb(rgb_next_best)
    );

    wire is_best_score = ((hr_10s_best * 10 + hr_1s_best) * 3600) + ((min_10s_best * 10 + min_1s_best) * 60) + (sec_10s_best * 10 + sec_1s_best) > 
                ((hr_10s * 10 + hr_1s) * 3600) + ((min_10s * 10 + min_1s) * 60) + (sec_10s * 10 + sec_1s);
    
    
    always @(posedge is_win)
        if(is_win & is_best_score) begin
            hr_10s_best <= hr_10s;
            hr_1s_best <= hr_1s;
            min_10s_best <= min_10s;
            min_1s_best <= min_1s;
            sec_10s_best <= sec_10s;
            sec_1s_best <= sec_1s;
        end
            

    wire[11:0] rgb_next_frog;

    frogger frog(.clk(clk_100MHz), .reset(reset_state), .up(up_state), .down(down_state), 
                 .left(left_state), .right(right_state), .video_on(video_on), 
                 .x(w_x), .y(w_y), .rgb(rgb_next_frog), .is_win(is_win));


 
 
    // rgb buffer
    always @(posedge clk_100MHz)
        if(p_tick) begin
            if (rgb_next == 12'h0F0 )
                rgb_reg <= rgb_next;
            else if (rgb_next_best == 12'hF00)
                rgb_reg <= rgb_next_best;
            else  rgb_reg <= rgb_next_frog;
        end
            
    // output
    assign rgb = rgb_reg; 
    
endmodule
