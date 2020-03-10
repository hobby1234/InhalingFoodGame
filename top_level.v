module top_level(
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
	);
	
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
	
	reg [11:0] colour;
	reg [7:0] x_out;
	reg [6:0] y_out;
	
	wire [11:0] colour_player;
	wire [7:0] x_out_player;
	wire [6:0] y_out_player;

	wire [11:0] colour_d_player;
	wire [7:0] x_out_d_player;
	wire [6:0] y_out_d_player;

	wire [11:0] colour_start;
	wire [7:0] x_out_start;
	wire [6:0] y_out_start;
	
	wire [11:0] colour_m1;
	wire [7:0] x_out_m1;
	wire [6:0] y_out_m1;
	
	wire [11:0] colour_m2;
	wire [7:0] x_out_m2;
	wire [6:0] y_out_m2;
	
	wire writeEn, clear_sig, shift_h_sig, shift_v_sig, load;
	wire [6:0] shift_amount;
	wire [6:0] shift_amount_two;
	wire [7:0] load_x;
	wire [6:0] load_y;
	wire complete_player, complete_m1, complete_m2, complete_d_player, complete_start;
	
	wire draw_player, draw_m1, draw_m2, draw_d_player, draw_start;
	
	wire [4:0] curState;
	wire frame;
	wire [1:0] randval;
	
	wire [7:0] posx_player, posx_m1, posx_m2, posx_d_player, posx_start;
	wire [6:0] posy_player, posy_m1, posy_m2, posy_d_player, posy_start;
	
	always@(*)
	begin
		if (curState <= 1'b1) 
			begin
				x_out <= x_out_player;
				y_out <= y_out_player;
				colour <= colour_player;
			end 
		else if (curState <= 2'b11)
			begin
				x_out <= x_out_m1;
				y_out <= y_out_m1;
				colour <= colour_m1;
			end
		else if (curState <= 3'b101)
			begin
				x_out <= x_out_m2;
				y_out <= y_out_m2;
				colour <= colour_m2;
			end
		else if (curState == 5'b11110)
			begin
				x_out <= x_out_d_player;
				y_out <= y_out_d_player;
				colour <= colour_d_player;
			end
		else if (curState == 5'b10110 || curState == 5'b11011)
			begin
				x_out <= x_out_start;
				y_out <= y_out_start;
				colour <= colour_start;
			end
		else
			begin
				x_out <= 0;
				y_out <= 0;
				colour <= 0;
			end
	end

	rd RateDivider(
		.Clock(CLOCK_50),
		.Enable(frame)
	);

	linearFeedbackShiftRegister lfsr(
		.clock(CLOCK_50),
		.seed(SW[17:2]),
		.reset(KEY[0]),
		.randnum(randval)
	);

	fsm FSM(
		.clock(CLOCK_50),
		.update(frame),
		.reset(KEY[0]),
		.blow(blow_toggle),
		.load(load),
		.load_x(load_x),
		.load_y(load_y),
		.randval(randval),
		.continueDraw(1'b1),
		.experiment(SW[1]),
		.complete_player(complete_player),
		.complete_m1(complete_m1),
		.complete_m2(complete_m2),
		.complete_start(complete_start),
		.player_x(posx_player),
		.player_y(posy_player),
		.m1_x(posx_m1),
		.m1_y(posy_m1),
		.m2_x(posx_m2),
		.m2_y(posy_m2),
		.draw_player(draw_player),
		.draw_m1(draw_m1),
		.draw_m2(draw_m2),
		.draw_d_player(draw_d_player),
		.draw_start(draw_start),
		.clear(clear_sig),
		.shift_h(shift_h_sig),
		.shift_v(shift_v_sig),
		.shift_amount(shift_amount),
		.shift_amount_two(shift_amount_two),
		.writeEn(writeEn),
		.state(curState)
	);

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
	balloon_sprite_control player(
		.clk(CLOCK_50),
		.draw(draw_player),
		.clear(clear_sig),
		.shift_h(shift_h_sig),
		.shift_v(shift_v_sig),
		.shift_amount(shift_amount),
		.load(load),
		.complete(complete_player),
		.load_x(load_x),
		.load_y(load_y),
		.x_out(x_out_player),
		.y_out(y_out_player),
		.colour_out(colour_player),
		.posx(posx_player),
		.posy(posy_player)
		);

	balloon_i_sprite_control d_player(
		.clk(CLOCK_50),
		.draw(draw_d_player),
		.clear(clear_sig),
		.shift_h(shift_h_sig),
		.shift_v(shift_v_sig),
		.shift_amount(shift_amount),
		.load(load),
		.complete(complete_d_player),
		.load_x(load_x),
		.load_y(load_y),
		.x_out(x_out_d_player),
		.y_out(y_out_d_player),
		.colour_out(colour_d_player),
		.posx(posx_d_player),
		.posy(posy_d_player)
		);
		
	missile_r_sprite_control m1(
		.clk(CLOCK_50),
		.draw(draw_m1),
		.clear(clear_sig),
		.shift_hv(shift_h_sig),
		.shift_v(shift_v_sig),
		.shift_amount(shift_amount),
		.shift_amount_two(shift_amount_two),
		.load(load),
		.complete(complete_m1),
		.load_x(load_x),
		.load_y(load_y),
		.x_out(x_out_m1),
		.y_out(y_out_m1),
		.colour_out(colour_m1),
		.posx(posx_m1),
		.posy(posy_m1)
		);
		
	missile_l_sprite_control m2(
		.clk(CLOCK_50),
		.draw(draw_m2),
		.clear(clear_sig),
		.shift_hv(shift_h_sig),
		.shift_v(shift_v_sig),
		.shift_amount(shift_amount),
		.shift_amount_two(shift_amount_two),
		.load(load),
		.complete(complete_m2),
		.load_x(load_x),
		.load_y(load_y),
		.x_out(x_out_m2),
		.y_out(y_out_m2),
		.colour_out(colour_m2),
		.posx(posx_m2),
		.posy(posy_m2)
		);

	start_sprite_control s(
		.clk(CLOCK_50),
		.draw(draw_start),
		.clear(clear_sig),
		.shift_h(shift_h_sig),
		.shift_v(shift_v_sig),
		.shift_amount(shift_amount),
		.load(load),
		.complete(complete_start),
		.load_x(load_x),
		.load_y(load_y),
		.x_out(x_out_start),
		.y_out(y_out_start),
		.colour_out(colour_start),
		.posx(posx_start),
		.posy(posy_start)
		);
	
	// --------------- HEX Modules (for debugging) --------------- 
	hex_display h0(
		.IN(randval),
		.OUT(HEX0)
		);
		
	hex_display h1(
		.IN(load_x[7:4]),
		.OUT(HEX1)
		);
		
	hex_display h2(
		.IN(curState[3:0]),
		.OUT(HEX2)
		);
	
	hex_display h3(
		.IN(curState[4]),
		.OUT(HEX3)
		);
		
	hex_display h4(
		.IN(blow_toggle),
		.OUT(HEX4)
		);
		
	hex_display h5(
		.IN(GPIO[0]),
		.OUT(HEX5)
		);
endmodule