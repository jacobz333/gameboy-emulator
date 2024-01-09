`timescale 1ns / 100ps
/**
 * Memory Router
 *
 * Created: Jacob Zheng 11/18/23
 */

module memory_router (
    input  wire logic clk_5MHz, clk_25MHz, Reset,
    input  wire logic booting,
    // CPU <-> General Memory (Read/Write)
    input  wire logic [15:0] cpu_addr,
    input  wire logic  [7:0] cpu_wdata,
    output      logic  [7:0] cpu_rdata,
    input  wire logic cpu_re, cpu_we,
    // Cartridge (Read/Write)
    output      logic [15:0] cart_addr,
    output      logic  [7:0] cart_wdata,
    input  wire logic  [7:0] cart_rdata,
    output      logic cart_we, cart_re,
    // CPU <-> PPU (Read/Write)
    output      logic [15:0] ppu_cpu_addr,
    output      logic  [7:0] ppu_cpu_wdata,
    input  wire logic  [7:0] ppu_cpu_rdata,
    output      logic ppu_cpu_we, ppu_cpu_re,
    // PPU (Read)
    input  wire logic [15:0] ppu_addr,
    output      logic  [7:0] ppu_data,
    input  wire logic ppu_re,
    input  wire logic  [1:0] ppu_mode,
    // CPU <-> DMA (Read/Write)
    output      logic [15:0] dma_cpu_addr,
    output      logic  [7:0] dma_cpu_wdata,
    input  wire logic  [7:0] dma_cpu_rdata,
    output      logic dma_cpu_we, dma_cpu_re,
    // DMA (Read/Write)
    input  wire logic [15:0] dma_waddr,
    input  wire logic [15:0] dma_raddr,
    input  wire logic  [7:0] dma_wdata,
    output      logic  [7:0] dma_rdata,
    input  wire logic dma_re, dma_we,
    input  wire logic dma_mode,
    // timer (Read/Write)
    output      logic [15:0] timer_addr,
    output      logic  [7:0] timer_wdata,
    input  wire logic  [7:0] timer_rdata,
    output      logic timer_re, timer_we,
    // joypad JOYP (Read/Write)
    output      logic  [7:0] JOYP_wdata,
    input  wire logic  [7:0] JOYP_rdata,
    output      logic JOYP_we, JOYP_re,
    // IF (Read/Write)
    output      logic  [7:0] IF_wdata,
    input  wire logic  [7:0] IF_rdata,
    output      logic IF_we,
    // IE (Read), Writes handled by CPU
    input  wire logic  [7:0] IE_data
);
    // memories
    logic [7:0] boot_rom_data;
    logic [7:0] boot_rom_addr;
    logic boot_rom_re;
    
    logic [7:0] vram_dout, vram_din;
    logic [12:0] vram_addr;
    logic vram_re, vram_we;
    
    logic [7:0] wram_dout, wram_din;
    logic [12:0] wram_addr;
    logic wram_re, wram_we;
    
    logic [7:0] oam_dout, oam_din;
    logic [7:0] oam_addr;
    logic oam_re, oam_we;


    // select signals
    logic cpu_boot_rom, cpu_cart, cpu_vram, cpu_wram, cpu_oam, cpu_JOYP, cpu_timer, cpu_IF, cpu_ppu, cpu_dma, cpu_IE;
    logic ppu_vram, ppu_oam;
    logic dma_boot_rom, dma_cart, dma_vram, dma_wram, dma_oam;
    
    // cpu conditionals
    assign cpu_boot_rom =  16'h0000 <= cpu_addr && cpu_addr <= 16'h00FF && ( booting) && (dma_mode != 1'b1); // accessible only when booting
    assign cpu_cart     = ((16'h0000 <= cpu_addr && cpu_addr <= 16'h00FF && (!booting)) || // not booting
                          (16'h0100 <= cpu_addr && cpu_addr <= 16'h7FFF)) && (dma_mode != 1'b1);
    assign cpu_vram     =  16'h8000 <= cpu_addr && cpu_addr <= 16'h9FFF && ppu_mode != 2'b11 && (dma_mode != 1'b1); // ppu drawing
    assign cpu_wram     =  16'hC000 <= cpu_addr && cpu_addr <= 16'hDFFF && (dma_mode != 1'b1);
    assign cpu_oam      =  16'hFE00 <= cpu_addr && cpu_addr <= 16'hFE9F && (ppu_mode != 2'b10 && ppu_mode != 2'b11) && (dma_mode != 1'b1); // ppu not in oam search and drawing
    assign cpu_JOYP     =  16'hFF00 == cpu_addr;
    assign cpu_timer    =  16'hFF04 <= cpu_addr && cpu_addr <= 16'hFF07;
    assign cpu_IF       =  16'hFF0F == cpu_addr;
    assign cpu_ppu      =  16'hFF40 <= cpu_addr && cpu_addr <= 16'hFF4B && cpu_addr != 16'hFF46;
    assign cpu_dma      =  16'hFF46 == cpu_addr;
    assign cpu_IE       =  16'hFFFF == cpu_addr;
    // ppu conditionals
    assign ppu_vram     =  16'h8000 <= ppu_addr && ppu_addr <= 16'h9FFF && ppu_mode == 2'b11; // drawing
    assign ppu_oam      =  16'hFE00 <= ppu_addr && ppu_addr <= 16'hFE9F && (ppu_mode == 2'b10 || ppu_mode == 2'b11); // oam search or drawing
    // dma conditionals
    assign dma_boot_rom =  16'h0000 <= dma_raddr && dma_raddr <= 16'h00FF && ( booting) && (dma_mode == 1'b1); // accessible only when booting
    assign dma_cart     = ((16'h0000 <= dma_raddr && dma_raddr <= 16'h00FF && (!booting)) || // not booting
                          (16'h0100 <= dma_raddr && dma_raddr <= 16'h7FFF)) && (dma_mode == 1'b1);
    assign dma_vram     =  16'h8000 <= dma_raddr && dma_raddr <= 16'h9FFF && ppu_mode != 2'b11 && (dma_mode == 1'b1); // ppu drawing
    assign dma_wram     =  16'hC000 <= dma_raddr && dma_raddr <= 16'hDFFF && (dma_mode == 1'b1);
    assign dma_oam      =  16'hFE00 <= dma_waddr && dma_waddr <= 16'hFE9F && (ppu_mode != 2'b10 && ppu_mode != 2'b11) && (dma_mode == 1'b1); // ppu not in oam search and drawing


    // read data
    assign cpu_rdata = (cpu_boot_rom & cpu_re) ? boot_rom_data :
                       (cpu_cart & cpu_re) ? cart_rdata : 
                       (cpu_vram & cpu_re) ? vram_dout : 
                       (cpu_wram & cpu_re) ? wram_dout :
                       (cpu_oam & cpu_re) ? oam_dout :
                       (cpu_JOYP & cpu_re) ? JOYP_rdata : 
                       (cpu_timer & cpu_re) ? timer_rdata : 
                       (cpu_IF & cpu_re) ? IF_rdata :
                       (cpu_ppu & cpu_re) ? ppu_cpu_rdata : 
                       (cpu_dma & cpu_re) ? dma_cpu_rdata :
                       (cpu_IE & cpu_re) ? IE_data : 8'hZZ;
    assign ppu_data  = (ppu_vram & ppu_re) ? vram_dout : 
                       (ppu_oam & ppu_re) ? oam_dout : 8'hZZ;
    assign dma_rdata = (dma_boot_rom & dma_re) ? boot_rom_data :
                       (dma_cart & dma_re) ? cart_rdata : 
                       (dma_vram & dma_re) ? vram_dout : 
                       (dma_wram & dma_re) ? wram_dout : 8'hZZ;


    // assign memory signals
    assign boot_rom_addr = (cpu_boot_rom) ? cpu_addr[7:0] : // shared with dma
                           (dma_boot_rom) ? dma_raddr[7:0] : 8'hZZ;
    assign boot_rom_re = (cpu_boot_rom & cpu_re) | (dma_boot_rom & dma_re);
    
    assign cart_wdata = cpu_wdata;
    assign cart_addr = (cpu_cart) ? cpu_addr : // shared with dma
                       (dma_cart) ? dma_raddr : 16'hZZZZ;
    assign cart_re = (cpu_cart & cpu_re) | (dma_cart & dma_re);
    assign cart_we = (cpu_cart & cpu_we) | (dma_cart & dma_we);

    assign vram_din = cpu_wdata;
    assign vram_addr = (cpu_vram) ? cpu_addr[12:0] :  // shared with dma & ppu
                       (dma_vram) ? dma_raddr[12:0] :
                       (ppu_vram) ? ppu_addr[12:0] : 13'hZZZZ;
    assign vram_re = (cpu_vram & cpu_re) | (dma_vram & dma_re) | (ppu_vram & ppu_re);
    assign vram_we = (cpu_vram & cpu_we);
    
    assign wram_din = cpu_wdata;
    assign wram_addr = (cpu_wram) ? cpu_addr[12:0] :  // shared with dma
                       (dma_wram) ? dma_raddr[12:0] : 13'hZZZZ;
    assign wram_re = (cpu_wram & cpu_re) | (dma_wram & dma_re);
    assign wram_we = cpu_wram & cpu_we;
    
    assign oam_din = (cpu_oam) ? cpu_wdata :
                     (dma_oam) ? dma_wdata : 8'hZZ; // shared with dma & ppu
    assign oam_addr = (cpu_oam) ? cpu_addr[7:0] :
                      (dma_oam) ? dma_waddr[7:0] :
                      (ppu_oam) ? ppu_addr[7:0] : 8'hZZ;
    assign oam_re = (cpu_oam & cpu_re) | (ppu_oam & ppu_re);
    assign oam_we = (cpu_oam & cpu_we) | (dma_oam & dma_we);

    assign JOYP_wdata = cpu_wdata;
    assign JOYP_re = (cpu_JOYP & cpu_re);
    assign JOYP_we = (cpu_JOYP & cpu_we);

    assign timer_wdata = cpu_wdata;
    assign timer_addr = cpu_addr;
    assign timer_re = (cpu_timer & cpu_re);
    assign timer_we = (cpu_timer & cpu_we);

    assign IF_wdata = cpu_wdata;
    assign IF_we = (cpu_IF & cpu_we);
    
    assign ppu_cpu_wdata = cpu_wdata;
    assign ppu_cpu_addr = cpu_addr;
    assign ppu_cpu_re = (cpu_ppu & cpu_re);
    assign ppu_cpu_we = (cpu_ppu & cpu_we);
    
    assign dma_cpu_wdata = cpu_wdata;
    assign dma_cpu_addr = cpu_addr;
    assign dma_cpu_re = (cpu_dma & cpu_re);
    assign dma_cpu_we = (cpu_dma & cpu_we);

    
    boot_rom Boot_Rom(.addr(boot_rom_addr),
                      .data(boot_rom_data),
                      .en(boot_rom_re)
                      );

    vram VRAM(.clk(clk_25MHz), // emulate BRAM
              .en(vram_we | vram_re),
              .we(vram_we),
              .reset(Reset),
              .addr(vram_addr),
              .din(vram_din),
              .dout(vram_dout)
              );

    wram WRAM(.clk(clk_25MHz), // emulate BRAM
              .en(wram_we | wram_re),
              .we(wram_we),
              .reset(Reset),
              .addr(wram_addr),
              .din(wram_din),
              .dout(wram_dout)
              );

    oam OAM(.clk(clk_25MHz), // emulate BRAM
            .en(oam_we | oam_re),
            .we(oam_we),
            .reset(Reset),
            .addr(oam_addr),
            .din(oam_din),
            .dout(oam_dout)
            );

endmodule
