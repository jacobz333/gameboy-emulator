//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Modified by Zuofu Cheng   08-19-2023                               --
//    Edited by Jacob Zheng     11-21-2023                               --
//                                                                       --
//    Fall 2023 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module  color_mapper ( input wire logic  [9:0] VGAX, VGAY,
                       output     logic [14:0] VGA_addr,
                       input wire logic [14:0] VGA_data,
                       output logic            VGA_fetch,
                       output     logic  [4:0] Red, Green, Blue );
    
    
    logic VGA_en;
    assign VGA_en = 240 <= VGAX && VGAX < 400 && 168 <= VGAY && VGAY < 312; // draw pixel
    assign VGA_fetch = 239 <= VGAX && VGAX < 399 && 168 <= VGAY && VGAY < 312; // fetch data one cycle earlier
    
    
    always_comb begin
        if (VGA_fetch) begin
            VGA_addr = (VGAX - 239) + 160 * (VGAY - 168);
        end else begin
            VGA_addr = 15'h0000;
        end
        if (VGA_en && !(VGA_data === 15'hXXXX)) begin
            Red   = VGA_data[14:10];
            Green = VGA_data[9:5];
            Blue  = VGA_data[4:0];
        end else begin
            Red   = 5'h00; 
            Green = 5'h00;
            Blue  = 5'h00;
        end
    end
    
endmodule
