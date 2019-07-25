module Control( clock,
                resetn,
                go,

                fin_B_D,
                fin_B_E,

                ld_bx_out,
                ld_by_out,

                en_B_shapeCounter_D,
                en_B_shapeCounter_E,

                fin_P1_D,
                fin_P1_E,

                ld_p1x_out,
                ld_p1y_out,

                en_P1_shapeCounter_D,
                en_P1_shapeCounter_E,
                
                fin_P2_D,
                fin_P2_E,

                ld_p2x_out,
                ld_p2y_out,

                en_P2_shapeCounter_D,
                en_P2_shapeCounter_E,

                fin_Wait,
                en_delayCounter,

                plot,
                sel_out,
                sel_col
    );
    // absolute input signals
    input clock, resetn, go;

    // dynamic input singnals
    input fin_B_D, fin_B_E;
    input fin_P1_D, fin_P1_E;
    input fin_P2_D, fin_P2_E;
    input fin_Wait;

    // ouput signals
    output reg plot, ld_bx_out, ld_by_out;
    output reg en_B_shapeCounter_D, en_B_shapeCounter_E;

    output reg ld_p1x_out, ld_p1y_out;
    output reg en_P1_shapeCounter_D, en_P1_shapeCounter_E;

    output reg ld_p2x_out, ld_p2y_out;
    output reg en_P2_shapeCounter_D, en_P2_shapeCounter_E;

    output reg en_delayCounter;

    output reg [1:0] sel_col;
    output reg [1:0] sel_out;

    //output [6:0] HEX0, HEX2;

    // declare registers for the FSM
    reg [5:0] current_state, next_state;

    // Hex_display hd1(
    //     .IN(current_state[3:0]),
    //     .OUT(HEX0)
    // );

    // Hex_display hd2(
    //     .IN(next_state[3:0]),
    //     .OUT(HEX2)
    // );

    // assign the states a value
    localparam  S_INIT = 5'd0,
                S_LOAD_WAIT = 5'd1,
				S_LOAD = 5'd2,
                S_PLOT_WAIT = 5'd3,
                S_PLOT = 5'd4,
                S_WAIT_WAIT = 5'd5,
                S_WAIT = 5'd6,
                S_DELETE_WAIT = 5'd7,
                S_DELETE = 5'd8,
                S_DONE = 5'd9,

                S_PLOT_WAIT_PADDLE1 = 5'd10,
                S_PLOT_PADDLE1 = 5'd11,
                S_DELETE_WAIT_PADDLE1 = 5'd12,
                S_DELETE_PADDLE1 = 5'd13,

                S_PLOT_WAIT_PADDLE2 = 5'd14,
                S_PLOT_PADDLE2 = 5'd15,
                S_DELETE_WAIT_PADDLE2 = 5'd16,
                S_DELETE_PADDLE2 = 5'd17;

    // state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_INIT: next_state = go ? S_LOAD_WAIT : S_INIT;
                S_LOAD_WAIT: next_state = S_LOAD;
                S_LOAD: next_state = S_PLOT_WAIT_PADDLE1;
                
                S_PLOT_WAIT_PADDLE1: next_state = S_PLOT_PADDLE1;
                S_PLOT_PADDLE1: next_state = fin_P1_D ? S_PLOT_WAIT : S_PLOT_PADDLE1;

                S_PLOT_WAIT: next_state = S_PLOT;
                S_PLOT: next_state = fin_B_D ? S_PLOT_WAIT_PADDLE2 : S_PLOT;

                S_PLOT_WAIT_PADDLE2: next_state = S_PLOT_PADDLE2;
                S_PLOT_PADDLE2: next_state = fin_P2_D ? S_WAIT_WAIT : S_PLOT_PADDLE2;

                S_WAIT_WAIT: next_state = S_WAIT;
                S_WAIT: next_state = fin_Wait ? S_DELETE_WAIT_PADDLE1: S_WAIT;

                S_DELETE_WAIT_PADDLE1: next_state = S_DELETE_PADDLE1;
                S_DELETE_PADDLE1: next_state = fin_P1_E ? S_DELETE_WAIT : S_DELETE_PADDLE1;

                S_DELETE_WAIT: next_state = S_DELETE;
                S_DELETE: next_state = fin_B_E ? S_DELETE_WAIT_PADDLE2 : S_DELETE;

                S_DELETE_WAIT_PADDLE2: next_state = S_DELETE_PADDLE2;
                S_DELETE_PADDLE2: next_state = fin_P2_E ? S_DONE : S_DELETE_PADDLE2;

                S_DONE: next_state = go ? S_PLOT_WAIT_PADDLE1 : S_INIT;

            default: next_state = S_INIT;
        endcase
    end // state_table

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals		
        // give instructions based on the current state
		case(current_state)
			S_INIT: begin
				plot = 1'b0;

                sel_out = 2'd0;
                sel_col = 2'd0;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0;  
                
			end
			S_LOAD_WAIT: begin
				plot = 1'b0;

                sel_out = 2'd0;
                sel_col = 2'd0;

                ld_bx_out = 1'b1;
                ld_by_out = 1'b1;

                ld_p1x_out = 1'b1;
                ld_p1y_out = 1'b1;

                ld_p2x_out = 1'b1;
                ld_p2y_out = 1'b1;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 
            end
            S_LOAD: begin
                plot = 1'b0;

                sel_out = 2'd0;
                sel_col = 2'd0;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 
            end
            S_PLOT_WAIT: begin
                plot = 1'b1;

                sel_out = 2'd0;
                sel_col = 2'd0;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b1;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 
            end
            S_PLOT: begin
                plot = 1'b1;

                sel_out = 2'd0;
                sel_col = 2'd0;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b1;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 
            end
            S_WAIT_WAIT: begin
                plot = 1'b0;

                sel_out = 2'd0;
                sel_col = 2'd0;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b1;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 

            end
            S_WAIT: begin
                plot = 1'b0;

                sel_out = 2'd0;
                sel_col = 2'd0;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b1;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 

            end
            S_DELETE_WAIT: begin
                plot = 1'b1;

                sel_out = 2'd0;
                sel_col = 2'd1;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b1;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 

            end
            S_DELETE: begin
                plot = 1'b1;

                sel_out = 2'd0;
                sel_col = 2'd1;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b1;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 

            end
            S_PLOT_WAIT_PADDLE1: begin
                plot = 1'b1;

                sel_out = 2'd1;
                sel_col = 2'd2;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b1;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 
            end
            S_PLOT_PADDLE1: begin
                plot = 1'b1;

                sel_out = 2'd1;
                sel_col = 2'd2;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b1;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 
            end
            S_DELETE_WAIT_PADDLE1: begin
                plot = 1'b1;

                sel_out = 2'd1;
                sel_col = 2'd3;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b1;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 

            end
            S_DELETE_PADDLE1: begin
                plot = 1'b1;

                sel_out = 2'd1;
                sel_col = 2'd3;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b1;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 
            end

            S_PLOT_WAIT_PADDLE2: begin
                plot = 1'b1;

                sel_out = 2'd2;
                sel_col = 2'd2;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b1;
                en_P2_shapeCounter_E = 1'b0; 
            end
            S_PLOT_PADDLE2: begin
                plot = 1'b1;

                sel_out = 2'd2;
                sel_col = 2'd2;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b1;
                en_P2_shapeCounter_E = 1'b0; 
            end
            S_DELETE_WAIT_PADDLE2: begin
                plot = 1'b1;

                sel_out = 2'd2;
                sel_col = 2'd3;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b1; 

            end
            S_DELETE_PADDLE2: begin
                plot = 1'b1;

                sel_out = 2'd2;
                sel_col = 2'd3;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b1;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b1; 
            end

            S_DONE: begin
                plot = 1'b0;

                sel_out = 2'd0;
                sel_col = 2'd0;

                ld_bx_out = 1'b0;
                ld_by_out = 1'b0;

                ld_p1x_out = 1'b0;
                ld_p1y_out = 1'b0;

                ld_p2x_out = 1'b0;
                ld_p2y_out = 1'b0;

                en_delayCounter = 1'b0;

				en_B_shapeCounter_D = 1'b0;
                en_B_shapeCounter_E = 1'b0;

                en_P1_shapeCounter_D = 1'b0;
                en_P1_shapeCounter_E = 1'b0;

                en_P2_shapeCounter_D = 1'b0;
                en_P2_shapeCounter_E = 1'b0; 

            end
            // default: // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase //output logic
    end

    // current_state registers
    always @(posedge clock)
        begin: state_FFs
            if(!resetn)
                current_state <= S_INIT;
            else
                current_state <= next_state;
        end // state_FFS

endmodule // control