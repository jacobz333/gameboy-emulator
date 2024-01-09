`timescale 1ns / 100ps
/**
 * Button I/O
 *
 * Created: Jacob Zheng 12/02/23
 */

module button_io (
    // buttons, active high input
    input wire [31:0] keycodes,
    // input wire logic START, SELECT, A, B, UP, DOWN, LEFT, RIGHT,

    input wire logic clk, reset, re, we,
    input wire logic [7:0] JOYP_din,
    output logic [7:0] JOYP_dout,

    output logic JOYP_interrupt
);
    logic START, SELECT, A, B, UP, DOWN, LEFT, RIGHT; // active high buttons

    // assign keycode -> button
    assign  START = (keycodes[7:0] == 8'h28) | (keycodes[15:8] == 8'h28) | (keycodes[23:16] == 8'h28) | (keycodes[31:24] == 8'h28); // enter
    assign SELECT = (keycodes[7:0] == 8'h16) | (keycodes[15:8] == 8'h16) | (keycodes[23:16] == 8'h16) | (keycodes[31:24] == 8'h16); // s
    assign      A = (keycodes[7:0] == 8'h04) | (keycodes[15:8] == 8'h04) | (keycodes[23:16] == 8'h04) | (keycodes[31:24] == 8'h04); // A
    assign      B = (keycodes[7:0] == 8'h1D) | (keycodes[15:8] == 8'h1D) | (keycodes[23:16] == 8'h1D) | (keycodes[31:24] == 8'h1D); // B
    assign     UP = (keycodes[7:0] == 8'h52) | (keycodes[15:8] == 8'h52) | (keycodes[23:16] == 8'h52) | (keycodes[31:24] == 8'h52); // up
    assign   DOWN = (keycodes[7:0] == 8'h51) | (keycodes[15:8] == 8'h51) | (keycodes[23:16] == 8'h51) | (keycodes[31:24] == 8'h51); // down
    assign   LEFT = (keycodes[7:0] == 8'h50) | (keycodes[15:8] == 8'h50) | (keycodes[23:16] == 8'h50) | (keycodes[31:24] == 8'h50); // left
    assign  RIGHT = (keycodes[7:0] == 8'h4F) | (keycodes[15:8] == 8'h4F) | (keycodes[23:16] == 8'h4F) | (keycodes[31:24] == 8'h4F); // right


    logic [3:0] JOYP_last[2]; // last state of the buttons
    logic [3:0] JOYP[2]; // current state of buttons
    logic [1:0] JOYP_sel;

    always_ff @(posedge clk) begin
        if (reset) begin
            JOYP_sel <= 2'b00;
        end else if (we) begin
            JOYP_sel <= JOYP_din[5:4];
        end

        JOYP_last <= JOYP; // constantly update JOYP
    end


    always_comb begin
        // assign button matrix
        JOYP[1] = {~START, ~SELECT, ~B, ~A};
        JOYP[0] = {~DOWN, ~UP, ~LEFT, ~RIGHT};
        
        // unique case (JOYP_sel)
        //     2'b00: JOYP = {~START, ~SELECT, ~B, ~A};    // both selected, select button > d-pad button
        //     2'b01: JOYP = {~START, ~SELECT, ~B, ~A};    // select buttons (active low)
        //     2'b10: JOYP = {~DOWN, ~UP, ~LEFT, ~RIGHT};  // d-pad buttons (active low)
        //     2'b11: JOYP = 4'hF;                         // neither
        // endcase

        // assign JOYP_dout
        if (re) begin
            unique case (JOYP_sel)
                2'b00: JOYP_dout = {2'b00, JOYP_sel, JOYP[1]};    // both selected, select button > d-pad button
                2'b01: JOYP_dout = {2'b00, JOYP_sel, JOYP[1]};    // select buttons (active low)
                2'b10: JOYP_dout = {2'b00, JOYP_sel, JOYP[0]};    // d-pad buttons (active low)
                2'b11: JOYP_dout = {2'b00, JOYP_sel, 4'hF};       // neither
            endcase
        end else begin // not reading
            JOYP_dout = 8'hZZ;
        end

        // assign JOYP_interrupt, check falling edge, (button press)
        unique case (JOYP_sel)
            2'b00: JOYP_interrupt = (JOYP_last[1][0] & ~JOYP[1][0]) | // both selected, select button > d-pad button
                                    (JOYP_last[1][1] & ~JOYP[1][1]) |
                                    (JOYP_last[1][2] & ~JOYP[1][2]) |
                                    (JOYP_last[1][3] & ~JOYP[1][3]);
            2'b01: JOYP_interrupt = (JOYP_last[1][0] & ~JOYP[1][0]) | // select buttons (active low)
                                    (JOYP_last[1][1] & ~JOYP[1][1]) |
                                    (JOYP_last[1][2] & ~JOYP[1][2]) |
                                    (JOYP_last[1][3] & ~JOYP[1][3]);
            2'b10: JOYP_interrupt = (JOYP_last[0][0] & ~JOYP[0][0]) | // d-pad buttons (active low)
                                    (JOYP_last[0][1] & ~JOYP[0][1]) |
                                    (JOYP_last[0][2] & ~JOYP[0][2]) |
                                    (JOYP_last[0][3] & ~JOYP[0][3]);  
            2'b11: JOYP_interrupt = 1'b0;       // neither
        endcase

        // JOYP_interrupt = (JOYP_last[0][0] & ~JOYP[0][0]) | 
        //                  (JOYP_last[0][1] & ~JOYP[0][1]) |
        //                  (JOYP_last[0][2] & ~JOYP[0][2]) |
        //                  (JOYP_last[0][3] & ~JOYP[0][3]) |
        //                  (JOYP_last[1][0] & ~JOYP[1][0]) | 
        //                  (JOYP_last[1][1] & ~JOYP[1][1]) |
        //                  (JOYP_last[1][2] & ~JOYP[1][2]) |
        //                  (JOYP_last[1][3] & ~JOYP[1][3]);
    end
    

endmodule
