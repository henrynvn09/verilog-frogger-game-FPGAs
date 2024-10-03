# FPGA Frogger Game with VGA Display

## Demo

https://github.com/user-attachments/assets/ce7145be-58ab-47a0-aa97-528e5aff7fb5

## Introduction

This project implements a version of the classic Frogger game using an FPGA, with output displayed on a VGA monitor. The game allows the player to control a frog, avoiding obstacles to reach the top of the screen. The player's time is tracked, and high scores are saved. Movement and interactions are managed using the FPGA buttons.

## Features
- **Frog Movement**: Controlled by FPGA buttons (up, down, left, right).
- **Obstacle Movement**: Obstacles move horizontally at different speeds.
- **Collision Detection**: The frog returns to the start if hit by an obstacle.
- **VGA Display**: Displays frog, obstacles, timer, and high score.
- **High Score Tracking**: Saves the fastest time.
- **Reset**: Reset button returns frog to start and resets the timer.

## Design Overview

### Key Modules:
1. **Clock_digit_rom**: Encodes digits for display on VGA.
2. **Pixel_clk_gen**: Places stopwatch digits on the screen and sets RGB values.
3. **Pixel_clk_gen_best**: Displays the high score stopwatch using custom logic.
4. **New_binary_clk**: Implements counters for minutes, seconds, and milliseconds.
5. **Vga_controller**: Sets up VGA signal parameters and resolution.
6. **Top.v**: Main module that integrates the game, stopwatches, and VGA display.
7. **Btn_debounce**: Handles button debouncing for reliable input.

### Frogger Module:
- **Frog Control**: Moves the frog based on button input, resets on collision.
- **Obstacle Movement**: Obstacles move horizontally and reset upon reaching edges.
- **Collision Detection**: Checks if the frog collides with obstacles.
- **Winning Check**: Detects if the frog reaches the top of the screen.

## Simulation and Testing
Verilog simulations were used to verify functionality, focusing on:
- Frog movement and obstacle interaction.
- Accurate time tracking and high score display.

### Known Challenges:
- Issues with shifting in 2D arrays.
- Difficulties instantiating multiple `Pixel_clk_gen` modules.

## Citations
- Original Frogger Game
- Stopwatch Repository
- Bouncing Square Repository

