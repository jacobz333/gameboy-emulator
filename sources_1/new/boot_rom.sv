/**
 * Boot ROM with enable
 *
 * Created: Jacob Zheng 11/17/23
 */

module boot_rom (
    input wire logic [7:0]	addr,
	output     logic [7:0]	data,
	input wire logic          en
);
    logic [7:0] ROM[256];
    
    always_comb begin
        if (en) begin
            data = ROM[addr];
        end else begin
            data = 8'hZZ;
        end
    end
    
	// ROM definition		
	assign ROM = {
        8'h31, // 0x0000: LD SP,$fffe          Setup Stack to 0xFFFE
        8'hFE, // 0x0001:
        8'hFF, // 0x0002:

// Zero the memory from $8000-$9FFF (VRAM)
        8'hAF, // 0x0003: XOR A                
        8'h21, // 0x0004: LD HL,$9fff          HL <- 0x9FFF
        8'hFF, // 0x0005:
        8'h9F, // 0x0006:
    // Addr_0007: loop from HL = 0x9FFF -> 0x8000
        8'h32, // 0x0007: LD (HL-),A           M[HL] <- A, HL <- HL-1
        8'hCB, // 0x0008: BIT 7,H              test if H[7] = 0, sets Z flag
        8'h7C, // 0x0009: 
        8'h20, // 0x000A: JR NZ, Addr_0007     if H[7] != 0, then repeat
        8'hFB, // 0x000B:

// Setup Audio
        8'h21, // 0x000C: LD HL,$ff26          
        8'h26, // 0x000D:
        8'hFF, // 0x000E:
        8'h0E, // 0x000F: LD C,$11
        8'h11, // 0x0010:
        8'h3E, // 0x0011: LD A,$80
        8'h80, // 0x0012:
        8'h32, // 0x0013: LD (HL-),A
        8'hE2, // 0x0014: LD ($FF00+C),A
        8'h0C, // 0x0015: INC C
        8'h3E, // 0x0016: LD A,$f3
        8'hF3, // 0x0017:
        8'hE2, // 0x0018: LD ($FF00+C),A
        8'h32, // 0x0019: LD (HL-),A
        8'h3E, // 0x001A: LD A,$77
        8'h77, // 0x001B: 
        8'h77, // 0x001C: LD (HL),A

// Setup BG palette
        8'h3E, // 0x001D: LD A,$FC              A <- 0xFC
        8'hFC, // 0x001E:
        8'hE0, // 0x001F: LD ($FF00+$47),A      M[0xFF47] <- A=0xFC (BG Palette)
        8'h47, // 0x0020:

// Convert and load logo data from cart into Video RAM
        8'h11, // 0x0021: LD DE,$0104           DE <- 0x0104 (beginning of Nintendo logo in cartridge)
        8'h04, // 0x0022:                       ! CHANGE TO 0x00A8 INSIDE BOOT ROM !
        8'h01, // 0x0023:
        8'h21, // 0x0024: LD HL,$8010           HL <- 0x8010 (0x0010 + Tile data)
        8'h10, // 0x0025:
        8'h80, // 0x0026:
    // Addr_0027: loops from DE = 0x0104 -> 0x0133 (fill HL = 0x8010 -> 0x818E) ! CHANGE TO DE = 0x00A8 -> 0x00D7 INSIDE BOOT ROM !
        8'h1A, // 0x0027: LD A,(DE)             A <- M[DE] (load Nintendo Logo tile into A)
        8'hCD, // 0x0028: CALL $0095            PC <- 0x0095, M[SP-2] <- PC, SP <- SP-2 
        8'h95, // 0x0029:                       (set tile memory for all 0x30 tiles)
        8'h00, // 0x002A: 
        8'hCD, // 0x002B: CALL $0096            PC <- 0x0096, M[SP-2] <- PC, SP <- SP-2
        8'h96, // 0x002C:
        8'h00, // 0x002D:
        8'h13, // 0x002E: INC DE                DE <- DE+1
        8'h7B, // 0x002F: LD A,E                A <- E
        8'hFE, // 0x0030: CP $34                compare A with 0x34, set Z flag
        8'h34, // 0x0031:                       ! CHANGE TO 0x00D8 INSIDE BOOT ROM !
        8'h20, // 0x0032: JR NZ, Addr_0027      if E=A != 0x034, repeat
        8'hF3, // 0x0033:
    
// Load 8 additional bytes into Video RAM (the tile for (R))
        8'h11, // 0x0034: LD DE,$00d8           DE <- 0x00D8 (beginning of (R) in boot ROM)
        8'hD8, // 0x0035: 
        8'h00, // 0x0036:
        8'h06, // 0x0037: LD B,$08              B <- 0x08 
        8'h08, // 0x0038:
    // Addr_0039: loops 8 times for 8x8 tile at HL = 0x8190 -> 0x81A0
        8'h1A, // 0x0039: LD A,(DE)             A <- M[DE]
        8'h13, // 0x003A: INC DE                DE <- DE+1
        8'h22, // 0x003B: LD (HL+),A            M[HL] <- A, HL <- HL+1
        8'h23, // 0x003C: INC HL                HL <- HL+1
        8'h05, // 0x003D: DEC B                 B <- B-1
        8'h20, // 0x003E: JR NZ, Addr_0039      if B != 0, repeat
        8'hF9, // 0x003F:

// Setup background tilemap
        8'h3E, // 0x0040: LD A,$19              A <- 0x19
        8'h19, // 0x0041:
        8'hEA, // 0x0042: LD ($9910),A          M[0x9910] <- A
        8'h10, // 0x0043:
        8'h99, // 0x0044:
        8'h21, // 0x0045: LD HL,$992f           HL <- 0x992F (beginning of BG tile map)
        8'h2F, // 0x0046: 
        8'h99, // 0x0047:
    // Addr_0048: nested loop from A = 0x19 -> 0x00, C = 0x0C -> 0x00 (set 12x2 tile indices, HL = 0x992F -> 0x9924, 0x990F -> 0x9904)
        8'h0E, // 0x0048: LD C,$0c              C <- 0x0C
        8'h0C, // 0x0049:
    // Addr_004A
        8'h3D, // 0x004A: DEC A                 A <- A-1
        8'h28, // 0x004B: JR Z, Addr_0055       if A == 0, PC <- 0x0055
        8'h08, // 0x004C:
        8'h32, // 0x004D: LD (HL-),A            M[HL] <- A, HL <- HL-1
        8'h0D, // 0x004E: DEC C                 C <- C-1
        8'h20, // 0x004F: JR NZ, Addr_004A      if C != 0, repeat
        8'hF9, // 0x0050:

        8'h2E, // 0x0051: LD L,$0f              L <- 0x0F
        8'h0F, // 0x0052:
        8'h18, // 0x0053: JR Addr_0048          PC <- 0x0048
        8'hF3, // 0x0054: 
//
// === Scroll logo on screen, and play logo sound===
//
// Addr_0055:
        8'h67, // 0x0055: LD H,A                H <- A  Initialize scroll count, H=0
        8'h3E, // 0x0056: LD A,$64              A <- 0x64
        8'h64, // 0x0057:
        8'h57, // 0x0058: LD D,A                D <- A  set loop count, D=$64
        8'hE0, // 0x0059: LD ($FF00+$42),A      SCY=M[0xFF42] <- A  Set vertical scroll register
        8'h42, // 0x005A:                       
        8'h3E, // 0x005B: LD A,$91              A <- 0x91
        8'h91, // 0x005C:
        8'hE0, // 0x005D: LD ($FF00+$40),A      LCDC=M[0xFF40] <- A  Turn on LCD, showing Background
        8'h40, // 0x005E:                       (set LCDC display on, enable BG)
        8'h04, // 0x005F: INC B                 B <- B+1  Set B=1
    // Addr_0060:
        8'h1E, // 0x0060: LD E,$02              E <- 0x02
        8'h02, // 0x0061:
    // Addr_0062:
        8'h0E, // 0x0062: LD E,$02              E <- 0x02
        8'h0C, // 0x0063:
    // Addr_0064: wait for V-Blank by checking 0xFF44=LY register 
        8'hF0, // 0x0064: LD A,($FF00+$44)      A <- M[FF44]=LY  wait for screen frame
        8'h44, // 0x0065:
        8'hFE, // 0x0066: CP $90                compare A with 0x90, set Z flag
        8'h90, // 0x0067:                       (LCDC[7]=LCD Display enable, LCDC[4]=BG&Window Tile Data)
        8'h20, // 0x0068: JR NZ, Addr_0064      if A != 0x90, repeat
        8'hFA, // 0x0069:                       (repeat until LCD is on?)
    
        8'h0D, // 0x006A: DEC C                 C <- C-1
        8'h20, // 0x006B: JR NZ, Addr_0064      if C != 0x00, then repeat
        8'hF7, // 0x006C: 
        8'h1D, // 0x006D: DEC E                 E <- E-1
        8'h20, // 0x006E: JR NZ, Addr_0062      if E != 0x00, then repeat
        8'hF2, // 0x006F: 

        8'h0E, // 0x0070: LD C,$13              C <- 0x13
        8'h13, // 0x0071:
        8'h24, // 0x0072: INC H                 H <- H+1  increment scroll count
        8'h7C, // 0x0073: LD A,H                A <- H
        8'h1E, // 0x0074: LD E,$83              E <- 0x83
        8'h83, // 0x0075:
        8'hFE, // 0x0076: CP $62                compare A to 0x62, set Z flag  
        8'h62, // 0x0077:
        8'h28, // 0x0078: JR Z, Addr_0080	    if A == 0x62  $62 counts in, play sound #1
        8'h06, // 0x0079:
        8'h1E, // 0x007A: LD E,$c1              E <- 0xC1
        8'hC1, // 0x007B:
        8'hFE, // 0x007C: CP $64                compare A to 0x64
        8'h64, // 0x007D:
        8'h20, // 0x007E: JR NZ, Addr_0086      if A != 0x64  $64 counts in, play sound #2
        8'h06, // 0x007F:
    // Addr_0080: play sound #1
        8'h7B, // 0x0080: LD A,E                A <- E
        8'hE2, // 0x0081: LD ($FF00+C),A        
        8'h0C, // 0x0082: INC C
        8'h3E, // 0x0083: LD A,$87
        8'h87, // 0x0084:
        8'hE2, // 0x0085: LD ($FF00+C),A
    // Addr_0086: play sound #2
        8'hF0, // 0x0086: LD,A($FF00+$42)       A <- M[0xFF42]
        8'h42, // 0x0087: 
        8'h90, // 0x0088: SUB B                 B <- B-1
        8'hE0, // 0x0089: LD ($FF00+$42),A      M[0xFF42] <- A  scroll logo up if B=1
        8'h42, // 0x008A:
        8'h15, // 0x008B: DEC D                 D <- D-1
        8'h20, // 0x008C: JR NZ, Addr_0060      if D != 0, repeat
        8'hD2, // 0x008D:
    
        8'h05, // 0x008E: DEC B                 set B=0 first time
        8'h20, // 0x008F: JR NZ, Addr_00E0        ... next time, cause jump to "Nintendo Logo check"
        8'h4F, // 0x0090:
    
        8'h16, // 0x0091: LD D,$20              D <- 0x20  use scrolling loop to pause
        8'h20, // 0x0092:
        8'h18, // 0x0093: JR Addr_0060
        8'hCB, // 0x0094:
//
// 	==== Graphic routine ====
//
// "Double up" all the bits of the graphics data and store in Video RAM
        8'h4F, // 0x0095: LD C,A                C <- A
        8'h06, // 0x0096: LD B,$04              B <- 0x04
        8'h04, // 0x0097:
    // Addr_0098: loops B=0x04 times, A <- (A<<2)+C[3]
        8'hC5, // 0x0098: PUSH BC               M[SP-2] <- BC, SP <- SP-2
        8'hCB, // 0x0099: RL C                  C <- C<<1
        8'h11, // 0x009A:
        8'h17, // 0x009B: RLA                   A <- A<<1
        8'hC1, // 0x009C: POP BC                BC <- M[SP], SP <- SP+2
        8'hCB, // 0x009D: RL C                  C <- C<<1
        8'h11, // 0x009E:
        8'h17, // 0x009F: RLA                   A <- A<<1
        8'h05, // 0x00A0: DEC B                 B <- B-1
        8'h20, // 0x00A1: JR NZ, Addr_0098      if B != 0, then repeat
        8'hF5, // 0x00A2:
    // set M[HL] <- A, M[HL+2] <- A where HL is in tile memory
        8'h22, // 0x00A3: LD (HL+),A            M[HL] <- A, HL <- HL+1
        8'h23, // 0x00A4: INC HL                HL <- HL+1
        8'h22, // 0x00A5: LD (HL+),A            M[HL] <- A, HL <- HL+1
        8'h23, // 0x00A6: INC HL                HL <- HL+1
        8'hC9, // 0x00A7: RET                   PC <- M[SP], SP <- SP+2
// Addr_00A8: Nintendo Logo
        8'hCE, // 0x00A8:
        8'hED, // 0x00A9:
        8'h66, // 0x00AA:
        8'h66, // 0x00AB:
        8'hCC, // 0x00AC:
        8'h0D, // 0x00AD:
        8'h00, // 0x00AE:
        8'h0B, // 0x00AF:
        8'h03, // 0x00B0:
        8'h73, // 0x00B1:
        8'h00, // 0x00B2:
        8'h83, // 0x00B3:
        8'h00, // 0x00B4:
        8'h0C, // 0x00B5:
        8'h00, // 0x00B6:
        8'h0D, // 0x00B7:
        8'h00, // 0x00B8:
        8'h08, // 0x00B9:
        8'h11, // 0x00BA:
        8'h1F, // 0x00BB:
        8'h88, // 0x00BC:
        8'h89, // 0x00BD:
        8'h00, // 0x00BE:
        8'h0E, // 0x00BF:
        8'hDC, // 0x00C0:
        8'hCC, // 0x00C1:
        8'h6E, // 0x00C2:
        8'hE6, // 0x00C3:
        8'hDD, // 0x00C4:
        8'hDD, // 0x00C5:
        8'hD9, // 0x00C6:
        8'h99, // 0x00C7:
        8'hBB, // 0x00C8:
        8'hBB, // 0x00C9:
        8'h67, // 0x00CA:
        8'h63, // 0x00CB:
        8'h6E, // 0x00CC:
        8'h0E, // 0x00CD:
        8'hEC, // 0x00CE:
        8'hCC, // 0x00CF:
        8'hDD, // 0x00D0:
        8'hDC, // 0x00D1:
        8'h99, // 0x00D2:
        8'h9F, // 0x00D3:
        8'hBB, // 0x00D4:
        8'hB9, // 0x00D5:
        8'h33, // 0x00D6:
        8'h3E, // 0x00D7:
// Addr_00D8: More video data (the tile data for ®)
        8'b00111100, // 0x00D8:   ****
        8'b01000010, // 0x00D9:  *    * 
        8'b10111001, // 0x00DA: * ***  *
        8'b10100101, // 0x00DB: * *  * *
        8'b10111001, // 0x00DC: * ***  *
        8'b10100101, // 0x00DD: * *  * *
        8'b01000010, // 0x00DE:  *    * 
        8'b00111100, // 0x00DF:   ****
// 
// ===== Nintendo logo comparison routine =====
//
// Addr_00E0:	
        8'h21, // 0x00E0:
        8'h04, // 0x00E1:
        8'h01, // 0x00E2:
        8'h11, // 0x00E3:
        8'hA8, // 0x00E4:
        8'h00, // 0x00E5:
        8'h1A, // 0x00E6:
        8'h13, // 0x00E7:
        8'hBE, // 0x00E8:
        8'h20, // 0x00E9:
        8'hFE, // 0x00EA:
        8'h23, // 0x00EB:
        8'h7D, // 0x00EC:
        8'hFE, // 0x00ED: 
        8'h34, // 0x00EE:
        8'h20, // 0x00EF:
        8'hF5, // 0x00F0:
        8'h06, // 0x00F1:
        8'h19, // 0x00F2:
        8'h78, // 0x00F3:
        8'h86, // 0x00F4:
        8'h23, // 0x00F5:
        8'h05, // 0x00F6:
        8'h20, // 0x00F7:
        8'hFB, // 0x00F8:
        8'h86, // 0x00F9:
        8'h20, // 0x00FA:
        8'hFE, // 0x00FB:
        8'h3E, // 0x00FC:
        8'h01, // 0x00FD:
        8'hE0, // 0x00FE:
        8'h50  // 0x00FF:
    };

endmodule