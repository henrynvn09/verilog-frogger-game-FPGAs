module frogger(
    input clk,
    input up,
    input down,
    input left,
    input right,
    input reset,
    input video_on,                         // from VGA controller
    input [9:0] x, y,                       // from VGA controller
    output reg [11:0] rgb,                  // to DAC, to VGA controller
    output reg is_win                      // if the player wins
   
    );
    
    parameter X_MAX = 639;                  // right border of display area
    parameter Y_MAX = 479;                  // bottom border of display area
    parameter OBSTACLE_RGB = 12'h912;       // red & green = yellow for obstacle
    parameter BG_RGB = 12'h045;             // blue background
    parameter FROG_RGB = 12'h5B0;           // color for frog

    parameter board_X_MAX = 400;            // right border of display area
    parameter board_X_MIN = 50;              // left border of display area
    parameter board_Y_MAX = 400;            // bottom border of display area
    parameter board_Y_MIN = 10;              // top border of display area

    parameter FROG_SIZE = 6; // This is actually half size of the frog
    parameter FROG_X_START = 200;
    parameter FROG_Y_START = board_Y_MAX - FROG_SIZE;
    parameter FROG_VELOCITY = 2;
    
    parameter OBSTACLE_SIZE = 8;  // This is actually half size of an obstacle
    
    reg [9:0] OBSTACLE_VELOCITIES [9:0];  // Velocities of obstacles
    reg [9:0] obstacle_X [9:0]; // Starting X positions of obstacles
    reg [9:0] obstacle_Y [9:0]; // Starting Y positions of obstacles
    reg obstacle_direction [9:0]; // 0: left to right, 1: right to left

    integer score, i;
    reg [9:0] frog_x, frog_y;
    
    // create a 60Hz refresh tick at the start of vsync 
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0;
    
    initial begin
        frog_x = FROG_X_START;
        frog_y = FROG_Y_START;

        // Set the initial direction of obstacles
        obstacle_direction[0] = 0; obstacle_direction[1] = 0; obstacle_direction[2] = 0;
        obstacle_direction[3] = 0; obstacle_direction[4] = 0; obstacle_direction[5] = 0;
        obstacle_direction[6] = 0; obstacle_direction[7] = 0; obstacle_direction[8] = 0;
        obstacle_direction[9] = 0;

        // OBSTACLE_VELOCITIES
        OBSTACLE_VELOCITIES[0] = -1; OBSTACLE_VELOCITIES[1] = 1; OBSTACLE_VELOCITIES[2] = -1;
        OBSTACLE_VELOCITIES[3] = 1; OBSTACLE_VELOCITIES[4] = -2; OBSTACLE_VELOCITIES[5] = 2;
        OBSTACLE_VELOCITIES[6] = -1; OBSTACLE_VELOCITIES[7] = 2; OBSTACLE_VELOCITIES[8] = -2;
        OBSTACLE_VELOCITIES[9] = 3;


        // obstacle_X
        obstacle_X[0] = 100; obstacle_X[1] = 100; obstacle_X[2] = 360;
        obstacle_X[3] = 350; obstacle_X[4] = 250; obstacle_X[5] = 150;
        obstacle_X[6] = 350; obstacle_X[7] = 370; obstacle_X[8] = 220;
        obstacle_X[9] = 380;

        // obstacle_Y
        obstacle_Y[0] = 360; obstacle_Y[1] = 330; obstacle_Y[2] = 310;
        obstacle_Y[3] = 290; obstacle_Y[4] = 200; obstacle_Y[5] = 170;
        obstacle_Y[6] = 140; obstacle_Y[7] = 110; obstacle_Y[8] = 85;
        obstacle_Y[9] = 60;

    end
    
    
    // Frog Control
    always @(posedge clk or posedge reset)
        if(reset) begin
            frog_x <= FROG_X_START;
            frog_y <= FROG_Y_START;
            score <= 0;
        end
        else begin
            if (refresh_tick) begin
                if (is_win == 1) is_win = 0;

                // Check collision with obstacles
                for (i = 0; i < 10; i = i + 1) begin
                    if ((obstacle_X[i] - OBSTACLE_SIZE - FROG_SIZE <= frog_x) && (frog_x <= obstacle_X[i] + OBSTACLE_SIZE + FROG_SIZE) &&
                        (obstacle_Y[i] - OBSTACLE_SIZE - FROG_SIZE <= frog_y) && (frog_y <= obstacle_Y[i] + OBSTACLE_SIZE + FROG_SIZE)) begin
                        // Reset frog position
                        frog_x <= FROG_X_START;
                        frog_y <= FROG_Y_START;
                    end
                end


                // move the frog
                if (down && (frog_y + FROG_SIZE < board_Y_MAX))
                    frog_y <= frog_y + FROG_VELOCITY;
                else if (up && (frog_y - FROG_SIZE > board_Y_MIN))
                    frog_y <= frog_y - FROG_VELOCITY;
                else if (left && (frog_x - FROG_SIZE > board_X_MIN))
                    frog_x <= frog_x - FROG_VELOCITY;
                else if (right && (frog_x + FROG_SIZE < board_X_MAX))
                    frog_x <= frog_x + FROG_VELOCITY;

                if (frog_y - FROG_SIZE <= board_Y_MIN) begin
                    // Frog reached the top, record high score
                    frog_x <= FROG_X_START;
                    frog_y <= FROG_Y_START;
                    is_win <= 1;
                end
                
                // Move the obstacles
                for (i = 0; i < 10; i = i + 1) begin
                    if (obstacle_direction[i] == 0) begin
                        // Move left to right
                        obstacle_X[i] <= obstacle_X[i] + OBSTACLE_VELOCITIES[i];
                        if (obstacle_X[i] >= board_X_MAX - OBSTACLE_SIZE)
                            obstacle_direction[i] <= 1; // Change direction
                    end else begin
                        // Move right to left
                        obstacle_X[i] <= obstacle_X[i] - OBSTACLE_VELOCITIES[i];
                        if (obstacle_X[i] <= board_X_MIN)
                            obstacle_direction[i] <= 0; // Change direction
                    end
                end
            end
        end

    // RGB control
    always @*
        if(~video_on)
            rgb = 12'h000;          // black(no value) outside display area
        else if ((board_X_MIN <= x) && (x <= board_X_MAX) &&
                 (board_Y_MIN <= y) && (y <= board_Y_MAX)) begin
            rgb = BG_RGB;

            // Draw the frog
            if ((frog_x - FROG_SIZE <= x) && (x <= frog_x + FROG_SIZE) &&
                (frog_y - FROG_SIZE <= y) && (y <= frog_y + FROG_SIZE))
                rgb = FROG_RGB;
            
            // Draw the obstacles
            for (i = 0; i < 10; i = i + 1) begin
                if ((obstacle_X[i] - OBSTACLE_SIZE <= x) && (x <= obstacle_X[i] + OBSTACLE_SIZE) &&
                    (obstacle_Y[i] - OBSTACLE_SIZE <= y) && (y <= obstacle_Y[i] + OBSTACLE_SIZE)) begin
                    rgb = OBSTACLE_RGB;
                end
            end


        end
        else
            rgb = 12'h000;          // black(outside board)
    endmodule
