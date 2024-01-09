module testbench();

timeunit 10ns;	// Half clock cycle at 50 MHz
			    // This is the amount of time represented by #1 
timeprecision 1ns;

// These signals are internal because the processor will be 
// instantiated as a submodule in testbench.
logic Clk = 0;
logic Reset;
logic [15:0] sw;
logic [15:0] led;
// USB
logic gpio_usb_int_tri_i;
logic gpio_usb_rst_tri_o;
logic usb_spi_miso;
logic usb_spi_mosi;
logic usb_spi_sclk;
logic usb_spi_ss;
//UART
logic uart_rtl_0_rxd;
logic uart_rtl_0_txd;
// Hex Displays
logic [7:0] hex_segA;
logic [3:0] hex_gridA;
logic [7:0] hex_segB;
logic [3:0] hex_gridB;
// HDMI
logic hdmi_tmds_clk_n;
logic hdmi_tmds_clk_p;
logic [2:0] hdmi_tmds_data_n;
logic [2:0] hdmi_tmds_data_p;

// Instantiating the DUT
// Make sure the module and signal names match with those in your design
top_level processor(.*);	

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1 Clk = ~Clk;
end

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end 

// Testing begins here
// The initial block is not synthesizable
// Everything happens sequentially inside an initial block
// as in a software program
initial begin: TEST_VECTORS
gpio_usb_int_tri_i = 1'b0;
usb_spi_miso = 1'b0;
uart_rtl_0_rxd = 1'b0;
Reset = 1'b0; // reset
sw[15:2] = 14'h0000;
sw[1:0] = 2'b01;
//addr = 16'hZZZZ;
//data = 8'hZZ;

#1
Reset = 1'b1; // Reset


#50 Reset = 1'b0;

//#1000 A = 1'b1; // test button
//#1000 A = 1'b0;


end
endmodule
