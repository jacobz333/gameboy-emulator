`timescale 1ns / 100ps
/**
 * OAM memory with enable and reset
 *
 * Created: Jacob Zheng 12/01/23
 */

module oam (
    input wire logic clk, en, we, reset,
    input wire logic [7:0] addr,
    input wire logic [7:0] din,
    output logic [7:0] dout
);
    
    logic [7:0] mem[160];
    
    always @(posedge clk) begin
        if (reset) begin
            dout <= 8'h00;
        end else if (en & we) begin // write 
            mem[addr] <= din;
        end else if (en) begin // read
            dout <= mem[addr];
        end else begin
            dout <= 8'hZZ;
        end
    end

endmodule