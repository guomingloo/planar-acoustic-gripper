module ws2812_controller (
    input  wire       clk,      // 50 MHz
    input  wire       rst_n,    // Active-low reset (Button pressed = 0)
	 input 	wire mode,
	 input wire control_mode,
    output reg        led_data  // Data for WS2812
);

    // Time constants at 50MHz
    localparam T0H = 17;    // 0.34 us
    localparam T1H = 35;    // 0.70 us
    localparam TRESET = 3000; // 60 us

    localparam STATE_SEND   = 0;
    localparam STATE_RESET  = 1;

    reg state           = STATE_RESET; 
    reg [11:0] bit_counter    = 0;    
    reg [6:0]  pixel_counter  = 0;    
    reg [15:0] reset_counter  = 0;    
    
    // Color Generation
    reg [7:0] hue = 0;
    reg [19:0] speed_counter = 0; 
    reg [23:0] color_stream [0:3];
    reg [7:0] r, g, b;

    // 1. Color Wheel & Reset Override
    always @(posedge clk) begin
        if (!rst_n) begin
            speed_counter <= 0;
            hue <= 0;
        end else if (mode && control_mode) begin
				speed_counter <= 0;
            hue <= 85;
		  end else if (!mode && control_mode) begin
				speed_counter <= 0;
            hue <= 170;
		  end else begin
            speed_counter <= speed_counter + 1'b1;
            if (speed_counter == 20'd500_000) begin
                speed_counter <= 0;
                hue <= hue + 1'b1; 
            end
        end
    end

    // 2. Combinational Color Logic (with Reset Priority)
    always @(*) begin
        if (!rst_n) begin
            // Force Red when reset button is pressed
            r = 8'd255; g = 8'd0; b = 8'd0;
        end else begin
            if (hue < 8'd85) begin
                r = 8'd255 - (hue * 8'd3); g = hue * 8'd3; b = 8'd0;
            end else if (hue < 8'd170) begin
                r = 8'd0; g = 8'd255 - ((hue - 8'd85) * 8'd3); b = (hue - 8'd85) * 8'd3;
            end else begin
                r = (hue - 8'd170) * 8'd3; g = 8'd0; b = 8'd255 - ((hue - 8'd170) * 8'd3);
            end
        end

        color_stream[0] = {g, r, b};
        color_stream[1] = {g, r, b};
        color_stream[2] = {g, r, b};
        color_stream[3] = {g, r, b};
    end

    // 3. WS2812 Transmitter
    reg [23:0] current_pixel_data;
    
    always @(posedge clk) begin
        case (state)
            STATE_RESET: begin
                led_data <= 1'b0;
                if (reset_counter < TRESET) begin
                    reset_counter <= reset_counter + 1'b1;
                end else begin
                    reset_counter <= 0;
                    pixel_counter <= 0;
                    state         <= STATE_SEND;
                end
            end

            STATE_SEND: begin
                current_pixel_data <= color_stream[pixel_counter / 24];
                
                if (current_pixel_data[23 - (pixel_counter % 24)])
                    led_data <= (bit_counter < T1H) ? 1'b1 : 1'b0;
                else
                    led_data <= (bit_counter < T0H) ? 1'b1 : 1'b0;

                if (bit_counter < 62) begin
                    bit_counter <= bit_counter + 1'b1;
                end else begin
                    bit_counter <= 0;
                    if (pixel_counter < 95)
                        pixel_counter <= pixel_counter + 1'b1;
                    else begin
                        pixel_counter <= 0;
                        state         <= STATE_RESET;
                    end
                end
            end
            default: state <= STATE_RESET;
        endcase
    end
endmodule