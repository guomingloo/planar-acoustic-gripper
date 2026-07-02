`timescale 1ns / 1ps

module pwm_channel(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [10:0] master_counter,
    input  wire [10:0] phase,
	 input wire enable,
    output reg         pwm_out
);

    wire [11:0] sum = phase + 11'd625;
    wire [10:0] off_tick = (sum >= 12'd1250) ? (sum - 12'd1250) : sum[10:0];

    always @(posedge clk or negedge rst_n) begin
		  if (!rst_n) begin
            // 1. Reset is ALWAYS checked first, unconditionally
            pwm_out <= 1'b0;
        end 
        else if (!enable) begin
            // 2. If disabled, force the output low safely
            pwm_out <= 1'b0;
        end 
        else begin
            // 3. Normal PWM operation only occurs if rst_n is high AND enable is high
            if (master_counter == phase)
                pwm_out <= 1'b1;
            else if (master_counter == off_tick)
                pwm_out <= 1'b0;
        end
    end

endmodule