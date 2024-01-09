/**
 * Frame Buffer True Dual Port
 * Follows tutorial
 *
 * Created: Jacob Zheng 11/20/23
 */

module frame_buffer (
    input wire logic clka, ena, wea,
                     clkb, enb, web,
    input wire logic [14:0] addra, addrb,
    input wire logic [14:0] dina,  dinb,
    output     logic [14:0] douta, doutb
);

    logic [14:0] mem[46080];
    
    always @(posedge clka) begin
        if (ena & wea) begin // write 
            mem[addra] <= dina;
        end else if (ena) begin // read
            douta <= mem[addra];
        end
    end

    always @(posedge clkb) begin
        if (enb & web) begin // write 
            mem[addrb] <= dinb;
        end else if (enb) begin // read
            doutb <= mem[addrb];
        end
    end

endmodule