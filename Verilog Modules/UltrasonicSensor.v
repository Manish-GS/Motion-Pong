module UltrasonicSensor(CLOCK_50, GPIO, sensor_1, sensor_2);
    input CLOCK_50;

    inout [35:0] GPIO;

    output [9:0] sensor_1, sensor_2;

    // wire newClock;

    // reg countDownFrom = 28'd50000000;

    // Countdown from 50,000,000 to get 1hz
    // always @(posedge CLOCK_50)
    // begin
    //     if(countDownFrom == 28'b0)
    //         countDownFrom <= 28'd50000000;
    //     else
    //         countDownFrom <= countDownFrom - 1'b1;
    // end

    // assign newClock = (countDownFrom == 28'b0) ? 1 : 0;

    wire [25:0] sensorDistance;
    wire [25:0] sensorDistance2;

    assign sensor_1 = sensorDistance;
    assign sensor_2 = sensorDistance2;

    usensor myPercolatingSensor(
        .distance(sensorDistance),
        .trig(GPIO[1]),
        .echo(GPIO[3]),
        .clock(CLOCK_50)
    );

    usensor myPercolatingSensorTWOO(
      .distance(sensorDistance2),
      .trig(GPIO[5]),
      .echo(GPIO[7]),
      .clock(CLOCK_50)
    );

endmodule


/**
*   THIS MODULE WAS WRITTEN BY A DIFFERENT TEAM, IN A PREVIOUS CSCB58 SECTION.
*   ORIGINAL SOURCE: https://github.com/mohammadmoustafa/CSCB58-Winter-2018-Project 
*/
module usensor(distance, trig, echo, clock);
  input clock, echo;
  output reg [25:0] distance;
  output reg trig;

  reg [25:0] master_timer;
  reg [25:0] trig_timer;
  reg [25:0] echo_timer;
  reg [25:0] echo_shift10;
  reg [25:0] echo_shift12;
  reg [25:0] temp_distance;
  reg echo_sense, echo_high;

  localparam  TRIG_THRESHOLD = 14'b10011100010000,
              MASTER_THRESHOLD = 26'b10111110101111000010000000;


  always @(posedge clock)
  begin
    if (master_timer == MASTER_THRESHOLD)
		begin
        master_timer <= 0;
		  
		  end
    else if (trig_timer == TRIG_THRESHOLD || echo_sense)
      begin
        trig <= 0;
        echo_sense <= 1;
        if (echo)
			   			    begin
					echo_high <= 1;
					echo_timer <= echo_timer + 1;
					//////////////////////////////////////////////////////
					// CLOCK_50 -> 50 000 000 clock cycles per second
					// let n = number of cycles
					// speed of sound in air: 340m/s
					// n / 50 000 000 = num of seconds
					// num of seconds * 340m/s = meters
					// meters * 100 = cm ~ distance to object and back
					// So we divide by 2 to get distance to object
					// 1/ 50 000 000 * 340 * 100 / 2 = 0.00034
					// n * 0.00034 = n * 34/100 000 = n / (100 000/34)
					// = 2941
					// To make up for sensor inaccuracy and simple math
					// we round down to 2900
					temp_distance <= (echo_timer / 2900);
					//////////////////////////////////////////////////////
			    end
        else
          begin
				distance <= temp_distance + 2'd2;
				echo_timer <= 0;
				trig_timer <= 0;
				echo_sense <= 0;
          end
      end
    else
	   begin
      trig <= 1;
      trig_timer <= trig_timer + 1;
      master_timer <= master_timer + 1;
    end
  end
endmodule