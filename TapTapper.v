module TapTapper
	(
		input CLOCK_50, // 50 MHz onboard clk, used as synchrnous clk for all modules
		input [3:0] KEY, // User input [3:1] correspond to hit boxes 1-3 respectively [0] is synchronous reset
		input [17: 0] SW,
		// The ports below are for the VGA output. [VGA ADAPTER FROM LAB6 STARTER CODE]
		output VGA_CLK, 		// VGA Clock
		output VGA_HS, 		// VGA H_SYNC
		output VGA_VS, 		// VGA V_SYNC
		output VGA_BLANK_N, 	// VGA BLANK
		output VGA_SYNC_N, 	// VGA SYNC
		output [9:0] VGA_R, 	// VGA Red[9:0]
		output [9:0] VGA_G, 	// VGA Green[9:0]
		output [9:0] VGA_B, 	// VGA Blue[9:0]
		
		output [6:0] HEX0, HEX1, HEX2, HEX3, HEX7, HEX6,// User score counter
		output [17:0] LEDR // TEST
	);
		
	wire master_clock;
	
	Twoto1mux master
	(
		.S(SW[0]),
		.IN({CLOCK_50, 1'b0}),
		.OUT(master_clock)
	);
	
	/*
	* SCORE OUTPUT
	*/
	
	wire [15:0] score_0, score_1, score_2;
	wire [15:0] score;
   assign score =	score_0 + score_1 + score_2;
	hex_display
	(
		.IN(score[3:0]),
		.OUT(HEX0)
	);
	
	hex_display
	(
		.IN(score[7:4]),
		.OUT(HEX1)
	);
	
	hex_display
	(
		.IN(score[11:8]),
		.OUT(HEX2)
	);
	
	hex_display
	(
		.IN(score[15:12]),
		.OUT(HEX3)
	);

	wire [7:0] lives_0, lives_1, lives_2;							
	wire [7:0] lives = lives_0 + lives_1 + lives_2;			// The sum of lost lives 
	wire [7:0] inverse_lives = 8'd45 - lives;					// Display the number of lives the player has remaining
	
	hex_display
	(
		.IN(inverse_lives[3:0]),									//Display lives at Hex6  and Hex7
		.OUT(HEX6)
	);
	
	hex_display
	(
		.IN(inverse_lives[7:4]),
		.OUT(HEX7)
	);

	wire resetn = KEY[0]; // synchronous reset for all components of game
	
	/*
	* VGA Adaptar [CODE FROM LAB 6 STARTER CODE]
	*/
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA (
		.resetn(resetn),
		.clock(CLOCK_50),
		.colour(colour),
		.x(x),
		.y(y),
		.plot(plot),
		/* Signals for the DAC to drive the monitor. */
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK)
	);
	
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
	

	/*
	* Animation Inputs
	*/
	wire [2:0] colour; // current colour being drawn
	wire [7:0] x; // current x coord of drawn pixel
	wire [6:0] y; // current y of drawn pixel
	wire plot; // enable for drawing on VGA

	
	/*
	* Animation Counters
	*/

	wire refresh; // 60 Hz refresh
	wire go; // 15 fps update

	// Instantiate 60 Hz refresh counter
	// Used for animation control transitions
	refresh_rate_counter refresher
	(
		.clk(master_clock), // 50 MHz clk
		.resetn(resetn), // synchrounous clk
		.refresh(refresh) // refresh output tick
	);

	
	frames_counter counter
	(
		.clk(master_clock), // 50 MHz
		.refresh(refresh), // 60 Hz input tick
		.go(go) // counter update tick
	);

	/*
	* COLUMN 1 OF TAP TAPPER
	*/
	
	/*
	* Ball Position Counters
	*/

	// Current x coordinate for all column components
	wire [7:0] x_in_0;
		
	// Current ball y coordinates
	wire [6:0] y_in_0_0;
	wire [6:0] y_in_0_1;
	wire [6:0] y_in_0_2;
	wire [6:0] y_in_0_3;


	// x-coordinate
	flipFlop x_0_value
	(
		.d(8'd56),
		.q(x_in_0),
		.clk(CLOCK_50),
		.resetn(resetn)
	);
	
	// coloumn-1 ball coordinate counters
	position_counter y_0_value_0
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.go(go),
		.origin(7'd5),
		.reset(reset_y_0_0),
		.q(y_in_0_0)
	);

	position_counter y_0_value_1
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.origin(7'd35),
		.reset(reset_y_0_1),
		.go(go),
		.q(y_in_0_1)
	);
	
	position_counter y_0_value_2
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.go(go),
		.origin(7'd65),
		.reset(reset_y_0_2),
		.q(y_in_0_2)
	);
	
	position_counter y_0_value_3
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.go(go),
		.origin(7'd95),
		.reset(reset_y_0_3),
		.q(y_in_0_3)
	);
	
	/*
	* Column 1 user input
	*/
	
	// resets ball to start
	// triggered when user hits ball
	wire reset_y_0_0;
	wire reset_y_0_1;
	wire reset_y_0_2;
	wire reset_y_0_3;
	
	// Instantiate key control for first column
	user_input column_0
	(

		.key(~KEY[3]), // user input
		.refresh(refresh),
		.resetn(resetn),
		.y_in_0(y_in_0_0), // locations of balls
		.y_in_1(y_in_0_1),
		.y_in_2(y_in_0_2),
		.y_in_3(y_in_0_3),
		.reset_y_0(reset_y_0_0), // output resets for reseeting ballsd
		.reset_y_1(reset_y_0_1),
		.reset_y_2(reset_y_0_2),
		.reset_y_3(reset_y_0_3),
		.add_score(add_score_0),
		.score(score_0),
		.lives(lives_0)

	);

	/*
	* COLUMN 2 OF TAP TAPPER
	*/
	
	/*
	* Ball Position Counters
	*/

	// Current x coordinate for all column components
	wire [7:0] x_in_1;
		
	// Current ball y coordinates
	wire [6:0] y_in_1_0;
	wire [6:0] y_in_1_1;
	wire [6:0] y_in_1_2;
	wire [6:0] y_in_1_3;


	// x-coordinate
	flipFlop x_1_value
	(
		.d(8'd71),
		.q(x_in_1),
		.clk(CLOCK_50),
		.resetn(resetn)
	);
	
	// coloumn-2 ball coordinate counters
	position_counter y_1_value_0
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.go(go),
		.origin(7'd0),
		.reset(reset_y_1_0),
		.q(y_in_1_0)
	);

	position_counter y_1_value_1
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.origin(7'd30),
		.reset(reset_y_1_1),
		.go(go),
		.q(y_in_1_1)
	);
	
	position_counter y_1_value_2
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.go(go),
		.origin(7'd60),
		.reset(reset_y_1_2),
		.q(y_in_1_2)
	);
	
	position_counter y_1_value_3
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.go(go),
		.origin(7'd90),
		.reset(reset_y_1_3),
		.q(y_in_1_3)
	);
	
	/*
	* Column 2 user input
	*/
	
	// resets ball to start
	// triggered when user hits ball
	wire reset_y_1_0;
	wire reset_y_1_1;
	wire reset_y_1_2;
	wire reset_y_1_3;
	
	// Instantiate key control for first column
	user_input column_1
	(

		.key(~KEY[2]), // user input
		.refresh(refresh),
		.resetn(resetn),
		.y_in_0(y_in_1_0), // locations of balls
		.y_in_1(y_in_1_1),
		.y_in_2(y_in_1_2),
		.y_in_3(y_in_1_3),
		.reset_y_0(reset_y_1_0), // output resets for reseeting ballsd
		.reset_y_1(reset_y_1_1),
		.reset_y_2(reset_y_1_2),
		.reset_y_3(reset_y_1_3),
		.add_score(add_score_1),
		.score(score_1),
		.lives(lives_1)
	
	);
	
	/*
	* COLUMN 3 OF TAP TAPPER
	*/
	
	/*
	* Ball Position Counters
	*/

	// Current x coordinate for all column components
	wire [7:0] x_in_2;
		
	// Current ball y coordinates
	wire [6:0] y_in_2_0;
	wire [6:0] y_in_2_1;
	wire [6:0] y_in_2_2;
	wire [6:0] y_in_2_3;


	// x-coordinate
	flipFlop x_2_value
	(
		.d(8'd86),
		.q(x_in_2),
		.clk(CLOCK_50),
		.resetn(resetn)
	);
	
	// coloumn-3 ball coordinate counters
	position_counter y_2_value_0
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.go(go),
		.origin(7'd10),
		.reset(reset_y_2_0),
		.q(y_in_2_0)
	);

	position_counter y_2_value_1
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.origin(7'd40),
		.reset(reset_y_2_1),
		.go(go),
		.q(y_in_2_1)
	);
	
	position_counter y_2_value_2
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.go(go),
		.origin(7'd65),
		.reset(reset_y_2_2),
		.q(y_in_2_2)
	);
	
	position_counter y_2_value_3
	(
		.clk(master_clock),
		.update(refresh),
		.resetn(resetn),
		.go(go),
		.origin(7'd85),
		.reset(reset_y_2_3),
		.q(y_in_2_3)
	);
	
	/*
	* Column 3 user input
	*/
	
	// resets ball to start
	// triggered when user hits ball
	wire reset_y_2_0;
	wire reset_y_2_1;
	wire reset_y_2_2;
	wire reset_y_2_3;
	
	// Instantiate key control for first column
	user_input column_2
	(

		.key(~KEY[1]), // user input
		.refresh(refresh),
		.resetn(resetn),
		.y_in_0(y_in_2_0), // locations of balls
		.y_in_1(y_in_2_1),
		.y_in_2(y_in_2_2),
		.y_in_3(y_in_2_3),
		.reset_y_0(reset_y_2_0), // output resets for reseeting ballsd
		.reset_y_1(reset_y_2_1),
		.reset_y_2(reset_y_2_2),
		.reset_y_3(reset_y_2_3),
		.add_score(add_score_2),
		.score(score_2),
		.lives(lives_2)
		
	
	);

	/*
	* Animation control - FSM for animating all components
	*/	
	wire clear_status; // clear input, 0 iff cleared
	wire draw_status; // draw input 0 iff drawn
	
	control
	(
		.clk(master_clock),
		.resetn(resetn),
		
		.go(~refresh),
		.clear_status(clear_status),
		.draw_status(draw_status),
		
		.plot(plot),
		.clear(clear),
		.ld_end(ld_end),

		.draw_0_0(draw_0_0),
		.draw_0_1(draw_0_1),
		.draw_0_2(draw_0_2),
		.draw_0_3(draw_0_3),
		.draw_hb_0(draw_hb_0),

		.draw_1_0(draw_1_0),
		.draw_1_1(draw_1_1),
		.draw_1_2(draw_1_2),
		.draw_1_3(draw_1_3),
		.draw_hb_1(draw_hb_1),

		.draw_2_0(draw_2_0),
		.draw_2_1(draw_2_1),
		.draw_2_2(draw_2_2),
		.draw_2_3(draw_2_3),
		.draw_hb_2(draw_hb_2),
		.lives(lives)

	 );


	/*
	* Animation datapath, draws and clears screen
	*/

	wire clear; // reset screen background state
	
	// draw states for balls in column 1
	wire draw_0_0, draw_0_1, draw_0_2, draw_0_3, draw_hb_0;

	// draw states for balls in column 2
	wire draw_1_0, draw_1_1, draw_1_2, draw_1_3, draw_hb_1;

	// draw states for balls in column 2
	wire draw_2_0, draw_2_1, draw_2_2, draw_2_3, draw_hb_2;
	
	wire ld_end;
	 
	datapath d0
	(
		.clk(master_clock),
		.resetn(resetn),
		
		.plot(plot),
	 
		.clear(clear),
		
		.ld_end(ld_end),
    
		.colour_in(3'b001),
		.colour_hitbox({~KEY[3],~KEY[2],~KEY[1]}),
    
		.x_in_0(x_in_0),
		.y_in_0_0(y_in_0_0), 
		.y_in_0_1(y_in_0_1), 
		.y_in_0_2(y_in_0_2),
		.y_in_0_3(y_in_0_3),
		
		.x_in_1(x_in_1),
		.y_in_1_0(y_in_1_0), 
		.y_in_1_1(y_in_1_1), 
		.y_in_1_2(y_in_1_2),
		.y_in_1_3(y_in_1_3),
		
		.x_in_2(x_in_2),
		.y_in_2_0(y_in_2_0), 
		.y_in_2_1(y_in_2_1), 
		.y_in_2_2(y_in_2_2),
		.y_in_2_3(y_in_2_3),
	 
		.draw_0_0(draw_0_0),
		.draw_0_1(draw_0_1),
		.draw_0_2(draw_0_2),
		.draw_0_3(draw_0_3),
		.draw_hb_0(draw_hb_0),
	 
		.draw_1_0(draw_1_0),
		.draw_1_1(draw_1_1),
		.draw_1_2(draw_1_2),
		.draw_1_3(draw_1_3),
		.draw_hb_1(draw_hb_1),

		.draw_2_0(draw_2_0),
		.draw_2_1(draw_2_1),
		.draw_2_2(draw_2_2),
		.draw_2_3(draw_2_3),
		.draw_hb_2(draw_hb_2),
	 
		.x_out(x),
		.y_out(y),
		.colour_out(colour),

		.clear_status(clear_status),
		.draw_status(draw_status)
	 
	);

    
endmodule


module clearScreen(input clk,
						input clearEn,
						output reg clear_status,						// clear_status allows user of function to know that the function is finished
						output reg [7:0]x,
						output reg [6:0]y,
						output reg [2:0]color					  
						);
	reg[7: 0] counterx;
	reg[6: 0] countery;
	
	always@(posedge clk) begin
		
	
		if (clearEn == 1'b1) begin                // If clear En is on then clear screen ONCE
			 

			if (counterx == 8'd159 & countery == 7'd119) begin	// When counter hits x = 160 and y = 120 then stop clearing 
				 clear_status <= 1'b0;
			end 
			else begin
			clear_status <= 1'b1;							
			if (counterx < 160 ) begin							// count x to 160 then drop to 0
					counterx <= counterx + 8'd1 ;
				end
				else begin
					counterx <= 0;
					countery <= countery + 7'd1;				// count y to 120 then hold
				end
				
			end
		
			x <= counterx[7:0];						// set ALL pixels to black
			y <= countery[6:0];
			color <= 3'b111;								 
		 
		end

		else begin
														// clear is inactive
			counterx <= 8'd0;						// reset counter
			countery <= 7'd0;		
		end
		
	end



endmodule

module datapath
	(
		input clk,
		input resetn,
		
		input plot,
	 
		input clear,
		
		input ld_end,
    
		input [2:0] colour_in,
		input [2:0] colour_hitbox,
    
		input [7:0] x_in_0, 
		input [6:0] y_in_0_0,
		input [6:0] y_in_0_1,
		input [6:0] y_in_0_2, 
		input [6:0] y_in_0_3,

		input [7:0] x_in_1, 
		input [6:0] y_in_1_0,
		input [6:0] y_in_1_1,
		input [6:0] y_in_1_2, 
		input [6:0] y_in_1_3,
		
		input [7:0] x_in_2,
		input [6:0] y_in_2_0,
		input [6:0] y_in_2_1,
		input [6:0] y_in_2_2, 
		input [6:0] y_in_2_3,
	 
		input draw_0_0, draw_0_1, draw_0_2, draw_0_3, draw_hb_0,
	 
		input draw_1_0, draw_1_1, draw_1_2, draw_1_3, draw_hb_1,

		input draw_2_0, draw_2_1, draw_2_2, draw_2_3, draw_hb_2,
	 
		output [7:0] x_out,
		output [6:0] y_out,
		output [2:0] colour_out,

		output clear_status,
		output reg draw_status
	 
	);
    
    // input registers
	 reg [3:0] count_xy;
	 reg [2:0] hitbox_x;
	 reg [2:0] hitbox_y;
    reg [7:0] x;
	 reg [6:0] y;
	 reg [2:0] colour;
	 
	 wire[7:0] clear_x_out;
	 wire [6:0] clear_y_out;
	 wire [2:0] clear_colour;
															// Clear screen output if FSM says to clear screen
	clearScreen test(
		.clk(clk),
		.clear_status(clear_status),
		.clearEn(clear),
		.x(clear_x_out),
		.y(clear_y_out),
		.color(clear_colour)
	);
 
 
	always@(posedge clk) begin
	
		if(~resetn) begin									// resetting all values to orginal
			x <= 8'd0;
			y <= 7'd0; 
   
			colour <= 3'd0;
	
			count_xy <= 4'd0;

			hitbox_x <= 3'd0;
			hitbox_y <= 3'd0;
				
			draw_status <= 1'b0;

		end
		
		else begin
			
			if(clear & ~ld_end) begin					// On the case of just clearing the screen
					count_xy <= 4'd0;
					x <= clear_x_out;
					y <= clear_y_out;
					colour <= clear_colour;
				end
				
			if(ld_end) begin								// On the case of loading the end screen
					count_xy <= 4'd0;
					x <= clear_x_out;
					y <= clear_y_out;
					colour <= 3'b100;
			end

			if (plot & ~clear) begin					// When we want to draw the balls for all 3 coloumns


				if (draw_0_0) begin
					x <= x_in_0;
					y <= y_in_0_0;
					colour <= colour_in;
				end
				else if (draw_0_1) begin				//Draw Column 1 Ball 1-4
					y <= y_in_0_1;
					colour <= colour_in + 3'd1;
				end
				else if (draw_0_2) begin
					y <= y_in_0_2;
					colour <= colour_in + 3'd2;
				end
				else if (draw_0_3) begin
					y <= y_in_0_3;
					colour <= colour_in + 3'd3;
				end
				else if (draw_1_0) begin
					x <= x_in_1;	
					y <= y_in_1_0;
					colour <= colour_in;
				end
				else if (draw_1_1) begin				//Draw Column 2 Ball 1-4
					y <= y_in_1_1;
					colour <= colour_in + 3'd3;
				end
				else if (draw_1_2) begin
					y <= y_in_1_2;
					colour <= colour_in + 3'd2;
				end
				else if (draw_1_3) begin
					y <= y_in_1_3;
					colour <= colour_in + 3'd1;
				end
				else if (draw_2_0) begin
					x <= x_in_2;		
					y <= y_in_2_0;
					colour <= colour_in;
				end
				else if (draw_2_1) begin				//Draw Column 3 Ball 1-4
					y <= y_in_2_1;
					colour <= colour_in + 3'd3;
				end
				else if (draw_2_2) begin
					y <= y_in_2_2;
					colour <= colour_in + 3'd4;
				end
				else if (draw_2_3) begin
					y <= y_in_2_3;
					colour <= colour_in + 3'd5;
				end

			
			if (draw_hb_0 | draw_hb_1 | draw_hb_2) begin				// Draw the 3 hitboxes at the end of the screen
				
				if (draw_hb_0) begin
					x <=  x_in_0 - 6'd1;
					colour <= {colour_hitbox[2], 2'd0};					// When the user presses one of the Keys make each individual hitboxe change colour
					end
				else if (draw_hb_1) begin
					x <=  x_in_1 - 6'd1;
					colour <= {colour_hitbox[1], 2'd0};
					end
				else if (draw_hb_2) begin
					x <=  x_in_2 - 6'd1;
					colour <= {colour_hitbox[0], 2'd0};
					end

				y <=  7'd100;
					
				
				count_xy <= 4'd0;
				if (hitbox_y == 3'b110) // Y counter reset
					hitbox_y <= 3'b000;
		
				if (hitbox_x == 3'b101) begin
					hitbox_x <= 3'b000;	
					hitbox_y <= hitbox_y + 3'd1;
				end
					
				else if (hitbox_y == 3'd0 || hitbox_y == 3'd5 ) // fill top and bottom left right
					hitbox_x <= hitbox_x + 3'd1;
				else if ( hitbox_x == 3'd0 )	// move from most left to most right
					hitbox_x <= hitbox_x + 3'd5;
				else 
					hitbox_x <= hitbox_x + 3'd1;		
				end
												
			else begin				
				hitbox_x <= 3'd0;
				hitbox_y <= 3'd0;										//reset counters
				count_xy <= count_xy + 4'd1;
			end
				
				
			if (count_xy == 4'b1111 ||
				(hitbox_y == 3'b101 && hitbox_x == 3'b101)	//needed for making that holo pattern
				) 
			begin
				draw_status <= 1'b0;
				hitbox_x <= 3'd0;
				hitbox_y <= 3'd0;									//reset counters
			end
			
			else 
				draw_status <= 1'b1;
			end

		end
                
    end

	// set x,y colour out
	assign x_out = x + count_xy[1:0] + hitbox_x;
	assign y_out = y + count_xy[3:2] + hitbox_y;
	assign colour_out = colour;

    
endmodule

module control
	(
		input clk,
		input resetn,
		
		input go,
		input clear_status,
		input draw_status,
		input [7:0] lives,
		output reg plot,
		output reg clear,
		output reg ld_end,

		output reg draw_0_0, draw_0_1, draw_0_2, draw_0_3, draw_hb_0,

		output reg draw_1_0, draw_1_1, draw_1_2, draw_1_3, draw_hb_1,

		output reg draw_2_0, draw_2_1, draw_2_2, draw_2_3, draw_hb_2

	 );

    reg [5:0] current_state, next_state; 
    
    localparam  S_REFRESH_PAUSE 			= 5'd0,
					 S_REFRESH_WAIT 			= 5'd1,
					 S_CLEAR 					= 5'd2,
					 
					 STATE_DRAW_0_0 			= 5'd3,
					 STATE_DRAW_0_1 			= 5'd4,
					 STATE_DRAW_0_2 			= 5'd5,
					 STATE_DRAW_0_3 			= 5'd6,
					 S_DRAW_H0					= 5'd7,
					 
					 STATE_DRAW_1_0 			= 5'd8,
					 STATE_DRAW_1_1 			= 5'd9,
					 STATE_DRAW_1_2 			= 5'd10,
					 STATE_DRAW_1_3 			= 5'd11,
					 S_DRAW_H1					= 5'd12,

					 
					 STATE_DRAW_2_0 			= 5'd13,
					 STATE_DRAW_2_1 			= 5'd14,
					 STATE_DRAW_2_2 			= 5'd15,
					 STATE_DRAW_2_3 			= 5'd16,
					 S_DRAW_H2					= 5'd17,
					 S_END						= 5'd18;
					 

					 
			 
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)					 
					 S_REFRESH_PAUSE: next_state = go ? S_REFRESH_WAIT : S_REFRESH_PAUSE; // Loop in current state until value is input
                S_REFRESH_WAIT: next_state = go ? S_REFRESH_WAIT : S_CLEAR; // Loop in current state until go signal goes low
                
					 S_CLEAR: next_state = (~clear_status) ? STATE_DRAW_0_0 : S_CLEAR; // Restart FSM
                
					 STATE_DRAW_0_0: next_state = (~draw_status) ? STATE_DRAW_0_1 : STATE_DRAW_0_0; // Loop in current state until value is input
                STATE_DRAW_0_1: next_state = (~draw_status) ? STATE_DRAW_0_2 : STATE_DRAW_0_1; // Loop in current state until value is input
                STATE_DRAW_0_2: next_state = (~draw_status) ? STATE_DRAW_0_3: STATE_DRAW_0_2; // Loop in current state until value is input
                STATE_DRAW_0_3: next_state = (~draw_status) ? S_DRAW_H0 : STATE_DRAW_0_3; // Loop in current state until value is input
                S_DRAW_H0: next_state = (~draw_status) ? STATE_DRAW_1_0 : S_DRAW_H0; // Loop in current state until value is input
					 
					 STATE_DRAW_1_0: next_state = (~draw_status) ? STATE_DRAW_1_1 : STATE_DRAW_1_0; // Loop in current state until value is input
                STATE_DRAW_1_1: next_state = (~draw_status) ? STATE_DRAW_1_2 : STATE_DRAW_1_1; // Loop in current state until value is input
                STATE_DRAW_1_2: next_state = (~draw_status) ? STATE_DRAW_1_3: STATE_DRAW_1_2; // Loop in current state until value is input
                STATE_DRAW_1_3: next_state = (~draw_status) ? S_DRAW_H1 : STATE_DRAW_1_3; // Loop in current state until value is input
                S_DRAW_H1: next_state = (~draw_status) ? STATE_DRAW_2_0 : S_DRAW_H1; // Loop in current state until value is input

					 STATE_DRAW_2_0: next_state = (~draw_status) ? STATE_DRAW_2_1 : STATE_DRAW_2_0; // Loop in current state until value is input
                STATE_DRAW_2_1: next_state = (~draw_status) ? STATE_DRAW_2_2 : STATE_DRAW_2_1; // Loop in current state until value is input
                STATE_DRAW_2_2: next_state = (~draw_status) ? STATE_DRAW_2_3: STATE_DRAW_2_2; // Loop in current state until value is input
                STATE_DRAW_2_3: next_state = (~draw_status) ? S_DRAW_H2 : STATE_DRAW_2_3; // Loop in current state until value is input
                S_DRAW_H2: next_state = (~draw_status) ? S_REFRESH_PAUSE : S_DRAW_H2; // Loop in current state until value is input
					

        endcase
    end // state_table

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        plot 		= 1'b0;
		  clear 		= 1'b0;

		  draw_0_0 	= 1'b0;
		  draw_0_1 	= 1'b0;
		  draw_0_2 	= 1'b0;
		  draw_0_3 	= 1'b0;
		  draw_hb_0 = 1'b0;

		  draw_1_0 	= 1'b0;
		  draw_1_1 	= 1'b0;
		  draw_1_2 	= 1'b0;
		  draw_1_3 	= 1'b0;
		  draw_hb_1 = 1'b0;

		  draw_2_0 	= 1'b0;
		  draw_2_1 	= 1'b0;
		  draw_2_2 	= 1'b0;
		  draw_2_3 	= 1'b0;
		  draw_hb_2 = 1'b0;
		  
		  ld_end 	= 1'b0;
		  
        case (current_state)
            S_CLEAR: begin
                clear = 1'b1;
					 plot = 1'b1;
                end

            STATE_DRAW_0_0: begin
					 draw_0_0 = 1'b1;
                plot = 1'b1;
                end
            STATE_DRAW_0_1: begin
					 draw_0_1 = 1'b1;
                plot = 1'b1;
                end
            STATE_DRAW_0_2: begin
					 draw_0_2 = 1'b1;
                plot = 1'b1;
                end
            STATE_DRAW_0_3: begin
					 draw_0_3 = 1'b1;
                plot = 1'b1;
                end
				S_DRAW_H0: begin
					 draw_hb_0 = 1'b1;
                plot = 1'b1;
                end

            STATE_DRAW_1_0: begin
					 draw_1_0 = 1'b1;
                plot = 1'b1;
                end
            STATE_DRAW_1_1: begin
					 draw_1_1 = 1'b1;
                plot = 1'b1;
                end
            STATE_DRAW_1_2: begin
					 draw_1_2 = 1'b1;
                plot = 1'b1;
                end
            STATE_DRAW_1_3: begin
					 draw_1_3 = 1'b1;
                plot = 1'b1;
                end
				S_DRAW_H1: begin
					 draw_hb_1 = 1'b1;
                plot = 1'b1;
                end

            STATE_DRAW_2_0: begin
					 draw_2_0 = 1'b1;
                plot = 1'b1;
                end
            STATE_DRAW_2_1: begin
					 draw_2_1 = 1'b1;
                plot = 1'b1;
                end
            STATE_DRAW_2_2: begin
					 draw_2_2 = 1'b1;
                plot = 1'b1;
                end
            STATE_DRAW_2_3: begin
					 draw_2_3 = 1'b1;
                plot = 1'b1;
                end
				S_DRAW_H2: begin
					 draw_hb_2 = 1'b1;
                plot = 1'b1;
                end
				S_END: begin
					clear = 1'b1;
					ld_end = 1'b1;
					plot = 1'b1;
					end

        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(~resetn)
				current_state <= S_REFRESH_PAUSE;
		  else if (lives >= 8'd45)
            current_state <= S_END;
        else
            current_state <= next_state;
    end // state_FFS
endmodule


// rate divider 50 Mhz to ~60 Hz
module refresh_rate_counter
	(
		input clk,
		input resetn,
		output reg refresh
		
	);
	
	reg [19:0] q; // reg for curr val
		
	always @ (posedge clk, negedge resetn)
	begin
		if (~resetn)
			q <= 20'd833333;
		else if (q == 20'd0) begin // reset
			q <= 20'd833333;
			refresh <= 1'b1;
		end
		else begin
			q <= q - 20'd1;
			refresh <= 1'b0;
		end

	end

endmodule

// counts for 15 fps given a 60Hz counter
module frames_counter
	(
		input clk,
		input refresh,
		
		output reg go
		
	);
	
	reg [3:0] q; // reg for curr val
		
	always @ (posedge clk)
	begin
		if (q == 4'd0) begin // reset
			q <= 4'd15;
			go <= 1'b1;
		end
		else if (refresh) begin		// For every 3 frames send out a signal
			q <= q - 4'd5;
			go <= 1'b0;
			end
		else
			go <= 1'b0;

	end

endmodule

// rate divider 50 Mhz to ~60 Hz
module position_counter
	(
		input clk,
		input update,
		input resetn,
		input go,
		input [6:0] origin,
		input reset,
		output reg [6:0] q
	);
	
			
	always @ (posedge clk, negedge resetn, posedge reset)
	begin
		if (resetn == 1'b0)			// Over all reset
			q <= origin;
		else if (reset)				// reset refers to when the user scores a point by clicking on the ball
			q <= 7'd5;
		else if (q == 7'd120)		// shove the ball back up to the top of the screen
			q <= 7'd0;
		else if (update)
			q <= q + 7'd1;				// increase y value of each ball
		else
			q <= q + 7'd0;				// prevent latch

	end

endmodule

// module for positive edge triggered flip flop
module flipFlop(d, q, clk, resetn);
	input [7:0]d; // input data
	input clk, resetn; // clock and reset input
	output reg [7:0]q; // output
	
	// positive edge flip flop, that is triggered everytime the clock rises
	always @(posedge clk)
	begin
		q <= d;
	end

endmodule

module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule

module user_input
	(

		input key, // user input
		input refresh,
		input resetn,
		input [6:0] y_in_0, // locations of key-notes
		input [6:0] y_in_1,
		input [6:0] y_in_2,
		input [6:0] y_in_3,
		
		output reg reset_y_0, // output resets for setting the
		output reg reset_y_1,
		output reg reset_y_2,
		output reg reset_y_3,
		output reg add_score,
		output reg [15:0] score,	// reg for curr 
		output reg [7:0] lives
	
	);


	always @ (negedge key, posedge refresh, negedge resetn)
	begin

																
	
		if (~resetn) begin													// reset
			score <= 16'd0;
			lives = 8'b00000000;
		end
		else if (refresh) begin
			reset_y_0 = 1'b0;
			reset_y_1 = 1'b0;
			reset_y_2 = 1'b0;
			reset_y_3 = 1'b0;
		end
		else begin
			if (y_in_0 + 7'd4  > 7'd100 && y_in_0  < 7'd107) begin // hit regestration of ball 1 and accont for score
				reset_y_0 = 1'b1;
				score <= score + 4'd1;
			end

			else if (y_in_1 + 7'd4  > 7'd100 && y_in_1  < 7'd107) begin // hit regestration of ball 2 and accont for score
				reset_y_1 = 1'b1;
				score <= score + 4'd1;
			end

			else if (y_in_2 + 7'd4  > 7'd100 && y_in_2  < 7'd107) begin // hit regestration of ball 3 and accont for score
				reset_y_2 = 1'b1;
				score <= score + 4'd1;

			end

			else if (y_in_3 + 7'd4  > 7'd100 && y_in_3  < 7'd107) begin // hit regestration of ball 4 and accont for score
				reset_y_3 = 1'b1;
				score <= score + 4'd1;
			end
			else begin
				lives <= lives + 1'd1;												// if user clicks and doesnt hit a ball make them lose lives
			end
		end
	end
	
endmodule

// Score Counter
module score_counter
	(
		input add_score_0, add_score_1, add_score_2,
		input resetn,
		output reg [3:0] score
	);
	
			
	always @ (posedge add_score_0, posedge add_score_1, posedge add_score_2, negedge resetn)
	begin
		if (resetn == 1'b0)
			score <= 4'd0;
		else if(add_score_0 | add_score_1 | add_score_2)
			score <= score + 4'd1;
		else
			score <= score + 4'd0;
	end

endmodule

// 2 to 1 mux
module Twoto1mux(S, IN, OUT);
    input [1:0] IN; // 7 in
	 input S; // 3 switches
	 output reg OUT; // out
	 
	 // always update when any change to switches
	 always @(*)
	 begin
		case(S)
			1'b0: OUT = IN[0];
			1'b1: OUT = IN[1];
			
			default: OUT = 1'b0; // default to 0
			
		endcase

	end
endmodule
