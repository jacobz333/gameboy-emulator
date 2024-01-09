`timescale 1ns / 100ps
/**
 * Timer Module
 *
 * Created: Jacob Zheng 12/02/23
 */


module timer(
        input wire Clk, Reset,
        // from CPU
        input wire  logic [15:0] cpu_addr,
        input wire  logic  [7:0] cpu_wdata,
        output      logic  [7:0] cpu_rdata,
        input wire  logic cpu_we, cpu_re,
        // timer interrupt
        output logic Timer_interrupt
    );

    // 0xFF04
    logic [15:0] DIV_in, DIV;
    logic DIV_en;
    // 0xFF05
    logic [7:0] TIMA_in, TIMA;
    logic TIMA_en;
    // 0xFF06
    logic [7:0] TMA_in, TMA;
    logic TMA_en;
    // 0xFF07
    logic [7:0] TAC_in, TAC;
    logic TAC_en;


    // 0xFF04
    register #(16, 16'h0000) DIVreg(.q(DIV),
                                .d(DIV_in),
                                .load(DIV_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF05
    register #(8, 8'h00) TIMAreg(.q(TIMA),
                                .d(TIMA_in),
                                .load(TIMA_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF06
    register #(8, 8'h00) TMAreg(.q(TMA),
                                .d(TMA_in),
                                .load(TMA_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF07
    register #(8, 8'h00) TACreg(.q(TAC),
                                .d(TAC_in),
                                .load(TAC_en),
                                .clock(Clk),
                                .reset(Reset)
                                );

    // clock bit from DIV
    logic [3:0] clk_sel;
    always_comb begin
        unique case (TAC[1:0])
            2'b00: clk_sel = 4'd9;
            2'b01: clk_sel = 4'd3;
            2'b10: clk_sel = 4'd5;
            2'b11: clk_sel = 4'd7;
        endcase
    end


    always_comb begin
        // defaults
         DIV_in = DIV + 16'h0001; DIV_en = 1'b1; // increment always
        TIMA_in = 8'hZZ; TIMA_en = 1'b0;
         TMA_in = 8'hZZ;  TMA_en = 1'b0;
         TAC_in = 8'hZZ;  TAC_en = 1'b0;

        // return 0xZZ if address not specified
        cpu_rdata = 8'hZZ;

        Timer_interrupt = 1'b0;

        // assign TIMA
        if (TAC[2] && (DIV[clk_sel] & ~DIV_in[clk_sel])) begin // detect falling edge
            TIMA_en = 1'b1;
            if (TIMA + 8'd1 == 8'd0) begin // TIMA overflow
                if (cpu_we && cpu_addr == 16'hFF06) begin // if writing into TMA, use new TMA
                    TIMA_in = cpu_wdata;
                end else begin // otherwise use TMA
                    TIMA_in = TMA;
                end
                Timer_interrupt = 1'b1; // send timer interrupt during overflow to CPU
            end else begin // increment TMA otherwise
                TIMA_in = TIMA + 8'd1;
            end
        end else if (cpu_we && cpu_addr == 16'hFF05) begin // writes onto TIMA
            TIMA_in = cpu_wdata;
            TIMA_en = 1'b1;
        end

        // cpu writes
        if (cpu_we) begin
            case (cpu_addr)
                16'hFF04: begin
                    DIV_in = 16'h0000; // any writes will reset DIV
                end
                16'hFF06: begin
                    TMA_in = cpu_wdata;
                    TMA_en = 1'b1;
                end
                16'hFF07: begin
                    TAC_in = cpu_wdata;
                    TAC_en = 1'b1;
                end
            endcase
        // cpu reads
        end else if (cpu_re) begin
            case (cpu_addr)
                16'hFF04: cpu_rdata = DIV[15:8]; // read only MSB 8
                16'hFF05: cpu_rdata = TIMA; 
                16'hFF06: cpu_rdata = TMA;
                16'hFF07: cpu_rdata = TAC;
            endcase
        end
    end

endmodule
