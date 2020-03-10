module InhalingFood(
    input [17:0] SW,
	input [3:0] KEY,
	input [0:0] GPIO,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	input CLOCK_50,
	output VGA_CLK,   						//	VGA Clock
	output VGA_HS,							//	VGA H_SYNC
	output VGA_VS,							//	VGA V_SYNC
	output VGA_BLANK_N,						//	VGA BLANK
	output VGA_SYNC_N,						//	VGA SYNC
	output [9:0] VGA_R,   					//	VGA Red[9:0]
	output [9:0] VGA_G,	 					//	VGA Green[9:0]
	output [9:0] VGA_B  					//	VGA Blue[9:0]
)
    // Logic to handle inhaling click
    reg blow_toggle;
	reg blow;
	
	initial begin
		blow_toggle = 1'b0;
		blow <= 1'b0;
	end
    

	always@(*)
	begin
		if (~GPIO[0])
			blow <= 1'b1;
		if(frame && GPIO[0])
			blow <= 1'b0;
	end

	always@(posedge frame)
	begin
		if (SW[0] == 0)
			blow_toggle = blow;
		else
			blow_toggle = ~KEY[2];
	end
    
    
    wire [7:0] load_x;
	wire [6:0] load_y;
    reg [11:0] colour;
    reg [7:0] x_out;
	reg [6:0] y_out;
    wire [7:0] posx_player;
	wire [6:0] posy_player;
    wire complete_player;
    
    
    
    // --------------- VGA Module --------------- 
	vga_adapter VGA(
		.resetn(1'b1),
		.clock(CLOCK_50),
		.colour(colour),
		.x(x_out),
		.y(y_out),
		.plot(writeEn),
		/* Signals for the DAC to drive the monitor. */
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 4;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";

	
	// --------------- Sprite Control Modules --------------- 
    pacmanspritecontrol pacman(
        .clk(CLOCK_50),
		.draw(1'b1),
		.clear(1'b0),
		.shift_h(1'b1),
		.shift_v(1'b1),
		.shift_amount(7'b0000001),
		.load(1'b1),
		.complete(complete_player),
		.load_x(load_x),
		.load_y(load_y),
		.x_out(x_out_player),
		.y_out(y_out_player),
		.colour_out(colour),
		.posx(posx_player),
		.posy(posy_player)
    )
    
  
endmodule
