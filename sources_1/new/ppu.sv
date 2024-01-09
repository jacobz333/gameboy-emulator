`timescale 1ns / 100ps

module ppu (
    input wire Clk, Reset,
    // CPU writing/reading to PPU
    input wire  logic [15:0] cpu_addr,
    input wire  logic  [7:0] cpu_wdata,
    output      logic  [7:0] cpu_rdata,
    input wire  logic cpu_we, cpu_re,
    // PPU reading from VRAM or OAM
    output      logic [15:0] ppu_addr,
    input  wire logic  [7:0] ppu_data,
    output      logic ppu_re,
    // PPU writing onto LCD frame buffer
    output logic [14:0] LCD_addr,
    output logic [14:0] LCD_data,
    output logic LCD_we,
    // PPU mode for memory router
    output logic [1:0] mode,
    // interrupts to the CPU
    output logic VBlank_interrupt, STAT_interrupt,
    
    // test signals
    output logic [7:0] test0,
    output logic [7:0] test1
);
    // PPU registers
    // 0xFF40
    logic [7:0] LCDC_in, LCDC;
    logic LCDC_en;
    // 0xFF41
    logic [7:0] STAT_in, STAT;
    logic STAT_en;
    // 0xFF42
    logic [7:0]  SCY_in, SCY;
    logic SCY_en;
    // 0xFF43
    logic [7:0]  SCX_in, SCX;
    logic SCX_en;
    // 0xFF44 READ ONLY
    logic [7:0] LY_in, LY;
    logic LY_en;
    // 0xFF45
    logic [7:0]  LYC_in, LYC;
    logic LYC_en;
    // 0xFF47
    logic [7:0]  BGP_in, BGP;
    logic BGP_en;
    // 0xFF48
    logic [7:0] OBP0_in, OBP0;
    logic OBP0_en;
    // 0xFF49
    logic [7:0] OBP1_in, OBP1;
    logic OBP1_en;
    // 0xFF4A
    logic [7:0]   WY_in, WY;
    logic WY_en;
    // 0xFF4B
    logic [7:0]   WX_in, WX;
    logic WX_en;
    
    // PPU Modes
    enum logic [1:0] {HBlank, VBlank, OAMSearch, Drawing} PPU_MODE;
    assign mode = PPU_MODE; // assign output
    
    assign test0 = LCDC; // test signals for fun
    assign test1 = STAT;
    
    // PPU Register Read/Write
    always_comb begin
        // defaults
        LCDC_in = 8'hZZ; LCDC_en = 1'b0;
        STAT_in = {STAT[7:3], LYC == LY, PPU_MODE}; STAT_en = 1'b1; // [2:0] READ ONLY
         SCY_in = 8'hZZ;  SCY_en = 1'b0;
         SCX_in = 8'hZZ;  SCX_en = 1'b0;
         LYC_in = 8'hZZ;  LYC_en = 1'b0;
        
         BGP_in = 8'hZZ;  BGP_en = 1'b0;
        OBP0_in = 8'hZZ; OBP0_en = 1'b0;
        OBP1_in = 8'hZZ; OBP1_en = 1'b0;
          WY_in = 8'hZZ;   WY_en = 1'b0;
          WX_in = 8'hZZ;   WX_en = 1'b0;
        // return 0xFF if address not specified
        cpu_rdata = 8'hZZ;

        if (cpu_we) begin
            case (cpu_addr)
                16'hFF40: begin
                    LCDC_in = cpu_wdata;
                    LCDC_en = 1'b1;
                end
                16'hFF41: begin // [2:0] READ ONLY
                    STAT_in = {cpu_wdata[7:3], LYC == LY, PPU_MODE};
                end
                16'hFF42: begin
                     SCY_in = cpu_wdata;
                     SCY_en = 1'b1;
                end
                16'hFF43: begin
                     SCX_in = cpu_wdata;
                     SCX_en = 1'b1;
                end
                16'hFF44: begin end // READ ONLY
                16'hFF45: begin
                     LYC_in = cpu_wdata;
                     LYC_en = 1'b1;
                end
                16'hFF47:  begin
                     BGP_in = cpu_wdata;
                     BGP_en = 1'b1;
                end
                16'hFF48:  begin
                    OBP0_in = cpu_wdata;
                    OBP0_en = 1'b1;
                end
                16'hFF49:  begin
                    OBP1_in = cpu_wdata;
                    OBP1_en = 1'b1;
                end
                16'hFF4A:  begin
                      WY_in = cpu_wdata;
                      WY_en = 1'b1;
                end
                16'hFF4B:  begin
                      WX_in = cpu_wdata;
                      WX_en = 1'b1;
                end
            endcase
        end else if (cpu_re) begin
            case (cpu_addr)
                16'hFF40: cpu_rdata = LCDC;
                16'hFF41: cpu_rdata = {STAT[7:3], LYC == LY, PPU_MODE}; // [2:0] READ ONLY
                16'hFF42: cpu_rdata = SCY;
                16'hFF43: cpu_rdata = SCX;
                16'hFF44: cpu_rdata = LY;
                16'hFF45: cpu_rdata = LYC;
                16'hFF47: cpu_rdata = BGP;
                16'hFF48: cpu_rdata = OBP0;
                16'hFF49: cpu_rdata = OBP1;
                16'hFF4A: cpu_rdata = WY;
                16'hFF4B: cpu_rdata = WX;
            endcase
        end
    end

    // 0xFF40
    register #(8, 8'h00) LCDCreg(.q(LCDC),
                                .d(LCDC_in),
                                .load(LCDC_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF41
    register #(8, 8'h00) STATreg(.q(STAT),
                                .d(STAT_in), // [2:0] READ ONLY
                                .load(STAT_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF42
    register #(8, 8'h00) SCYreg(.q(SCY),
                                .d(SCY_in),
                                .load(SCY_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF43
    register #(8, 8'h00) SCXreg(.q(SCX),
                                .d(SCX_in),
                                .load(SCX_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF44
    register #(8, 8'h00)  LYreg(.q(LY),
                                .d(LY_in),
                                .load(LY_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF45
    register #(8, 8'h00) LYCreg(.q(LYC),
                                .d(LYC_in),
                                .load(LYC_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF47
    register #(8, 8'h00) BGPreg(.q(BGP),
                                .d(BGP_in),
                                .load(BGP_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF48
    register #(8, 8'h00) OBP0reg(.q(OBP0),
                                .d(OBP0_in),
                                .load(OBP0_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF49
    register #(8, 8'h00) OBP1reg(.q(OBP1),
                                .d(OBP1_in),
                                .load(OBP1_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF4A
    register #(8, 8'h00)  WYreg(.q(WY), // temp
                                .d(WY_in),
                                .load(WY_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    // 0xFF4B
    register #(8, 8'h00)  WXreg(.q(WX), // temp
                                .d(WX_in),
                                .load(WX_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    
    // Horizontal Counter
    logic [8:0] LX;
    always_ff @ (posedge Clk) begin
        if (Reset | ~LCDC[7]) begin // reset or LCD off
            LX <= 9'd0;
        end else if (LY == 8'd184 && LX == 9'd95) begin // reset LX at the end of VBlank
            LX <= 9'd0;
        end else if (LX == 9'd455) begin // reset LX at the end of HBlank 
            LX <= 9'd0;
        end else begin // increment LX at every dot
            LX <= LX + 9'd1;
        end
    end

    // Vertical Counter
    always_comb begin
        if (Reset | ~LCDC[7]) begin // reset or LCD off
            LY_in = 8'd0;
            LY_en = 1'b0;
        end else if (LY == 8'd184 && LX == 9'd95) begin // reset LY at the end of VBlank
            LY_in = 8'd0;
            LY_en = 1'b1;
        end else if (LX == 9'd455) begin // increment LY at the end of each scanline
            LY_in = LY + 8'd1;
            LY_en = 1'b1;
        end else begin // no change otherwise
            LY_in = LY;
            LY_en = 1'b0;
        end
    end


    // interrupt signals
    assign VBlank_interrupt = LY == 8'd144 && 9'd0 <= LX && LX < 9'd8;
    assign STAT_interrupt = (STAT[6] & (LY == LYC)) |
                            (STAT[5] & (PPU_MODE == OAMSearch)) |
                            (STAT[4] & (PPU_MODE == VBlank)) |
                            (STAT[3] & (PPU_MODE == HBlank));
    
    // OAM Fetcher
    logic [7:0] Sprite_Array[10][3];
    logic Valid_Sprite_array[10];
    logic [3:0] Sprite_Array_count;
    logic addSprite;
    enum logic {FetchSpriteX, FetchSpriteY} OAM_MODE;

    // determine if sprite is visible
    assign addSprite = LCDC[1] && // OBJ visible
                       Sprite_Array_count < 4'd10 && // less than 10 visible sprites
                       8'd0 < Sprite_Array[Sprite_Array_count][0] && // 0 < x
                       ppu_data <= LY + 8'd16 && // y <= LY + 16
                       LY + 8'd16 < ppu_data + ((LCDC[2]) ? 8'd16 : 8'd8); // LY + 16 < y + height

    // assign OAM modes
    always_comb begin
        if (PPU_MODE != OAMSearch) begin
            OAM_MODE = FetchSpriteX;
        end else if (LX % 2 == 0) begin
            OAM_MODE = FetchSpriteX;
        end else begin
            OAM_MODE = FetchSpriteY;
        end
    end
    
    // Fetcher
    enum logic [2:0] {Fetch_Address_0, Fetch_Address_1,
                      Fetch_Data0_0, Fetch_Data0_1,
                      Fetch_Data1_0, Fetch_Data1_1,
                      Idle_0, Idle_1}
                      FETCH_MODE;
    enum logic [2:0] {Idle, Normal,
                      Fetch0, Fetch1,
                      WindowStart0, WindowStart1,
                      Sprite0} FETCH_STATE;
    enum logic [1:0] {None, Background, Window, Sprite} FETCH_SOURCE, FETCH_SOURCE_old;
    logic [3:0] sprite_array_idx; // index of current sprite inside visible array
    
    // assign sprite arrays
    always_ff @ (posedge Clk) begin
        if (Reset | PPU_MODE == HBlank) begin
            Sprite_Array_count <= 4'h0;
            Valid_Sprite_array <= '{1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                                    1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // no valid sprites
        end else begin
            case (OAM_MODE)
                FetchSpriteX: begin
                    Sprite_Array[Sprite_Array_count][0] <= ppu_data; // save sprite x, debug
                    if (FETCH_STATE == Sprite0 && FETCH_MODE == Fetch_Data1_0) begin
                        Valid_Sprite_array[sprite_array_idx] <= 1'b0; // invalidate current sprite
                    end
                end
                FetchSpriteY: begin
                    if (addSprite) begin
                        Sprite_Array_count <= Sprite_Array_count + 4'h1; // increment sprite count
                        Sprite_Array[Sprite_Array_count][1] <= ppu_data; // save sprite y
                        Sprite_Array[Sprite_Array_count][2] <= LX / 2; // save sprite index
                        Valid_Sprite_array[Sprite_Array_count] <= 1'b1; // valid sprite found
                    end
                end
            endcase
        end
    end

    
    // anticipation signals
    logic HBlank_next, Window_next, Sprite_next, pixel0_next;
    logic sprite_next_array[10];

    logic [7:0] FetchPixelX, FetchPixelY; // pixel to fetch

    // Background and Window Attributes
    logic [7:0] MapPixelX, MapPixelY; // pixel on background/window map
    logic [4:0] TileX, TileY; // tile on background/window map
    logic [15:0] TileMapAddress; // address storing tile index
    logic [15:0] TileDataAddress; // address storing tile pixel data

    // Sprite Attributes
    logic [7:0] SpriteX, SpriteY; // sprite location on screen from visible array
    logic [5:0] SpriteIndex; // sprite index from visible array (0->39)
    logic [2:0] SpritePixelX; // pixel on sprite
    logic [3:0] SpritePixelY;
    logic [15:0] SpriteFlagsAddress; // address storing sprite flags
    logic [15:0] SpriteTileIndexAddress; // address storing sprite tile index
    logic [15:0] SpriteDataAddress; // address storing sprite pixel data
    logic [4:0] mixOffset; // offset when mixing pixels, determined by LCDX, ranges from 0 -> 8

    // Fetcher Registers
    // tile index
    logic [7:0] TileIndex_in, TileIndex;
    logic TileIndex_en;
    // sprite flags
    logic [7:0] SpriteFlags_in, SpriteFlags;
    logic SpriteFlags_en;
    // sprite tile index
    logic [7:0] SpriteTileIndex_in, SpriteTileIndex;
    logic SpriteTileIndex_en;
    // pixel data 0
    logic [7:0] Data0_in, Data0;
    logic Data0_en;
    // pixel data 1
    logic [7:0] Data1_in, Data1;
    logic Data1_en;

    // Fetcher Registers
    register #(8, 8'h00) TileIndexreg(.q(TileIndex),
                                    .d(TileIndex_in),
                                    .load(TileIndex_en),
                                    .clock(Clk),
                                    .reset(Reset)
                                    );

    register #(8, 8'h00) SpriteFlagsreg(.q(SpriteFlags),
                                    .d(SpriteFlags_in),
                                    .load(SpriteFlags_en),
                                    .clock(Clk),
                                    .reset(Reset)
                                    );
    
    register #(8, 8'h00) SpriteTileIndexreg(.q(SpriteTileIndex),
                                    .d(SpriteTileIndex_in),
                                    .load(SpriteTileIndex_en),
                                    .clock(Clk),
                                    .reset(Reset)
                                    );

    register #(8, 8'h00)   Data0reg(.q(Data0),
                                    .d(Data0_in),
                                    .load(Data0_en),
                                    .clock(Clk),
                                    .reset(Reset)
                                    );
    
    register #(8, 8'h00)   Data1reg(.q(Data1),
                                    .d(Data1_in),
                                    .load(Data1_en),
                                    .clock(Clk),
                                    .reset(Reset)
                                    );

    // FIFO
    enum logic {Suspend, Push} FIFO_MODE;
    logic [3:0] FIFO_count; // number of pixels in FIFO high

    // FIFO shift registers, unpacked: {data0, data1, src, palette0, palette1, palette2}
    // src: 0 -> BG, 1 -> Sprite
    // palette: 3 bits, 
    logic [7:0] FIFO_low_in[6], FIFO_low[6];
    logic FIFO_low_shift_out[6];
    logic FIFO_low_load, FIFO_low_shift_en;
    
    logic [7:0] FIFO_high_in[6], FIFO_high[6];
    logic FIFO_high_shift_out[6];
    logic FIFO_high_load, FIFO_high_shift_en;

    // FIFO shift registers
    shift_reg #(8,6,{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}) FIFO_low_reg(.q(FIFO_low),
                                                    .d(FIFO_low_in),
                                                    .shift_out(FIFO_low_shift_out),
                                                    .shift_in(FIFO_high_shift_out), // shift in from high byte
                                                    .load(FIFO_low_load),
                                                    .shift_en(FIFO_high_shift_en), // shift only when pushing
                                                    .clock(Clk),
                                                    .reset(Reset)
                                                    );

    shift_reg #(8,6,{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}) FIFO_high_reg(.q(FIFO_high), // unused
                                                    .d(FIFO_high_in),
                                                    .shift_out(FIFO_high_shift_out),
                                                    .shift_in('{1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}), // nothing
                                                    .load(FIFO_high_load),
                                                    .shift_en(FIFO_low_shift_en), // shift only when pushing
                                                    .clock(Clk),
                                                    .reset(Reset)
                                                    );
    
    // LCD Frame Buffer Signals
    logic [7:0] LCDX, LCDY;
    logic [1:0] LCD_color;

    
    // assign anticipation signals
    always_comb begin
        pixel0_next = LCDX == 8'd0 && (
                      (FETCH_SOURCE == Background && LX == 9'd91 + (SCX % 8)) || // background/fetch1 to pixel0
                      (FETCH_STATE == WindowStart1 && FETCH_MODE == Fetch_Data1_1) || // window to pixel0
                      (FETCH_SOURCE == Sprite && FETCH_MODE == Fetch_Data1_1) // sprite to pixel0
                      );

        for (integer idx = 0; idx < 10; idx++) begin
            sprite_next_array[idx] = Valid_Sprite_array[idx] &&  // valid sprite
                                     Sprite_Array[idx][1] <= LCDY + 8'd16 && // sprite y <= LCDY, sprite y offset of 16
                                     LCDY + 8'd16 < Sprite_Array[idx][1] + ((LCDC[2]) ? 8'd16 : 8'd8) && // LCDY < sprite y + height, sprite y offset of 16
                                     (
                                        ( // start to sprite 
                                        pixel0_next && Sprite_Array[idx][0] <= 8'd8
                                        ) 
                                        || 
                                        (!pixel0_next && // not start
                                            (
                                                ( // normal to sprite
                                                FETCH_STATE == Normal && 
                                                Sprite_Array[idx][0] == LCDX + 8'd1 + 8'd8 && FIFO_MODE == Push // LCDX == sprite x, sprite x offset of 8
                                                ) 
                                                || 
                                                ( // window/sprite to sprite
                                                ((FETCH_STATE == WindowStart1 && FETCH_MODE == Fetch_Data1_0) || (FETCH_STATE == Sprite0 && FETCH_MODE == Fetch_Data1_1)) &&
                                                Sprite_Array[idx][0] == LCDX + 8'd8 // LCDX == sprite x, sprite x offset of 8
                                                )
                                            )
                                        )
                                     );
        end
        

        HBlank_next = (FIFO_MODE == Push) && (LCDX == 8'd159); // FIFO pushing last pixel
        
        Window_next = LCDC[5] && (WY <= LCDY) && (FETCH_SOURCE == Background) && ( // must transition from background source
                        (pixel0_next && WX <= 8'd7) || // start to window, WX offset by 7
                        (!pixel0_next && LCDX + 8'd1 + 8'd7 == WX && FIFO_MODE == Push) // background to window, WX offset by 7
                      );
        
        Sprite_next = LCDC[1] && ( // if any sprite is visible
                        (sprite_next_array[0] | sprite_next_array[1] |
                         sprite_next_array[2] | sprite_next_array[3] |
                         sprite_next_array[4] | sprite_next_array[5] |
                         sprite_next_array[6] | sprite_next_array[7] |
                         sprite_next_array[8] | sprite_next_array[9])
                      );

    end
    
    // internal window line counter
    logic [7:0] WindowInternalY;
    always_ff @ (posedge Clk) begin
        if (Reset | ~LCDC[7]) begin // reset or LCD off
            WindowInternalY <= 8'hFF;
        end else if (LY == 8'd184 && LX == 9'd95) begin // reset LX at the end of VBlank
            WindowInternalY <= 8'hFF;
        end else if (Window_next) begin // increment if displaying window
            WindowInternalY <= WindowInternalY + 8'h01;
        end
    end
    
    // assign PPU modes
    always_comb begin
        if (Reset | ~LCDC[7]) begin // reset or LCD off, enter mode 0
            PPU_MODE = HBlank;
        end else if (8'd0 <= LY && LY < 8'd144) begin
            if (9'd0 <= LX && LX < 9'd80) begin // OAM Search 0 -> 79
                PPU_MODE = OAMSearch;
            end else if (9'd80 <= LX && LCDX < 8'd160) begin // Drawing 80 -> (LCDX=160) - 1
                PPU_MODE = Drawing;
            end else begin // HBlank (LCDX=160) -> 455
                PPU_MODE = HBlank;
            end
        end else begin // VBlank LY: 144 -> 183 or LY = 184,LX < 96 (extended from LY 144 -> 153)
            PPU_MODE = VBlank;
        end
    end

    // assign FIFO count and FIFO mode
    always_ff @ (posedge Clk) begin
        if (Reset | ~LCDC[7] | (PPU_MODE != Drawing)) begin // reset or if not drawing
            FIFO_MODE <= Suspend;
            FIFO_count <= 4'h0;
        end else if (HBlank_next) begin // if FIFO is pushing last pixel, set to 0
            FIFO_MODE <= Suspend;
            FIFO_count <= 4'h0;
        end else if (Window_next) begin // suspend for window fetch
            FIFO_MODE <= Suspend;
            FIFO_count <= 4'h0;
        end else if (Sprite_next) begin // suspend for sprite fetch
            FIFO_MODE <= Suspend;
            if (FIFO_high_load) begin // update fifo count
                FIFO_count <= 4'h8;
            end else if (FIFO_MODE == Push) begin
                FIFO_count <= FIFO_count - 4'h1;
            end
        end else if (FETCH_STATE == Sprite0 && FETCH_MODE == Fetch_Data1_1) begin // push again if possible from sprite fetch
            if (FIFO_count > 4'h0) begin
                FIFO_MODE <= Push;
            end 
        end else if (FIFO_high_load) begin // if loading new pixels, set to 8
            FIFO_MODE <= Push;
            FIFO_count <= 4'h8;
        end else if (FIFO_MODE == Push && FIFO_count > 4'h1) begin // if FIFO is not empty, decrement
            FIFO_MODE <= Push;
            FIFO_count <= FIFO_count - 4'h1;
        end else if (FIFO_MODE == Push && FIFO_count == 4'h1) begin // emptying FIFO, decrement and suspend
            FIFO_MODE <= Suspend;
            FIFO_count <= 4'h0;
        end
    end

    // assign fetcher states, modes, and sources
    always_ff @ (posedge Clk) begin
        if (Reset) begin // reset, go idle
            FETCH_STATE <= Idle;
            FETCH_MODE <= Idle_0;
            FETCH_SOURCE <= None; // default
            FETCH_SOURCE_old <= None;
        end else if (PPU_MODE == OAMSearch && LX == 9'd79) begin // start Fetch0
            FETCH_STATE <= Fetch0;
            FETCH_MODE <= Fetch_Address_0;
            FETCH_SOURCE <= Background;
            FETCH_SOURCE_old <= Background;
        end else if (HBlank_next) begin // HBlank reset, FIFO is pushing last pixel on scanline
            FETCH_STATE <= Idle;
            FETCH_MODE <= Idle_0;
            FETCH_SOURCE <= None;
            FETCH_SOURCE_old <= None;
        end else if (Window_next) begin // anticipate window, reset fetcher
            FETCH_STATE <= WindowStart0;
            FETCH_MODE <= Fetch_Address_0;
            FETCH_SOURCE <= Window;
            FETCH_SOURCE_old <= Window;
        end else if (Sprite_next) begin // anticipate sprite, reset fetcher
            FETCH_STATE <= Sprite0;
            FETCH_MODE <= Fetch_Address_0;
            FETCH_SOURCE <= Sprite;
            if (FETCH_SOURCE != Sprite) begin
                FETCH_SOURCE_old <= FETCH_SOURCE; // save to return from sprite mode, only save old source if entering from nonsprite mode
            end
        end else begin
            // assign transitions
            case (FETCH_STATE)
                Normal: begin
                    unique case(FETCH_MODE)
                        Fetch_Address_0: FETCH_MODE <= Fetch_Address_1;
                        Fetch_Address_1: FETCH_MODE <= Fetch_Data0_0;
                        Fetch_Data0_0: FETCH_MODE <= Fetch_Data0_1;
                        Fetch_Data0_1: FETCH_MODE <= Fetch_Data1_0;
                        Fetch_Data1_0: FETCH_MODE <= Fetch_Data1_1;
                        Fetch_Data1_1: begin
                            if (FIFO_MODE == Push && FIFO_count > 4'h1) begin // keep pushing
                                FETCH_MODE <= Fetch_Data1_1;
                            end else if (FIFO_MODE == Push && FIFO_count == 4'h1) begin // pushing last pixel in FIFO
                                FETCH_MODE <= Fetch_Address_0;
                                FETCH_SOURCE_old <= FETCH_SOURCE;
                            end else if (FIFO_MODE == Suspend) begin // FIFO was waiting, begin next
                                FETCH_MODE <= Fetch_Address_0;
                                FETCH_SOURCE_old <= FETCH_SOURCE;
                            end
                        end
                        Idle_0: FETCH_MODE <= Idle_0; // unused
                        Idle_1: FETCH_MODE <= Idle_0; // unused
                    endcase
                end
                Fetch0: begin
                    unique case(FETCH_MODE)
                        Fetch_Address_0: FETCH_MODE <= Fetch_Address_1; // LX = 80
                        Fetch_Address_1: FETCH_MODE <= Fetch_Data0_0; // LX = 81
                        Fetch_Data0_0: FETCH_MODE <= Fetch_Data0_1; // LX = 82
                        Fetch_Data0_1: FETCH_MODE <= Fetch_Data1_0; // LX = 83
                        Fetch_Data1_0: FETCH_MODE <= Fetch_Data1_1; // LX = 84
                        Fetch_Data1_1: begin  // LX = 85, begin Fetch1
                            FETCH_STATE <= Fetch1;
                            FETCH_MODE <= Fetch_Address_0;
                        end
                        Idle_0: FETCH_MODE <= Idle_0; // unused
                        Idle_1: FETCH_MODE <= Idle_0; // unused
                    endcase
                end
                Fetch1: begin
                    unique case(FETCH_MODE)
                        Fetch_Address_0: FETCH_MODE <= Fetch_Address_1; // LX = 86
                        Fetch_Address_1: FETCH_MODE <= Fetch_Data0_0; // LX = 87
                        Fetch_Data0_0: FETCH_MODE <= Fetch_Data0_1; // LX = 88
                        Fetch_Data0_1: FETCH_MODE <= Fetch_Data1_0; // LX = 89
                        Fetch_Data1_0: FETCH_MODE <= Fetch_Data1_1; // LX = 90
                        Fetch_Data1_1: begin // LX = 91, go to Normal  (Window should be detected above)
                            FETCH_STATE <= Normal;
                            FETCH_MODE <= Fetch_Address_0;
                        end
                        Idle_0: FETCH_MODE <= Idle_0; // unused
                        Idle_1: FETCH_MODE <= Idle_0; // unused
                    endcase
                end
                WindowStart0: begin
                    unique case(FETCH_MODE)
                        Fetch_Address_0: FETCH_MODE <= Fetch_Data0_0; // double speed fetch
                        Fetch_Address_1: FETCH_MODE <= Idle_0; // unused
                        Fetch_Data0_0: FETCH_MODE <= Fetch_Data1_0; // double speed fetch
                        Fetch_Data0_1: FETCH_MODE <= Idle_0; // unused
                        Fetch_Data1_0: begin // go to WindowStart1, double speed fetch
                            FETCH_STATE <= WindowStart1;
                            FETCH_MODE <= Fetch_Address_0;
                        end
                        Fetch_Data1_1: FETCH_MODE <= Idle_0; // unused
                        Idle_0: FETCH_MODE <= Idle_0; // unused
                        Idle_1: FETCH_MODE <= Idle_0; // unused
                    endcase
                end
                WindowStart1: begin
                    unique case(FETCH_MODE)
                        Fetch_Address_0: FETCH_MODE <= Fetch_Data0_0; // double speed fetch
                        Fetch_Address_1: FETCH_MODE <= Idle_0; // unused
                        Fetch_Data0_0: FETCH_MODE <= Fetch_Data1_0; // double speed fetch
                        Fetch_Data0_1: FETCH_MODE <= Idle_0; // unused
                        Fetch_Data1_0: begin // go to Normal (Sprites should be detected above), double speed fetch
                            FETCH_STATE <= Normal;
                            FETCH_MODE <= Fetch_Address_0;
                        end
                        Fetch_Data1_1: FETCH_MODE <= Idle_0; // unused
                        Idle_0: FETCH_MODE <= Idle_0; // unused
                        Idle_1: FETCH_MODE <= Idle_0; // unused
                    endcase
                end
                Sprite0: begin
                    unique case(FETCH_MODE)
                        Fetch_Address_0: FETCH_MODE <= Fetch_Address_1;
                        Fetch_Address_1: FETCH_MODE <= Fetch_Data0_0;
                        Fetch_Data0_0: FETCH_MODE <= Fetch_Data0_1;
                        Fetch_Data0_1: FETCH_MODE <= Fetch_Data1_0;
                        Fetch_Data1_0: FETCH_MODE <= Fetch_Data1_1;
                        Fetch_Data1_1: begin
                            FETCH_STATE <= Normal;
                            FETCH_MODE <= Fetch_Address_0;
                            FETCH_SOURCE <= FETCH_SOURCE_old; // return to either background or window
                            FETCH_SOURCE_old <= Sprite; // check for sprite after
                        end
                        Idle_0: FETCH_MODE <= Idle_0; // unused
                        Idle_1: FETCH_MODE <= Idle_0; // unused
                    endcase
                end
            endcase
        end
    end



    // assign fetch control signals
    always_comb begin
        // defaults
        mixOffset = 4'hZ;

        FIFO_low_shift_en = FIFO_MODE == Push;
        FIFO_high_shift_en = FIFO_MODE == Push;

        TileIndex_in = 8'hZZ; TileIndex_en = 1'b0;
        SpriteFlags_in = 8'hZZ; SpriteFlags_en = 1'b0;
        SpriteTileIndex_in = 8'hZZ; SpriteTileIndex_en = 1'b0;
        Data0_in = 8'hZZ; Data0_en = 1'b0;
        Data1_in = 8'hZZ; Data1_en = 1'b0;
        FIFO_low_in = '{8'hZZ, 8'hZZ, 8'hZZ, 8'hZZ, 8'hZZ, 8'hZZ}; FIFO_low_load = 1'b0;
        FIFO_high_in = '{8'hZZ, 8'hZZ, 8'hZZ, 8'hZZ, 8'hZZ, 8'hZZ}; FIFO_high_load = 1'b0;

        ppu_addr = 16'hZZZZ;
        ppu_re = 1'b0;

        unique case (FETCH_STATE)
            None: begin
                if (PPU_MODE == OAMSearch) begin
                    unique case (OAM_MODE) // OBJ are 4 bytes long
                        FetchSpriteX: begin
                            ppu_addr = 4 * (LX / 2) + 16'h0001 + 16'hFE00; // x byte
                            ppu_re = 1'b1;
                        end
                        FetchSpriteY: begin
                            ppu_addr = 4 * (LX / 2) + 16'h0000 + 16'hFE00; // y byte
                            ppu_re = 1'b1;
                        end
                    endcase
                end
            end
            Normal: begin
                unique case (FETCH_MODE)
                    Fetch_Address_0: begin
                        ppu_re = 1'b1;
                        // fetch from VRAM
                        ppu_addr = TileMapAddress;
                        TileIndex_in = ppu_data;
                        TileIndex_en = 1'b1;
                    end
                    Fetch_Address_1: begin // do nothing
                    end
                    Fetch_Data0_0: begin // load Data0
                        ppu_re = 1'b1;
                        // fetch from VRAM
                        ppu_addr = TileDataAddress;
                        Data0_in = ppu_data;
                        Data0_en = 1'b1;
                    end
                    Fetch_Data0_1: begin // do nothing
                    end
                    Fetch_Data1_0: begin // load Data1
                        ppu_re = 1'b1;
                        // fetch from VRAM
                        ppu_addr = TileDataAddress + 16'h0001;
                        Data1_in = ppu_data;
                        Data1_en = 1'b1;
                    end
                    Fetch_Data1_1: begin 
                        if ((FIFO_MODE == Push && FIFO_count == 4'h1) || // FIFO pushing last
                            (FIFO_MODE == Suspend && FIFO_count == 4'h0)) // FIFO suspended and waiting
                            begin // load in next tile
                            FIFO_high_in = '{Data0, Data1, 8'h00, 8'h00, 8'h00, 8'h00};
                            FIFO_high_load = 1'b1;
                        end // do nothing otherwise
                    end
                    Idle_0: begin // do nothing
                    end
                    Idle_1: begin // unused
                    end
                endcase
            end
            Fetch0: begin
                unique case(FETCH_MODE)
                    Fetch_Address_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileMapAddress;
                        TileIndex_in = ppu_data;
                        TileIndex_en = 1'b1;
                    end
                    Fetch_Address_1: begin // do nothing
                    end
                    Fetch_Data0_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileDataAddress;
                        Data0_in = ppu_data;
                        Data0_en = 1'b1; // load Data0
                    end
                    Fetch_Data0_1: begin // do nothing
                    end
                    Fetch_Data1_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileDataAddress + 16'h0001;
                        Data1_in = ppu_data;
                        Data1_en = 1'b1; // load Data1
                    end
                    Fetch_Data1_1: begin // load tile into FIFO low
                        FIFO_low_in = '{Data0, Data1, 8'h00, 8'h00, 8'h00, 8'h00};
                        FIFO_low_load = 1'b1;
                    end
                    Idle_0: begin // unused
                    end
                    Idle_1: begin // unused
                    end
                endcase
            end
            Fetch1: begin
                unique case(FETCH_MODE)
                    Fetch_Address_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileMapAddress;
                        TileIndex_in = ppu_data;
                        TileIndex_en = 1'b1;
                    end
                    Fetch_Address_1: begin // do nothing
                    end
                    Fetch_Data0_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileDataAddress;
                        Data0_in = ppu_data;
                        Data0_en = 1'b1; // load Data0
                    end
                    Fetch_Data0_1: begin // do nothing
                    end
                    Fetch_Data1_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileDataAddress + 16'h0001;
                        Data1_in = ppu_data;
                        Data1_en = 1'b1; // load Data1
                    end
                    Fetch_Data1_1: begin // load tile into FIFO high
                        FIFO_high_in = '{Data0, Data1, 8'h00, 8'h00, 8'h00, 8'h00};
                        FIFO_high_load = 1'b1;
                    end
                    Idle_0: begin // unused
                    end
                    Idle_1: begin // unused
                    end
                endcase
            end
            WindowStart0: begin
                unique case(FETCH_MODE)
                    Fetch_Address_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileMapAddress;
                        TileIndex_in = ppu_data;
                        TileIndex_en = 1'b1;
                    end
                    Fetch_Address_1: begin // unused
                    end
                    Fetch_Data0_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileDataAddress;
                        Data0_in = ppu_data;
                        Data0_en = 1'b1; // load Data0
                    end
                    Fetch_Data0_1: begin // unused
                    end
                    Fetch_Data1_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileDataAddress + 16'h0001;
                        Data1_in = ppu_data; // (unused)
                        Data1_en = 1'b1; // load Data1 (unused)

                        // load FIFO low one cycle earlier
                        for (integer i = 0; i < 8; i++) begin
                            if (~LCDC[0] & FIFO_low[2][i]) begin // OBJ > BG priority, do not redraw
                                FIFO_low_in[0][i] = FIFO_low[0][i];
                                FIFO_low_in[1][i] = FIFO_low[1][i]; 
                                FIFO_low_in[2][i] = 1'b1; // OBJ flag
                                FIFO_low_in[3][i] = FIFO_low[3][i]; // preserve palettes
                                FIFO_low_in[4][i] = FIFO_low[4][i];
                                FIFO_low_in[5][i] = FIFO_low[5][i];
                            end else begin // redraw BG/OBJ otherwise
                                FIFO_low_in[0][i] = Data0[i]; // Data0
                                FIFO_low_in[1][i] = ppu_data[i]; // Data1 from data bus
                                FIFO_low_in[2][i] = 1'b0; // BG flag
                                FIFO_low_in[3][i] = 1'b0; // no palette
                                FIFO_low_in[4][i] = 1'b0;
                                FIFO_low_in[5][i] = 1'b0;
                            end
                        end
                        FIFO_low_load = 1'b1;
                    end
                    Fetch_Data1_1: begin // unused 
                    end
                    Idle_0: begin // unused
                    end
                    Idle_1: begin // unused
                    end
                endcase
            end
            WindowStart1: begin
                unique case(FETCH_MODE)
                    Fetch_Address_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileMapAddress;
                        TileIndex_in = ppu_data;
                        TileIndex_en = 1'b1;
                    end
                    Fetch_Address_1: begin // unused
                    end
                    Fetch_Data0_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileDataAddress;
                        Data0_in = ppu_data;
                        Data0_en = 1'b1; // load Data0
                    end
                    Fetch_Data0_1: begin // unused
                    end
                    Fetch_Data1_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = TileDataAddress + 16'h0001;
                        Data1_in = ppu_data; // (unused)
                        Data1_en = 1'b1; // load Data1 (unused)

                        // load FIFO high one cycle earlier
                        FIFO_high_in = '{Data0, ppu_data, 8'h00, 8'h00, 8'h00, 8'h00}; // there should not be any sprite pixels here
                        FIFO_high_load = 1'b1;
                    end
                    Fetch_Data1_1: begin // unused 
                    end
                    Idle_0: begin // unused
                    end
                    Idle_1: begin // unused
                    end
                endcase
            end
            Sprite0: begin
                unique case(FETCH_MODE)
                    Fetch_Address_0: begin
                        ppu_re = 1'b1; // fetch from OAM
                        ppu_addr = SpriteFlagsAddress;
                        SpriteFlags_in = ppu_data;
                        SpriteFlags_en = 1'b1;
                    end
                    Fetch_Address_1: begin
                        ppu_re = 1'b1; // fetch from OAM
                        ppu_addr = SpriteTileIndexAddress;
                        SpriteTileIndex_in = ppu_data;
                        SpriteTileIndex_en = 1'b1;
                    end
                    Fetch_Data0_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = SpriteDataAddress;
                        Data0_in = ppu_data;
                        Data0_en = 1'b1; // load Data0
                    end
                    Fetch_Data0_1: begin // unused
                    end
                    Fetch_Data1_0: begin
                        ppu_re = 1'b1; // fetch from VRAM
                        ppu_addr = SpriteDataAddress + 16'h0001;
                        Data1_in = ppu_data;
                        Data1_en = 1'b1; // load Data1
                    end
                    Fetch_Data1_1: begin // load FIFO low
                        FIFO_low_load = 1'b1;

                        // offset for mixing pixels
                        if (LCDX < 8) begin
                            mixOffset = SpriteX; // mix this many, if SpriteX = 3, mix 3 pixels
                        end else begin
                            mixOffset = 4'h8; // mix all 8 pixels
                        end

                        for (integer i = 0; i < 8; i++) begin // show mixOffset number of pixels
                            if (FIFO_low[2][i]) begin // existing OBJ > OBJ priority
                                FIFO_low_in[0][i] = FIFO_low[0][i];
                                FIFO_low_in[1][i] = FIFO_low[1][i];
                                FIFO_low_in[2][i] = 1'b1; // OBJ flag
                                FIFO_low_in[3][i] = FIFO_low[3][i]; // preserve palettes
                                FIFO_low_in[4][i] = FIFO_low[4][i];
                                FIFO_low_in[5][i] = FIFO_low[5][i];
                            end else if (~SpriteFlags[5] & // OBJ > BG priority, no horizontal flip
                                (Data0[i] | Data1[i]) && // must be non-transparent (color index = 0)
                                ((~SpriteFlags[7]) || // OBJ > BG
                                 (SpriteFlags[7] && (~FIFO_low[0][i] & ~FIFO_low[1][i]))) // BG=00
                                ) begin
                                FIFO_low_in[0][i] = Data0[i]; // mix sprite Data0
                                FIFO_low_in[1][i] = Data1[i]; // mix sprite Data1
                                FIFO_low_in[2][i] = 1'b1; // OBJ flag
                                FIFO_low_in[3][i] = 1'b0; // OBJ palettes
                                FIFO_low_in[4][i] = 1'b0;
                                FIFO_low_in[5][i] = SpriteFlags[4];
                            end else if (SpriteFlags[5] & // OBJ > BG priority, with horizontal flip
                                (Data0[7-i] | Data1[7-i]) && // must be non-transparent (color index = 0)
                                ((~SpriteFlags[7]) || // OBJ > BG
                                 (SpriteFlags[7] && (~FIFO_low[0][i] & ~FIFO_low[1][i]))) // BG=00
                                ) begin
                                FIFO_low_in[0][i] = Data0[7-i]; // mix sprite Data0
                                FIFO_low_in[1][i] = Data1[7-i]; // mix sprite Data1
                                FIFO_low_in[2][i] = 1'b1; // OBJ flag
                                FIFO_low_in[3][i] = 1'b0; // OBJ palettes
                                FIFO_low_in[4][i] = 1'b0;
                                FIFO_low_in[5][i] = SpriteFlags[4];
                            end else begin // redraw BG otherwise
                                FIFO_low_in[0][i] = FIFO_low[0][i]; 
                                FIFO_low_in[1][i] = FIFO_low[1][i];
                                FIFO_low_in[2][i] = 1'b0; // BG flag
                                FIFO_low_in[3][i] = 1'b0;
                                FIFO_low_in[4][i] = 1'b0;
                                FIFO_low_in[5][i] = 1'b0;
                            end
                        end
                    end
                    Idle_0: begin // unused
                    end
                    Idle_1: begin // unused
                    end
                endcase
            end
        endcase
    end

    logic [7:0] tester;
    always_comb begin
        for (integer i = 0; i < 8; i++) begin
            tester[i] = (Data0[i] | Data1[i]);
        end
    end

    // assign pixels to fetch
    always_comb begin
        unique case (FETCH_STATE)
            Idle: begin // nothing
                FetchPixelX = 8'hZZ;
                FetchPixelY = 8'hZZ;
            end
            Normal: begin // 16 ahead
                FetchPixelX = LCDX + 8'd16;
                // if (LCDX == 8'd0 || FETCH_SOURCE == Window) begin
                    
                // end else if (SCX % 8 != 0 && FETCH_SOURCE == Background && FETCH_SOURCE_old != Sprite) begin // do not fetch further during sprite after
                //     FetchPixelX = 8 * (LCDX/8 + 2 + 1); //  && FETCH_SOURCE_old != Sprite
                // end else begin
                //     FetchPixelX = 8 * (LCDX/8 + 2);
                // end
                FetchPixelY = LY;
            end 
            Fetch0: begin // 0 fixed
                FetchPixelX = 8'd0;
                FetchPixelY = LY;
            end
            Fetch1: begin // 8 fixed
                FetchPixelX = 8'd8;
                FetchPixelY = LY;
            end
            WindowStart0: begin // refetch current
                FetchPixelX = LCDX;
                FetchPixelY = LY;
            end
            WindowStart1: begin // refetch 8 ahead
                FetchPixelX = LCDX + 8'd8;
                FetchPixelY = LY;
            end
            Sprite0: begin // fetch current
                FetchPixelX = LCDX;
                FetchPixelY = LY;
            end
        endcase
    end

    // compute addresses
    always_comb begin
        // defaults
        MapPixelX = 8'hZZ; MapPixelY = 8'hZZ;
        TileX = 5'hZZ; TileY = 5'hZZ;
        TileMapAddress = 16'hZZZZ;
        TileDataAddress = 16'hZZZZ;

        sprite_array_idx = 4'hZ;
        SpriteX = 8'hZZ; SpriteY = 8'hZZ;
        SpriteIndex = 5'hZZ;
        SpritePixelX = 5'hZZ; SpritePixelY = 5'hZZ;
        SpriteFlagsAddress = 16'hZZZZ;
        SpriteTileIndexAddress = 16'hZZZZ;
        SpriteDataAddress = 16'hZZZZ;

        case (FETCH_SOURCE)
            Background: begin
                MapPixelX = (FetchPixelX + SCX) % 256;
                MapPixelY = (FetchPixelY + SCY) % 256;
                TileX = MapPixelX / 8;
                TileY = MapPixelY / 8;
                // BG Tile Map
                unique case (LCDC[3])
                    1'b0: TileMapAddress = (TileX + 32*TileY) + 16'h9800;
                    1'b1: TileMapAddress = (TileX + 32*TileY) + 16'h9C00;
                endcase
                // BG/Window Tile Data
                unique case (LCDC[4])
                    1'b0: begin // 8800 mode
                        if (TileIndex < 8'd128) begin
                            TileDataAddress = 16*TileIndex + 2 * (MapPixelY % 8) + 16'h9000;
                        end else begin
                            TileDataAddress = 16*TileIndex + 2 * (MapPixelY % 8) + 16'h8000;
                        end                    
                    end // 8000 mode
                    1'b1: TileDataAddress = 16*TileIndex + 2 * (MapPixelY % 8) + 16'h8000;
                endcase
            end
            Window: begin
                MapPixelX = FetchPixelX - WX + 8'd7; // WX offset by 7
                MapPixelY = WindowInternalY;
                TileX = MapPixelX / 8;
                TileY = MapPixelY / 8;
                // Window Tile Map
                unique case (LCDC[6])
                    1'b0: TileMapAddress = (TileX + 32*TileY) + 16'h9800;
                    1'b1: TileMapAddress = (TileX + 32*TileY) + 16'h9C00;
                endcase
                // BG/Window Tile Data
                unique case (LCDC[4])
                    1'b0: begin
                        if (TileIndex < 8'd128) begin
                            TileDataAddress = 16*TileIndex + 2 * (MapPixelY % 8) + 16'h9000;
                        end else begin
                            TileDataAddress = 16*TileIndex + 2 * (MapPixelY % 8) + 16'h8000;
                        end                    
                    end
                    1'b1: TileDataAddress = 16*TileIndex + 2 * (MapPixelY % 8) + 16'h8000;
                endcase
            end
            Sprite: begin
                for (integer idx = 9; 0 <= idx; idx--) begin // lower OAM indices are given priority
                    if (Valid_Sprite_array[idx] && // valid sprite
                        Sprite_Array[idx][1] <= LCDY + 8'd16 && // sprite y <= LCDY, sprite y offset of 16
                        LCDY + 8'd16 < Sprite_Array[idx][1] + ((LCDC[2]) ? 8'd16 : 8'd8) && // LCDY < sprite y + height, sprite y offset of 16
                        Sprite_Array[idx][0] <= LCDX + 8'd8 // LCDX == sprite x, sprite x offset of 8
                    ) begin
                        sprite_array_idx = idx;
                    end
                end

                SpriteX = Sprite_Array[sprite_array_idx][0];
                SpriteY = Sprite_Array[sprite_array_idx][1];
                SpriteIndex = Sprite_Array[sprite_array_idx][2];
                
                SpriteFlagsAddress = 4 * SpriteIndex + 16'h0003 + 16'hFE00; // flags are 4th byte of OAM entry
                SpriteTileIndexAddress = 4 * SpriteIndex + 16'h0002 + 16'hFE00; // tile index is in 3rd byte of OAM entry
               
                // horizontal flip
                unique case (SpriteFlags[5]) // sprite x offset = 8
                    1'b0: SpritePixelX = (LCDX + 8'd8 - SpriteX);
                    1'b1: SpritePixelX = 8'd8 - 8'd1 - (LCDX + 8'd8 - SpriteX);
                endcase
                // vertical flip
                unique case (SpriteFlags[6]) // sprite y offset = 16
                    1'b0: SpritePixelY = (LCDY + 8'd16 - SpriteY);
                    1'b1: SpritePixelY = ((LCDC[2]) ? 8'd16 : 8'd8) - 8'd1 - (LCDY + 8'd16 - SpriteY);
                endcase
                
                if (LCDC[2]) begin // 8x16 sprite
                    if (SpritePixelY < 8'd8) begin
                        SpriteDataAddress = 16*({SpriteTileIndex[7:1], 1'b0}) + 2*(SpritePixelY%8) + 16'h8000; // ignore LSB
                    end else begin
                        SpriteDataAddress = 16*({SpriteTileIndex[7:1], 1'b1}) + 2*(SpritePixelY%8) + 16'h8000; // ignore LSB
                    end
                end else begin // 8x8 sprite
                    SpriteDataAddress = 16*SpriteTileIndex + 2*SpritePixelY + 16'h8000;
                end
            end
        endcase
    end
    
    // assign LCDX
    always_ff @ (posedge Clk) begin
        if (Reset | ~LCDC[7]) begin // reset or LCD off
            LCDX <= 8'd0;
        end else if (PPU_MODE == Drawing && FIFO_MODE == Push && (9'd92 + (SCX % 8) <= LX)) begin // increment when FIFO is pushing, offset due to scrollX
            LCDX <= LCDX + 8'd1;
        end else if (PPU_MODE == HBlank && LX < 9'd455) begin // keep at 160 during HBlank
            LCDX <= 8'd160;
        end else if (PPU_MODE == HBlank && LX == 9'd455) begin // reset at end of HBlank
            LCDX <= 8'd0;
        end
    end

    assign LCDY = LY; // scanlines always correspond to vertical counter

    // LCD control
    always_comb begin
        // write only when FIFO is pushing
        LCD_we = FIFO_MODE == Push;
        
        // assign LCD addr in
        LCD_addr = LCDX + 8'd160 * LCDY;

        // assign color
        if (~FIFO_low_shift_out[2]) begin // BG flag
            case (LCDC[0])
                1'b0: LCD_color = 2'b00;
                1'b1: LCD_color = BGP[2*{FIFO_low_shift_out[1], FIFO_low_shift_out[0]} +: 2];
            endcase
        end else begin // OBJ flag
            case ({FIFO_low_shift_out[3], FIFO_low_shift_out[4], FIFO_low_shift_out[5]}) // choose OBJ palette
                3'b000: LCD_color = OBP0[2*{FIFO_low_shift_out[1], FIFO_low_shift_out[0]} +: 2];
                3'b001: LCD_color = OBP1[2*{FIFO_low_shift_out[1], FIFO_low_shift_out[0]} +: 2];
                default: LCD_color = 2'b00;
            endcase
        end
        

        // assign LCD data in, map 2 bit colors to RGB555
        unique case (LCD_color)
            2'b00: LCD_data = (((15'h001C << 5) | 15'h001F) << 5) | 15'h001A;
            2'b01: LCD_data = (((15'h0011 << 5) | 15'h0018) << 5) | 15'h000E;
            2'b10: LCD_data = (((15'h0006 << 5) | 15'h000D) << 5) | 15'h000B;
            2'b11: LCD_data = (((15'h0001 << 5) | 15'h0003) << 5) | 15'h0004;
        endcase
    end

endmodule


module shift_reg #(
    parameter width=8, depth=1, [width-1:0] reset_value[depth]='{8'h00}
) (
        output     logic [width-1:0] q[depth],
        input wire logic [width-1:0] d[depth],
        output     logic shift_out[depth],
        input wire logic shift_in[depth],
        input wire logic load, shift_en,
        input wire logic clock, reset
);

    always @(posedge clock) begin
        if (reset) begin
            q <= reset_value;
        end
        else if (load) begin
            q <= d;
        end else if (shift_en) begin
            for (integer i = 0; i < depth; i++) begin
                q[i] <= {q[i][width-1:0], shift_in[i]};
            end
        end
    end

    always_comb begin
        for (integer i = 0; i < depth; i++) begin
            shift_out[i] = q[i][width-1];
        end
    end

endmodule