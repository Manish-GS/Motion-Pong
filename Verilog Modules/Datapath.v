module Datapath(clock,
                resetn,
                gameSpeed,
                
                HEX0,
                HEX1,
                HEX2,
                HEX3,

                ld_Val,

                data,
                sensor_1,
                sensor_2,

                sel_out,
                sel_col,

                en_B_shapeCounter_D,
                en_B_shapeCounter_E,

                en_P1_shapeCounter_D,
                en_P1_shapeCounter_E,

                en_P2_shapeCounter_D,
                en_P2_shapeCounter_E,

                en_delayCounter,
                
                x_out,
                y_out,
                colour_out,

                fin_Wait,

                fin_P1_D,
                fin_P1_E,

                fin_P2_D,
                fin_P2_E,

                fin_B_D,
                fin_B_E);

/* ------------- INPUT SIGNALS ------------- */

    /* --  FROM THE DE2 BOARD -- */
        input clock;                // The clock signal.
        input resetn;               // The reset signal.

    /* -- FROM THE USER -- */
        /* SWITCHES AND BUTTONS */
        input [27:0] gameSpeed;     // Determines the Speed at which the game is played.
        input [9:0] data;           // Data from the user about colours of the shape.

        /* ULTRASONIC */
        input [9:0] sensor_1;       // Data from ultrasonic sensor 1.
        input [9:0] sensor_2;       // Data from ultrasonic sensor 2.


    /* -- FROM CONTROL MODULE -- */
        /* OUPUT CONTROL */
        input [1:0] sel_out;        // Determines the shape to draw.
        input [1:0] sel_col;        // Determines the colour of each shape.
        input en_delayCounter;      // Enable signal for the delay.

        /* GENERAL CONTROLS */
        input ld_Val;

        /* BALL CONTROLS */
        input en_B_shapeCounter_D;
        input en_B_shapeCounter_E;
        
        /* PADDLE 1 CONTROLS */
        input en_P1_shapeCounter_D;
        input en_P1_shapeCounter_E;

        /* PADDLE 2 CONTROLS */
        input en_P2_shapeCounter_D;
        input en_P2_shapeCounter_E;
    

/* ----------- END INPUT SIGNALS ----------- */

/* ------------- OUTPUT SIGNALS ------------- */

    /* TO THE VGA ADAPTER */
    output reg [2:0] colour_out;    // The Colour output to the VGA Adapter
    output reg [9:0] x_out;         // The X Coordinate of the shape to the VGA Adapter
	output reg [9:0] y_out;         // The Y Coordinate of the shape to the VGA Adapter

    /* TO THE CONTROL MODULE */
    output fin_Wait;
    output fin_B_D, fin_B_E;
    output fin_P1_D, fin_P1_E;
    output fin_P2_D, fin_P2_E;

    /* TO THE HEX DISPLAY */
    output [6:0] HEX0;
    output [6:0] HEX1;
    output [6:0] HEX2;
    output [6:0] HEX3;

/* ----------- END OUTPUT SIGNALS ----------- */

/* --------------- VARIABLES --------------- */

    // Scores of Player 1 and Player 2
    reg [7:0] player_1_score, player_2_score;

    // Registers for both counters
    reg [27:0] delayCounter;

    // Registers for ball counters
    reg [3:0] B_shapeCounter_D;
    reg [3:0] B_shapeCounter_E;
    reg [9:0] B_XposCounter;
    reg [9:0] B_YposCounter;

    // Registers for paddle1 counters
    reg [5:0] P1_shapeCounter_D;
    reg [5:0] P1_shapeCounter_E;
    reg [7:0] P1_Position;

    // Registers for paddle1 counters
    reg [5:0] P2_shapeCounter_D;
    reg [5:0] P2_shapeCounter_E;
    reg [7:0] P2_Position;

    // Registers for ball direction
    reg B_X_dir;
    reg B_Y_dir;

    // Register for paddle1 counter
    reg P1_dir;

    // Registes for paddle2 counter
    reg P2_dir;

    // Register for original Ball Position
    reg [9:0] OG_B_x;    // Store the original x position of the ball
	reg [9:0] OG_B_y;    // Store the original y position of the ball

    // Register for original Paddle1 Position
    reg [9:0] OG_P1_x;    // Store the original x position of the ball
	reg [9:0] OG_P1_y;    // Store the original y position of the ball

    // Register for original Paddle1 Position
    reg [9:0] OG_P2_x;    // Store the original x position of the ball
	reg [9:0] OG_P2_y;    // Store the original y position of the ball


    // WIRES

    // Datapath to Control wires
    wire fin_B_D;       // Determines whether the shape counter for draw is finished
    wire fin_B_E;       // Determines whether the shape counter for erase is finished

    wire fin_P1_D;      // Determines whether the shape counter for draw is finished
    wire fin_P1_E;      // Determines whether the shape counter for erase is finished

    wire fin_P2_D;      // Determines whether the shape counter for draw is finished
    wire fin_P2_E;      // Determines whether the shape counter for erase is finished

    wire fin_Wait;      // Determines whether the waiting is done

    // Internal Wires
    wire B_moveX, B_moveY;  // for Ball
    wire P1_move;           // for Paddle1
    wire P2_move;           // for Paddle2

    // helper assignments for ball
    assign fin_B_D = (B_shapeCounter_D == 4'd15) ? 1 : 0;
    assign fin_B_E = (B_shapeCounter_E == 4'd15) ? 1 : 0;
    assign B_moveX = fin_B_E;
    assign B_moveY = fin_B_E;

    // helper assignments for paddle1
    assign fin_P1_D = (P1_shapeCounter_D == 6'd63) ? 1 : 0;
    assign fin_P1_E = (P1_shapeCounter_E == 6'd63) ? 1 : 0;
    assign P1_move = fin_P1_E;

    // assign P1_move = ((sel_out == 2'd1 | sel_out == 2'd3) & (P1_shapeCounter == 6'd63)) ? 1 : 0;

    // helper assignments for paddle1
    assign fin_P2_D = (P2_shapeCounter_D == 6'd63) ? 1 : 0;
    assign fin_P2_E = (P2_shapeCounter_E == 6'd63) ? 1 : 0;
    assign P2_move = fin_P2_E;

    // assign P2_move = ((sel_out == 2'd1 | sel_out == 2'd3) & (P2_shapeCounter == 6'd63)) ? 1 : 0;

    assign fin_Wait = (delayCounter == 28'd0) ? 1 : 0;


/* ------------- END VARIABLES ------------- */

/* --------------- COUNTERS --------------- */
    // 1. DELAY Counter
    /* 
        The Counter counts down from a value which
        is exactly 1/60th of a second.

        Value = 20'd833333 - 1'b1
    */
    always @(posedge clock)
    begin
        if(delayCounter == 28'd0)
            delayCounter <= gameSpeed ;   //28'd833333 - 1'b1;
        else if(en_delayCounter == 1'b1)
            delayCounter <= delayCounter - 1'b1;
    end
/* ------------- END COUNTERS ------------- */

/* ------------- BALL COUNTERS ------------- */
    // 1. SHAPE Counter
    /* 
        The counter helps to draw a shape by adding
        to the existing x and y value.
    */
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            B_shapeCounter_D <= 4'b0000;
        else if(en_B_shapeCounter_D == 1'b1)
            B_shapeCounter_D <= B_shapeCounter_D + 1'b1;
        else if(en_B_shapeCounter_E == 1'b1)
            B_shapeCounter_E <= B_shapeCounter_E + 1'b1;
    end

    // 2. BALL - X POSITION Counter
    /* 
        The counter helps to move the ball around the
        screen in the x direction
    */
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
        begin
            B_XposCounter <= 10'd0;
            B_YposCounter <= 10'd0;
        end
        else if((B_moveX == 1'b1) & (B_X_dir == 1'b1))
            B_XposCounter <= B_XposCounter + 1'b1;
        else if((B_moveX == 1'b1) & (B_X_dir == 1'b0))
            B_XposCounter <= B_XposCounter - 1'b1;
        else if(OG_B_x + B_XposCounter == OG_P1_x - 1'b1)        // Reset the ball to be in the middle, and Player 2 wins
            begin
                B_XposCounter <= 10'd0;
                player_2_score <= player_2_score + 1'b1;
            end
            
        else if(OG_B_x + B_XposCounter + 2'd2 == OG_P2_x + 1'b1)   //Reset ball to middle, and Player 1 wins
            begin
                B_XposCounter <= 10'd0; 
                player_1_score <= player_1_score + 1'b1;
            end
        
        if((B_moveY == 1'b1) & (B_Y_dir == 1'b1))
            B_YposCounter <= B_YposCounter + 1'b1;
        if((B_moveY == 1'b1) & (B_Y_dir == 1'b0))
            B_YposCounter <= B_YposCounter - 1'b1;
    end

/* ----------- END BALL COUNTERS ----------- */

/* ------------ PADDLE1 COUNTERS ------------ */
    // 1. SHAPE Counter
    /* 
        The counter helps to draw a shape by adding
        to the existing x and y value.
    */
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            P1_shapeCounter_D <= 6'd0;
        else if(en_P1_shapeCounter_D == 1'b1)
        begin    
            P1_shapeCounter_D <= P1_shapeCounter_D + 1'b1; 
        end
        else if(en_P1_shapeCounter_E == 1'b1)
            P1_shapeCounter_E <= P1_shapeCounter_E + 1'b1;
    end

    // 2. PADDLE1 - Y POSITION Counter
    /* 
        The counter helps to move the ball around the
        screen in the x direction
    */
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            P1_Position <= 10'd1;
        
        // set the position to 0 if the sensor is in the blind spot
        if((P1_move == 1'b1) & (sensor_1 < 7) & (P1_Position < 10'd0))
            P1_Position <= P1_Position - 1'b1;

        // While the paddle isn't being drawn over or at 120 pixels long, continue
        else if(OG_P1_y + P1_Position + 4'd15 < 10'd120)
        begin

            // If the user is moving their hand away from the sensor, move the paddle down
            if((P1_move == 1'b1) & (P1_Position < (sensor_1 - 2'd2) * 7) & (sensor_1 < 5'd20))

                if(((sensor_1 - 2'd2) * 7) - P1_Position > 80)
                    P1_Position <= P1_Position + 6'd40;

                else if(((sensor_1 - 2'd2) * 7) - P1_Position > 50)
                    P1_Position <= P1_Position + 5'd20;

                else if(((sensor_1 - 2'd2) * 7) - P1_Position > 20)
                    P1_Position <= P1_Position + 3'd4;

                else
                    P1_Position <= P1_Position + 2'd2;

            // Else if user is moving hand TOWARD the sensor, move it up
            else if((P1_move == 1'b1) & (P1_Position > (sensor_1 - 2'd2) * 7) & (sensor_1 < 5'd20))

                if(P1_Position - ((sensor_1 - 2'd2) * 7) > 80)
                    P1_Position <= P1_Position - 6'd40;

                else if(P1_Position - ((sensor_1 - 2'd2) * 7) > 50)
                    P1_Position <= P1_Position - 5'd20;

                else if(P1_Position - ((sensor_1 - 2'd2) * 7) > 20)
                    P1_Position <= P1_Position - 3'd4;

                else
                    P1_Position <= P1_Position - 1'b1;
        end
        
        // If the paddle is going to overflow, decrement it
        else if(OG_P1_y + P1_Position + 4'd15 >= 10'd120)
            P1_Position <= P1_Position - 1'b1;
        
    end    


// ---------- END PADDLE COUNTERS ---------- //

/* ------------ PADDLE2 COUNTERS ------------ */
    // 1. SHAPE Counter
    /* 
        The counter helps to draw a shape by adding
        to the existing x and y value.
    */
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            P2_shapeCounter_D <= 6'd0;
        else if(en_P2_shapeCounter_D == 1'b1)
            P2_shapeCounter_D <= P2_shapeCounter_D + 1'b1;
        else if(en_P2_shapeCounter_E == 1'b1)
            P2_shapeCounter_E <= P2_shapeCounter_E + 1'b1;
    end

    // 2. PADDLE1 - Y POSITION Counter
    /* 
        The counter helps to move the ball around the
        screen in the x direction
    */
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            P2_Position <= 10'd0;

        // Set the position to 0 if the sensor is in the blind spot
        if((P2_move == 1'b1) & (sensor_2 < 7) & (P2_Position < 10'd0))
            P2_Position <= P2_Position - 1'b1;

        // While the paddle isn't being drawn over or at 120 pixels long, continue
        else if(OG_P2_y + P2_Position + 4'd15 < 10'd120)
        begin
            // If the user is moving their hand AWAY from the sensor, move the paddle down
            if((P2_move == 1'b1) & (P2_Position < (sensor_2 - 2) * 7) & (sensor_2 < 5'd20))
            
                if(((sensor_2 - 2'd2) * 7) - P2_Position > 80)
                    P2_Position <= P2_Position + 6'd40;

                else if(((sensor_2 - 2'd2) * 7) - P2_Position > 50)
                    P2_Position <= P2_Position + 5'd20;

                else if(((sensor_2 - 2'd2) * 7) - P2_Position > 20)
                    P2_Position <= P2_Position + 3'd4;
                    
                else
                    P2_Position <= P2_Position + 1'b1;

            // Else if user is moving hand TOWARD the sensor, move it up
            if((P2_move == 1'b1) & (P2_Position > (sensor_2 - 2) * 7) & (sensor_2 < 5'd20))
            
                if(P2_Position - ((sensor_2 - 2'd2) * 7) > 80)
                    P2_Position <= P2_Position - 6'd40;

                else if(P2_Position - ((sensor_2 - 2'd2) * 7) > 50)
                    P2_Position <= P2_Position - 5'd20;

                else if(P2_Position - ((sensor_2 - 2'd2) * 7) > 20)
                    P2_Position <= P2_Position - 3'd4;

                else
                    P2_Position <= P2_Position - 1'b1;
        end
        // If the paddle is going to overflow, decrement it
        else if(OG_P2_y + P2_Position + 4'd15 >= 10'd120)
            P2_Position <= P2_Position - 1'b1;
    end    


// ---------- END PADDLE COUNTERS ---------- //


// ------------- REGISTERS ------------- //

    /* 
        STORING POSITIONS

        Stores the original positions of
        -> Ball
        -> Paddles.
    */
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
        begin
            OG_B_y <= 10'd0;    // Reset the Y Coordinate of the Ball
            OG_B_x <= 10'd0;    // Reset the X Coordinate of the Ball
            OG_P1_y <= 10'd0;   // Reset the Y Coordinate of the Paddle 1
            OG_P1_x <= 10'd0;   // Reset the X Coordinate of the Paddle 1
            OG_P2_y <= 10'd0;   // Reset the Y Coordinate of the Paddle 2
            OG_P2_x <= 10'd0;   // Reset the X Coordinate of the Paddle 2
        end
        else if(ld_Val == 1'b1)
        begin
            OG_B_y <= 10'd60;   // Store the Y Coordinate of the Ball
            OG_B_x <= 10'd80;   // Store the X Coordinate of the Ball
            OG_P1_y <= 10'd0;   // Store the Y Coordinate of the Paddle 1
            OG_P1_x <= 10'd15;   // Store the X Coordinate of the Paddle 1
            OG_P2_y <= 10'd0;   // Store the Y Coordinate of the Paddle 2
            OG_P2_x <= 10'd144; // Store the X Coordinate of the Paddle 2
        end
    end

    /* 
        COLLISION DETECTION 

        Determines whether a collision occured between the Ball
        and one of the following.
        -> Top Wall
        -> Bottom Wall
        -> Paddle 1
        -> Paddle 2
    */
    always @(posedge clock)
    begin
        // Check the collision against Paddle 1
        if((OG_B_x + B_XposCounter == OG_P1_x + 1'b1) & (OG_B_y + B_YposCounter + 2'd2 >= OG_P1_y + P1_Position) & (OG_B_y + B_YposCounter <= OG_P1_y + P1_Position + 4'd15))
            B_X_dir <= 1'b1;    // If collision change the X direction to right

        // Check the collision against Paddle 2
        else if((OG_B_x + B_XposCounter + 2'd2 == OG_P2_x) & (OG_B_y + B_YposCounter + 2'd2 >= OG_P2_y + P2_Position) & (OG_B_y + B_YposCounter <= OG_P2_y + P2_Position + 4'd15))
            B_X_dir <= 1'b0;    // If collision change the X direction to left

        // Check the collision against the Top wall
        else if(OG_B_y + B_YposCounter == 8'd0)
            B_Y_dir <= 1'b1;    // If collision change the Y direction to down
            
        // Check the collision against the Bottom wall
        else if(OG_B_y + B_YposCounter + 2'd2 == 8'd118)
            B_Y_dir <= 1'b0;    // If collision change the Y direction to up

        else if(OG_B_x + B_XposCounter == OG_P1_x - 1'b1)
            B_X_dir <= 1'b1;

        else if(OG_B_x + B_XposCounter + 2'd2 == OG_P2_x + 1'b1)
            B_X_dir <= 1'b0;
    end
// ----------- END REGISTERS ----------- // 

    // Determine the Colour Output of the Ball and the Paddles
    always @(*)
		begin
			case (sel_col)
				2'd0: colour_out = data[9:7];
				2'd1: colour_out = 3'd0;
                2'd2: colour_out = data[3:0];
                2'd3: colour_out = 3'd0;
			endcase
		end
    // Determine the X Coordinate of the Ball and the Paddles
    always @(*)
        begin
            case (sel_out)
                2'd0: x_out = OG_B_x + B_shapeCounter_D[1:0] + B_shapeCounter_E[1:0] + B_XposCounter;
                2'd1: x_out = OG_P1_x;
                2'd2: x_out = OG_P2_x;
                default: x_out = OG_B_x + B_shapeCounter_D[1:0] + B_shapeCounter_E[1:0] + B_XposCounter;
            endcase
        end

    // Determine the Y Coordinate of the ball and the Paddles
    always @(*)
        begin
            case (sel_out)
                2'd0: y_out = OG_B_y + B_shapeCounter_D[3:2] + B_shapeCounter_E[3:2] + B_YposCounter;
                2'd1: y_out = OG_P1_y + P1_shapeCounter_D[5:2] + P1_shapeCounter_E[5:2] + P1_Position;
                2'd2: y_out = OG_P2_y + P2_shapeCounter_D[5:2] + P2_shapeCounter_E[5:2] + P2_Position;
                default: y_out = OG_B_y + B_shapeCounter_D[3:2] + B_shapeCounter_E[3:2] + B_YposCounter;
            endcase
        end

    /* Hex displays to show Player 1 and Player 2 scores */
    Hex_display player1ScorePart1(
        .IN(player_1_score[3:0]),
        .OUT(HEX2)
    );

    Hex_display player1ScorePart2(
        .IN(player_1_score[7:4]),
        .OUT(HEX3)
    );    

    Hex_display player2ScorePart1(
        .IN(player_2_score[3:0]),
        .OUT(HEX0)
    );

    Hex_display player2ScorePart2(
        .IN(player_2_score[7:4]),
        .OUT(HEX1)
    );

endmodule // datapath