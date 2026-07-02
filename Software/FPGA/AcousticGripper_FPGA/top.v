`include "transducer_coords.vh"

module top (
    input  wire        clk,
    input  wire        rst_n,
	 input  wire 		  btn_n,
    input  wire        rx_in,
    output wire        tx_out,
	 output wire		  led,
    output wire        rs485_dir,
    output wire [65:0] transducer
);

		// ── UART Instantiation ───────────────────────────────────────────────────
		wire [15:0] uart_prescale = 16'd54;
		wire        uart_rst_high = ~rst_n;

		wire [7:0]  m_axis_tdata;
		wire        m_axis_tvalid;
		wire        m_axis_tready = 1'b1;
		wire [7:0]  s_axis_tdata  = 8'h4B; // ACK byte
		wire        s_axis_tvalid;
		wire        s_axis_tready;
		wire        tx_busy;
		

		
		
		 // --- Control Logic Declarations ---
		reg  control_mode  = 1'b0; // 0: UART, 1: Button
		reg  mode_preset   = 1'b0; // 0: Preset A, 1: Preset B
		reg  [19:0] debounce_cnt;
		reg  btn_synced, btn_stable, btn_stable_prev;
		reg control_mode_d;
		reg pulse;
		reg [18:0] delay_counter;
		reg        tx_trigger;
		reg [21:0] test_timer;
		reg rs485_dir_reg;
		reg tx_seen_busy;

		// --- Presets ---
		localparam X_A	 = 12'd0; localparam Y_A = 12'd343; localparam Z_A = 12'd0;
		localparam X_B = 12'd0; localparam Y_B = 12'd343; localparam Z_B = 12'd0;
	
	 assign s_axis_tvalid = tx_trigger;
	 assign rs485_dir = rs485_dir_reg;

    uart #(.DATA_WIDTH(8)) u_uart (
        .clk             (clk),
        .rst             (uart_rst_high),
        .s_axis_tdata    (s_axis_tdata),
        .s_axis_tvalid   (s_axis_tvalid),
        .s_axis_tready   (s_axis_tready),
        .m_axis_tdata    (m_axis_tdata),
        .m_axis_tvalid   (m_axis_tvalid),
        .m_axis_tready   (m_axis_tready),
        .rxd             (rx_in),
        .txd             (tx_out),
        .tx_busy         (tx_busy),
        .rx_busy         (),
        .rx_overrun_error(),
        .rx_frame_error  (),
        .prescale        (uart_prescale)
    );
	 
		ws2812_controller led_inst (
			 .clk      (clk),
			 .rst_n    (rst_n),
			 .led_data (led),
			 .control_mode (control_mode),
			 .mode (mode_preset)
		);
    // ── Target Receive Machine (12-bit Q8.4)
    reg signed [11:0] target_x_reg, target_y_reg, target_z_reg;
	 reg [7:0] enable;
    reg [3:0] byte_count;
    reg       send_ack;

   always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            target_x_reg <= 12'd0;
            target_y_reg <= 12'd0;
            target_z_reg <= 12'd0;
				enable <= 8'd0;
            byte_count   <= 4'd0;
            send_ack     <= 1'b0;
				delay_counter    <= 13'd0;
				tx_trigger   <= 1'b0;
				tx_seen_busy  <= 1'b0;
        end else begin
            
				if (tx_trigger) begin
                rs485_dir_reg <= 1'b1;
                tx_seen_busy  <= 1'b0;
            end else if (tx_busy) begin
                tx_seen_busy <= 1'b1;
            end else if (tx_seen_busy) begin
                rs485_dir_reg <= 1'b0;
                tx_seen_busy  <= 1'b0;
            end
				
            if (m_axis_tvalid && m_axis_tready) begin
                if (m_axis_tdata == 8'hAA && byte_count == 4'd0) begin
                    byte_count <= 4'd1; 
                end else if (byte_count > 4'd0) begin
                    byte_count <= byte_count + 1'b1;
                    case (byte_count)
                        4'd1: target_x_reg[11:8] <= m_axis_tdata[3:0];
                        4'd2: target_x_reg[7:0]  <= m_axis_tdata;
                        4'd3: target_y_reg[11:8] <= m_axis_tdata[3:0];
                        4'd4: target_y_reg[7:0]  <= m_axis_tdata;
                        4'd5: target_z_reg[11:8] <= m_axis_tdata[3:0];
                        4'd6: target_z_reg[7:0] <= m_axis_tdata;
								4'd7: begin
									 enable[7:0] <= m_axis_tdata;
									 byte_count        <= 4'd0;
                            send_ack          <= 1'b1;
                        end
                        default: byte_count <= 4'd0;
                    endcase
                end
            end
             if (send_ack) begin
					 if (delay_counter < 18'd200000) begin
						  // Stalling for to let the Pi switch to RX mode
						  delay_counter <= delay_counter + 1'b1;
					 end else if (!tx_trigger) begin
                      tx_trigger    <= 1'b1;         
                      send_ack      <= 1'b0;         
                      delay_counter <= 13'd0;
                 end
				end
				
            if (s_axis_tready && s_axis_tvalid) 
                tx_trigger <= 1'b0;
        end
    end

    // Target Valid Pulse 
    reg send_ack_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) send_ack_prev <= 1'b0;
        else        send_ack_prev <= send_ack;
    end
    wire target_valid = send_ack && !send_ack_prev;

    //Master PWM Counter (0 to 1249)
    reg [10:0] master_counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            master_counter <= 11'd0;
        else if (master_counter == 11'd1249)
            master_counter <= 11'd0;
        else
            master_counter <= master_counter + 1'b1;
    end

    // ── Phase Array Logic 
   wire [11:0] final_x = control_mode ? (mode_preset ? X_B : X_A) : target_x_reg;
	wire [11:0] final_y = control_mode ? (mode_preset ? Y_B : Y_A) : target_y_reg;
	wire [11:0] final_z = control_mode ? (mode_preset ? Z_B : Z_A) : target_z_reg;
	 
	 wire [725:0] phase_flat;
	 wire update_trigger = (target_valid || (btn_stable_prev && !btn_stable));
	 
	 
    
		calc_phase u_calc (
			 .clk          (clk),
			 .rst_n        (rst_n),
			 .target_x     (final_x),
			 .target_y     (final_y),
			 .target_z     (final_z),
			 .target_valid (target_valid || (pulse)), // Trigger update when mode flips
			 .phase_flat   (phase_flat),
			 .phases_valid ()
		);
    // 66 PWM Generators
    genvar ch;
    generate
        for (ch = 0; ch < 66; ch = ch + 1) begin : pwm_gen
            pwm_channel pwm_inst (
                .clk            (clk),
                .rst_n          (rst_n),
                .master_counter (master_counter),
                .phase          (phase_flat[ch*11 +: 11]),
                .pwm_out        (transducer[ch]),
					 .enable			  (|enable)
            );
				
				
				
        end
    endgenerate
	 
//probe 12 bit for ISSP;
IP_Block frame_err (.probe(rx_frame_error));
IP_Block overrun_err (.probe(rx_overrun_error));
IP_Block byte_num  (.probe(s_axis_tdata));
IP_Block valid_num  (.probe(s_axis_tvalid));   
IP_Block x_target  (.probe(final_x[10:0]));    
IP_Block y_target  (.probe(final_y[10:0]));    
IP_Block z_targer  (.probe(final_z[10:0]));    
IP_Block RX_target  (.probe(rx_in));    
IP_Block TX_target  (.probe(tx_out));
IP_Block dir  (.probe(rs485_dir)); 
	 
	always @(posedge clk) begin
		 btn_synced = btn_n; 
		 btn_stable = btn_synced;
		 btn_stable_prev <= btn_stable;
		 if (btn_stable_prev && !btn_stable) begin
			  if (!control_mode) control_mode <= 1'b1;      // Enter Button Mode
			  else if (control_mode) mode_preset <= ~mode_preset;  
			  else control_mode <= 1'b0;                    // Exit to UART Mode
		 end
	end
	
	always @(posedge clk) begin
    // Store the previous value
    control_mode_d <= control_mode;
    
    // Pulse high for one cycle when control_mode changes
    if (control_mode != control_mode_d) begin
        pulse <= 1'b1;
    end else begin
        pulse <= 1'b0;
    end
end

endmodule