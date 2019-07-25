module Datapath(clock,
                resetn,
                gameSpeed,
                
                HEX0,
                HEX1,
                HEX2,
                HEX3,

                data,
                sensor_1,
                sensor_2,

                sel_out,
                sel_col,
                
                ld_bx,
                ld_by,

                ld_p1x,
                ld_p1y,

                ld_p2x,
                ld_p2y,
                
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

    /* FROM DE2 BOARD */

    input clock, resetn;
    input [9:0] data;
    input [27:0] gameSpeed;

    /* FROM CONTROL MODULE */

    /* OUPUT CONTROL */
    // Determines which shape to draw
    input [1:0] sel_out;
    input [1:0] sel_col;
    input en_delayCounter;

    /* BALL CONTROLS */
    input ld_bx, ld_by;
    input en_B_shapeCounter_D;
    input en_B_shapeCounter_E;
    
    /* PADDLE 1 CONTROLS */
    input [9:0] sensor_1;   // Data from ultrasonic sensor
    input ld_p1x, ld_p1y;
    input en_P1_shapeCounter_D;
    input en_P1_shapeCounter_E;

    /* PADDLE 2 CONTROLS */
    input [9:0] sensor_2;   // Data from ultrasonic sensor
    input ld_p2x, ld_p2y;
    input en_P2_shapeCounter_D;
    input en_P2_shapeCounter_E;
    

/* ----------- END INPUT SIGNALS ----------- */

/* ------------- OUTPUT SIGNALS ------------- */

    /* TO VGA_Adapter */
    output reg [2:0] colour_out;
    output reg [9:0] x_out;
	output reg [9:0] y_out;

    /* TO Control Module */
    output fin_Wait;
    output fin_B_D, fin_B_E;
    output fin_P1_D, fin_P1_E;
    output fin_P2_D, fin_P2_E;

    /*HEX displays scores for each Player*/
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
        else if(OG_B_x + B_XposCounter == 10'd0)        // Reset the ball to be in the middle, and Player 2 wins
            begin
                B_XposCounter <= 10'd0;
                B_YposCounter <= 10'd0;
                player_2_score <= player_2_score + 1'b1;
            end
            
        else if(OG_B_x + B_XposCounter + 2'd2 == 10'd160)   //Reset ball to middle, and Player 1 wins
            begin
                B_XposCounter <= 10'd0; 
                B_YposCounter <= 10'd0;
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
            P1_Position <= 10'd0;
        else if((P1_move == 1'b1) & (P1_Position < (sensor_1 - 2'd2) * 7) & (sensor_1 < 5'd18))
        # Move
        if((sensor_1 - 2'd2) * 7 - P1_Position > 100)
                P1_Position <= P1_Position + 5'd10;
        else if((sensor_1 - 2'd2) * 7 - P1_Position > 3'd5)
                P1_Position <= P1_Position + 2'd2;
            else
                P1_Position <= P1_Position + 1'b1;
        
        else if((P1_move == 1'b1) & (P1_Position > (sensor_1 - 2'd2) * 7) & (sensor_1 < 5'd18))
            // if(P1_Position - (sensor_1 - 2'd2) * 7 > 50)
            //     P1_Position <= P1_Position - 4'd8;
            // else 
            if(P1_Position - (sensor_1 - 2'd2) * 7 > 3'd5)
                P1_Position <= (sensor_1 - 2'd2) * 4'd7;
                //P1_Position <= P1_Position - 2'd2;
            else
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
        else if((P2_move == 1'b1) & (P2_Position < (sensor_2 - 2) * 7) & (sensor_2 < 5'd18))
            // if((sensor_2 - 2) * 7 - P2_Position > 50)
            //     P2_Position <= P2_Position + 4'd8;
            // else 
            if((sensor_2 - 2) * 7 - P2_Position > 3'd5)
                //P2_Position <= P2_Position + 2'd2;
                P2_Position <= (sensor_2 - 2'd2) * 4'd7;
            else
                P2_Position <= P2_Position + 1'b1;
        
        else if((P2_move == 1'b1) & (P2_Position > (sensor_2 - 2) * 7) & (sensor_2 < 5'd18))
            // if(P2_Position - (sensor_2 - 2) * 7 > 50)
            //     P2_Position <= P2_Position - 4'd8;
            // else 
            if(P2_Position - (sensor_2 - 2) * 7 > 3'd5)
                //P2_Position <= P2_Position - 2'd2;
                P2_Position <= (sensor_2 - 2'd2) * 4'd7;
            else
                P2_Position <= P2_Position - 1'b1;
    end    


// ---------- END PADDLE COUNTERS ---------- //


// ------------- REGISTERS ------------- //

	// register for x
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            OG_B_x <= 10'd0;
        else if(ld_bx == 1'b1)
            OG_B_x <= 10'd80;
    end

    // register for y
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            OG_B_y <= 10'd0;
        else if(ld_by == 1'b1)
            OG_B_y <= 10'd60;
    end

    // register for x paddle1
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            OG_P1_x <= 10'd0;
        else if(ld_bx == 1'b1)
            OG_P1_x <= 10'd0;
    end

    // register for y paddle1
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            OG_P1_y <= 10'd0;
        else if(ld_by == 1'b1)
            OG_P1_y <= 10'd0;
    end

    // register for x paddle1
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            OG_P2_x <= 10'd0;
        else if(ld_p2x == 1'b1)
            OG_P2_x <= 10'd159;
    end

    // register for y paddle1
    always @(posedge clock)
    begin
        if(resetn == 1'b0)
            OG_P2_y <= 10'd0;
        else if(ld_p2y == 1'b1)
            OG_P2_y <= 10'd0;
    end

    // Collision Detection
    // Ball detection with the walls
    always @(posedge clock)
    begin
         //else if(OG_B_x + B_shapeCounter_D[1:0] + B_shapeCounter_E[1:0] + B_XposCounter == 10'd160)
            //B_X_dir <= 1'b0;
        if((OG_B_x + B_shapeCounter_D[1:0] + B_shapeCounter_E[1:0] + B_XposCounter == OG_P1_x + 1'b1) &
           (OG_B_y + B_YposCounter >= OG_P1_y + P1_Position) &
           (OG_B_y + B_shapeCounter_D[3:2] + B_shapeCounter_E[3:2] + B_YposCounter <= OG_P1_y + 4'd15 + P1_Position))
            begin
                B_X_dir <= 1'b1;
            end
        else if((OG_B_x + B_shapeCounter_D[1:0] + B_shapeCounter_E[1:0] + B_XposCounter + 2'd2 == OG_P2_x) &
                (OG_B_y + B_YposCounter >= OG_P2_y + P2_Position) &
                (OG_B_y + B_shapeCounter_D[3:2] + B_shapeCounter_E[3:2] + B_YposCounter <= OG_P2_y + 4'd15 + P2_Position))
            B_X_dir <= 1'b0;
        else if(OG_B_y + B_shapeCounter_D[3:2] + B_shapeCounter_E[3:2] + B_YposCounter == 8'd0)
            B_Y_dir <= 1'b1;
        else if(OG_B_y + B_shapeCounter_D[3:2] + B_shapeCounter_E[3:2] + B_YposCounter == 8'd116)
            B_Y_dir <= 1'b0;
    end
// ----------- END REGISTERS ----------- // 

    // Determine the Colour Output of the Ball and the Paddles
    always @(*)
		begin
			case (sel_col)
				2'd0: colour_out = data[9:7];
				2'b1: colour_out = 3'd0;
                2'd2: colour_out = data[3:0];
                2'd3: colour_out = 3'd0;
			endcase
		end
    // Determine the X Coordinate of the Ball and the Paddles
    always @(*)
        begin
            case (sel_out)
                2'd0: x_out = OG_B_x + B_shapeCounter_D[1:0] + B_shapeCounter_E[1:0] + B_XposCounter;
                2'd1: x_out = OG_P1_x + P1_shapeCounter_D[0] + P1_shapeCounter_E[0];
                2'd2: x_out = OG_P2_x + P2_shapeCounter_D[0] + P2_shapeCounter_E[0];
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