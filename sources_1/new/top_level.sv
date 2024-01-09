`timescale 1ns / 100ps

module top_level (
        input  logic  Clk, Reset,
        // buttons
        input  logic [15:0] sw,

        output logic [15:0] led,
        
        //USB signals
        input  logic [0:0] gpio_usb_int_tri_i,
        output logic gpio_usb_rst_tri_o,
        input  logic usb_spi_miso,
        output logic usb_spi_mosi,
        output logic usb_spi_sclk,
        output logic usb_spi_ss,
        
        //UART
        input  logic uart_rtl_0_rxd,
        output logic uart_rtl_0_txd,
        
        // HDMI
        output logic hdmi_tmds_clk_n,
        output logic hdmi_tmds_clk_p,
        output logic [2:0] hdmi_tmds_data_n,
        output logic [2:0] hdmi_tmds_data_p,
        
        //Hexs
        output logic [7:0] hex_segA,
        output logic [3:0] hex_gridA,
        output logic [7:0] hex_segB,
        output logic [3:0] hex_gridB
    );
    
    logic clk_5MHz, clk_25MHz, clk_125MHz, clk_15MHz; // Clocks
    logic [31:0] keycode0_gpio, keycode1_gpio; // keycodes
    
    logic locked; // ???
    logic [9:0] drawX, drawY; // VGA -> color mapper
    logic hsync, vsync, vde; // from VGA controller
    logic [4:0] red, green, blue; // VGA -> color mapper -> HDMI
    
    // cpu memory bus
    wire logic [15:0] cpu_addr;
    wire logic [7:0]  cpu_data;
    logic cpu_we_l, cpu_re_l;
    // cartridge memory bus
    logic [15:0] cart_addr;
    logic [7:0] cart_wdata, cart_rdata;
    logic cart_we, cart_re;
    // cpu-ppu memory bus
    logic [15:0] ppu_cpu_addr;
    logic [7:0] ppu_cpu_wdata, ppu_cpu_rdata;
    logic ppu_cpu_we, ppu_cpu_re;
    // cpu-dma memory bus
    logic [15:0] dma_cpu_addr;
    logic [7:0] dma_cpu_wdata, dma_cpu_rdata;
    logic dma_cpu_we, dma_cpu_re;
    // dma memory bus
    logic [15:0] dma_waddr, dma_raddr;
    logic [7:0] dma_rdata, dma_wdata;
    logic dma_re, dma_we;
    logic dma_mode;
    // ppu memory bus
    logic [15:0] ppu_addr;
    logic [7:0]  ppu_data;
    logic ppu_re;
    logic [1:0] ppu_mode;
    // timer bus
    logic [15:0] timer_addr;
    logic [7:0] timer_wdata, timer_rdata;
    logic timer_we, timer_re;
    // joypad JOYP bus
    logic [7:0] JOYP_wdata, JOYP_rdata;
    logic JOYP_we, JOYP_re;


    // PPU -> LCD frame buffer
    logic [14:0] LCD_addr;
    logic [14:0] LCD_data;
    logic LCD_we;
    // LCD frame buffer -> VGA
    logic [14:0] VGA_addr;
    logic [14:0] VGA_data;
    logic VGA_fetch;
    

    // interrupts
    logic [4:0] IF_data, IE_data;
    logic [4:0] IF_in;
    logic IF_load;
    
    logic JOYP_interrupt, Serial_interrupt, Timer_interrupt, STAT_interrupt, VBlank_interrupt;
    logic [7:0] IF_wdata;
    logic IF_we;
    assign Serial_interrupt = 1'b0; // not implemented


    logic booting;
    logic [15:0] PC;
    logic [7:0] test0, test1;
    assign led[0] = Reset;
    assign led[2:1] = sw[1:0];
    assign led[15:3] = 13'h130F;

    // assign booting
    always_ff @ (posedge clk_5MHz) begin    
        if (Reset) begin // set to booting=1 upon reset
            booting <= 1'b1;
        end else if (booting && (PC == 16'h0100)) begin // stop booting when PC reaches 0x0100
            booting <= 1'b0;
        end
    end
    
    memory_router memory_router(.clk_5MHz(clk_5MHz),
                                .clk_25MHz(clk_25MHz),
                                .Reset(Reset),
                                .booting(booting),
                                // CPU <-> General Memory (Read/Write)
                                .cpu_addr(cpu_addr),
                                .cpu_wdata(cpu_data),
                                .cpu_rdata(cpu_data),
                                .cpu_re(~cpu_re_l), // given CPU outputs active lows
                                .cpu_we(~cpu_we_l),
                                // Cartridge (Read/Write)
                                .cart_addr(cart_addr),
                                .cart_wdata(cart_wdata),
                                .cart_rdata(cart_rdata),
                                .cart_we(cart_we),
                                .cart_re(cart_re),
                                // CPU <-> PPU (Read/Write)
                                .ppu_cpu_addr(ppu_cpu_addr),
                                .ppu_cpu_wdata(ppu_cpu_wdata),
                                .ppu_cpu_rdata(ppu_cpu_rdata),
                                .ppu_cpu_we(ppu_cpu_we),
                                .ppu_cpu_re(ppu_cpu_re),
                                // PPU (Read)
                                .ppu_addr(ppu_addr),
                                .ppu_data(ppu_data),
                                .ppu_re(ppu_re),
                                .ppu_mode(ppu_mode),
                                // CPU <-> DMA (Read/Write)
                                .dma_cpu_addr(dma_cpu_addr),
                                .dma_cpu_wdata(dma_cpu_wdata),
                                .dma_cpu_rdata(dma_cpu_rdata),
                                .dma_cpu_we(dma_cpu_we),
                                .dma_cpu_re(dma_cpu_re),
                                // DMA (Read/Write)
                                .dma_waddr(dma_waddr),
                                .dma_raddr(dma_raddr),
                                .dma_wdata(dma_wdata),
                                .dma_rdata(dma_rdata),
                                .dma_re(dma_re),
                                .dma_we(dma_we),
                                .dma_mode(dma_mode),
                                // timer (Read/Write)
                                .timer_addr(timer_addr),
                                .timer_wdata(timer_wdata),
                                .timer_rdata(timer_rdata),
                                .timer_we(timer_we),
                                .timer_re(timer_re),
                                // joypad JOYP (Read/Write)
                                .JOYP_wdata(JOYP_wdata),
                                .JOYP_rdata(JOYP_rdata),
                                .JOYP_we(JOYP_we),
                                .JOYP_re(JOYP_re),
                                // IF (Read), Writes go thru Interrupt Module
                                .IF_wdata(IF_wdata),
                                .IF_rdata({3'b000, IF_data}),
                                .IF_we(IF_we),
                                // IE (Read), Writes handled by CPU
                                .IE_data({3'b000, IE_data})
                                );
    
    ppu gbc_ppu(.Clk(clk_5MHz),
                .Reset(Reset),
                // CPU writing/reading to PPU
                .cpu_addr(ppu_cpu_addr),
                .cpu_wdata(ppu_cpu_wdata),
                .cpu_rdata(ppu_cpu_rdata),
                .cpu_we(ppu_cpu_we),
                .cpu_re(ppu_cpu_re),
                // PPU reading from VRAM or OAM
                .ppu_addr(ppu_addr),
                .ppu_data(ppu_data),
                .ppu_re(ppu_re),
                // PPU writing onto LCD frame buffer
                .LCD_addr(LCD_addr),
                .LCD_data(LCD_data),
                .LCD_we(LCD_we),
                
                .mode(ppu_mode), // send to memory router
                
                // VBlank/STAT interrupts
                .VBlank_interrupt(VBlank_interrupt),
                .STAT_interrupt(STAT_interrupt),
                
                // test signals
                .test0(test0),
                .test1(test1)
                );
    
    cpu gbc_cpu(.mem_we_l(cpu_we_l), // output
                .mem_re_l(cpu_re_l), // output
                .IF_data(IF_data), // output
                .IE_data(IE_data), // output
                .addr_ext(cpu_addr), // inout
                .data_ext(cpu_data), // inout
                .IF_in(IF_in), // input from Interrupt module
                .IE_in(5'h00), // CPU controlled
                .IF_load(IF_load), // input from Interrupt module
                .IE_load(1'b0), // CPU controlled
                .cpu_mem_disable(Reset), // input
                .ext_halt(Reset), // input
                .bp_addr(16'hFFFF), // input
                .bp_step(1'b0), // input
                .bp_continue(1'b0), // input
                .clock(clk_5MHz), // input
                .reset(Reset), // input
                
                .PC(PC) // output, program counter
                );
    
    timer Timer(.Clk(clk_5MHz),
                .Reset(Reset),
                // from CPU
                .cpu_addr(timer_addr),
                .cpu_wdata(timer_wdata),
                .cpu_rdata(timer_rdata),
                .cpu_we(timer_we),
                .cpu_re(timer_re),
                // timer interrupt
                .Timer_interrupt(Timer_interrupt)
                );

    button_io JOYPreg(.keycodes(keycode0_gpio),
                      // JOYP register read/write
                      .clk(clk_5MHz),
                      .reset(Reset),
                      .re(JOYP_re),
                      .we(JOYP_we),
                      .JOYP_din(JOYP_wdata),
                      .JOYP_dout(JOYP_rdata),
                      // JOYP interrupt
                      .JOYP_interrupt(JOYP_interrupt)
                      );

    interrupt Interrupt(.JOYP_interrupt(JOYP_interrupt),
                        .Serial_interrupt(Serial_interrupt),
                        .Timer_interrupt(Timer_interrupt),
                        .STAT_interrupt(STAT_interrupt),
                        .VBlank_interrupt(VBlank_interrupt),
                        .cpu_IF_we(IF_we), // (input) writing from CPU
                        .IF_din(IF_wdata), // (input) write data from CPU
                        .IF_data(IF_data), // (input) current IF_data (from CPU)
                        .IF_load(IF_load), // (output) loads to CPU
                        .IF_dout(IF_in)    // (output) writes to CPU
                        );

    dma DMA(.Clk(clk_5MHz),
            .Reset(Reset),
            // CPU writing/reading to DMA
            .cpu_addr(dma_cpu_addr),
            .cpu_wdata(dma_cpu_wdata),
            .cpu_rdata(dma_cpu_rdata),
            .cpu_we(dma_cpu_we),
            .cpu_re(dma_cpu_re),
            // DMA transfer bus
            .dma_waddr(dma_waddr),
            .dma_raddr(dma_raddr),
            .dma_wdata(dma_wdata),
            .dma_rdata(dma_rdata),
            .dma_re(dma_re),
            .dma_we(dma_we),
            // 0 = none, 1 = transfer
            .dma_mode(dma_mode) // send to memory router
            );
    
    cartridge Cartridge(.Clk(clk_25MHz),
                        .Reset(Reset),
                        // select game from switches
                        .sel(sw[1:0]),
                        // cartridge memory bus
                        .addr(cart_addr),
                        .wdata(cart_wdata),
                        .rdata(cart_rdata),
                        .re(cart_re),
                        .we(cart_we)
                        );

    clk_wiz_0 clk_wiz (
        .clk_5MHz(clk_5MHz),
        .clk_25MHz(clk_25MHz),
        .clk_125MHz(clk_125MHz),
        .reset(1'b0),
        .locked(locked),
        .clk_in1(Clk)
        // originally Clk, but cannot assign clocks else Vivado won't synthesize
    );

    // Frame Buffer
    frame_buffer FrameBuffer(.clka(clk_25MHz), // LCD write only
                             .ena(LCD_we),
                             .wea(LCD_we),
                             .addra(LCD_addr),
                             .dina(LCD_data),
                             .douta(),
                             .clkb(clk_25MHz), // VGA read only
                             .enb(VGA_fetch),
                             .web(1'b0),
                             .addrb(VGA_addr),
                             .dinb(15'hZZZ),
                             .doutb(VGA_data)
                             );
    
    color_mapper ColorMapper(.VGAX(drawX),
                            .VGAY(drawY),
                            .VGA_addr(VGA_addr),
                            .VGA_data(VGA_data),
                            .VGA_fetch(VGA_fetch),
                            .Red(red),
                            .Green(green),
                            .Blue(blue) );

    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(1'b0),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );

    // VGA to HDMI IP
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active 
        .rst(1'b0),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),

        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),

        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),
        .TMDS_CLK_N(hdmi_tmds_clk_n),
        .TMDS_DATA_P(hdmi_tmds_data_p),
        .TMDS_DATA_N(hdmi_tmds_data_n)
    );
    
    // USB MicroBlaze
    mb_usb mb_block_i(
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~Reset), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
    
    // hex drivers
    HexDriver HexA (
        .clk(clk_25MHz),
        .reset(Reset),
        .in({PC[15:12], PC[11:8], PC[7:4], PC[3:0]}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );
    HexDriver HexB (
        .clk(clk_25MHz),
        .reset(Reset),
        .in({test0[7:4], test0[3:0], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );

endmodule