`timescale 1ns / 100ps
/**
 * Interrupt Module
 *
 * Created: Jacob Zheng 12/03/23
 */

module interrupt(
    input wire logic JOYP_interrupt, Serial_interrupt, Timer_interrupt, STAT_interrupt, VBlank_interrupt,

    input wire logic cpu_IF_we,     // (input) writing from CPU
    input wire logic [7:0] IF_din,  // (input) write data from CPU
    input wire logic [4:0] IF_data, // (input) current IF_data (from CPU)
    output     logic IF_load,       // (output) loads to CPU
    output     logic [4:0] IF_dout  // (output) writes to CPU
);

    assign IF_load = (~IF_data[0] & VBlank_interrupt) | // rising edge detection
                     (~IF_data[1] & STAT_interrupt) |
                     (~IF_data[2] & Timer_interrupt) |
                     (~IF_data[3] & Serial_interrupt) |
                     (~IF_data[4] & JOYP_interrupt) |
                     cpu_IF_we; // cpu writing
    
    // CPU writes override interrupts
    assign IF_dout[0] = (cpu_IF_we) ? IF_din[0] : VBlank_interrupt;
    assign IF_dout[1] = (cpu_IF_we) ? IF_din[1] : STAT_interrupt;
    assign IF_dout[2] = (cpu_IF_we) ? IF_din[2] : Timer_interrupt;
    assign IF_dout[3] = (cpu_IF_we) ? IF_din[3] : Serial_interrupt;
    assign IF_dout[4] = (cpu_IF_we) ? IF_din[4] : JOYP_interrupt;

endmodule
