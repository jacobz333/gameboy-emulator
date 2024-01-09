`timescale 1ns / 100ps
/**
 * Cartridge Module
 *
 * Created: Jacob Zheng 12/06/23
 */

module cartridge (
        input  wire logic Clk, Reset,
        // select game from switches
        input  wire logic  [1:0] sel,
        // memory bus
        input  wire logic [15:0] addr,
        input  wire logic  [7:0] wdata,
        output      logic  [7:0] rdata,
        input  wire logic re, we
);
    // tetris MBC0, read only, 2 banks, no switching, 32kB
    logic [14:0] tetris_addr;
    logic  [7:0] tetris_data;
    logic tetris_re;
    // super mario MBC1, read only, 4 bank, 64kB
    logic [15:0] mario_addr;
    logic  [7:0] mario_data;
    // galaga MBC1, read only, 8 banks, 128kB
    logic [16:0] galaga_addr;
    logic  [7:0] galaga_data;
    logic galaga_re;

    // game ROMs
    tetris_rom Tetris_ROM(.addra(tetris_addr),
                         .douta(tetris_data),
                         .ena(tetris_re),
                         .clka(Clk)
                         );

    super_mario_rom Mario_ROM(.a(mario_addr), // distributed memory does not require clocks/enables
                              .spo(mario_data)
                              );

    galaga_rom Galaga_ROM(.addra(galaga_addr),
                          .douta(galaga_data),
                          .ena(galaga_re),
                          .clka(Clk)
                          );

    // MBC controller register
    logic  [4:0] ROM_bank_in, ROM_bank;
    logic ROM_bank_load;
    
    register #(5, 5'h01) ROM_bankreg(.q(ROM_bank),
                                     .d(ROM_bank_in),
                                     .load(ROM_bank_load),
                                     .clock(Clk),
                                     .reset(Reset)
                                     );
    
    // assign ROM_bank
    always_comb begin
        ROM_bank_in = 5'hZZ; ROM_bank_load = 1'b0;
        
        unique case (sel)
            2'b00: begin // nothing
            end
            2'b01: begin // unused
            end
            2'b10: begin // 4 banks, need 2 bits
                ROM_bank_load = we && (16'h2000 <= addr && addr <= 16'h3FFF);
                ROM_bank_in = (wdata[1:0] != 2'h0) ? wdata[1:0] : 2'h1; // rom bank number cannot be zero
            end
            2'b11: begin // 8 banks, need 3 bits
                ROM_bank_load = we && (16'h2000 <= addr && addr <= 16'h3FFF);
                ROM_bank_in = (wdata[2:0] != 3'h0) ? wdata[2:0] : 3'h1; // rom bank number cannot be zero
            end
        endcase
    end

    // assign memory buses
    always_comb begin
        // defaults
        tetris_addr = 15'hZZZZ; tetris_re = 1'b0;
         mario_addr = 16'hZZZZ;
        galaga_addr = 17'hZZZZ; galaga_re = 1'b0;

        rdata = 8'hZZ;

        unique case (sel)
            2'b00: begin // nothing
            end
            2'b01: begin // 2 banks, no MBC
                tetris_addr = addr[14:0];
                rdata = tetris_data;
                tetris_re = re;
            end
            2'b10: begin // 4 banks, MBC controls MSB 2
                mario_addr = (16'h0000 <= addr && addr <= 16'h3FFF) ? {2'b00, addr[13:0]} : {ROM_bank[1:0], addr[13:0]};
                rdata = (re) ? mario_data : 8'hZZ;
            end
            2'b11: begin // 8 banks, MBC controls MSB 3
                galaga_addr = (16'h0000 <= addr && addr <= 16'h3FFF) ? {3'b000, addr[13:0]} : {ROM_bank[2:0], addr[13:0]};
                rdata = galaga_data;
                galaga_re = re;
            end
        endcase
    end

endmodule
