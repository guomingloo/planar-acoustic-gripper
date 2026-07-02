`include "transducer_coords.vh"

`timescale 1ns / 1ps

module calc_phase(
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [11:0] target_x,
    input  wire signed [11:0] target_y,
    input  wire signed [11:0] target_z,
    input  wire         target_valid,
    output wire [725:0] phase_flat,
    output reg          phases_valid
);

    localparam N_CH        = 66;
    localparam CH_PER_PIPE = 33;   
    localparam PIPE_LAT    = 12;   // 12 Cycles total latency from input to write
    localparam PHASE_SCALE = 16'h91c6;

    // ── Channel Position Table ────────────────────────────────────────────────
    wire signed [11:0] CH_X [0:N_CH-1];
    wire signed [11:0] CH_Y [0:N_CH-1];
    wire signed [11:0] CH_Z [0:N_CH-1];

	assign CH_X[0]  = `CH0_0_X;  assign CH_Y[0]  = `CH0_0_Y;  assign CH_Z[0]  = `CH0_0_Z;
    assign CH_X[1]  = `CH0_1_X;  assign CH_Y[1]  = `CH0_1_Y;  assign CH_Z[1]  = `CH0_1_Z;
    assign CH_X[2]  = `CH0_2_X;  assign CH_Y[2]  = `CH0_2_Y;  assign CH_Z[2]  = `CH0_2_Z;
    assign CH_X[3]  = `CH0_3_X;  assign CH_Y[3]  = `CH0_3_Y;  assign CH_Z[3]  = `CH0_3_Z;
    assign CH_X[4]  = `CH0_4_X;  assign CH_Y[4]  = `CH0_4_Y;  assign CH_Z[4]  = `CH0_4_Z;
    assign CH_X[5]  = `CH0_5_X;  assign CH_Y[5]  = `CH0_5_Y;  assign CH_Z[5]  = `CH0_5_Z;
    assign CH_X[6]  = `CH0_6_X;  assign CH_Y[6]  = `CH0_6_Y;  assign CH_Z[6]  = `CH0_6_Z;
    assign CH_X[7]  = `CH0_7_X;  assign CH_Y[7]  = `CH0_7_Y;  assign CH_Z[7]  = `CH0_7_Z;
    assign CH_X[8]  = `CH0_8_X;  assign CH_Y[8]  = `CH0_8_Y;  assign CH_Z[8]  = `CH0_8_Z;
    assign CH_X[9]  = `CH0_9_X;  assign CH_Y[9]  = `CH0_9_Y;  assign CH_Z[9]  = `CH0_9_Z;
    assign CH_X[10] = `CH0_10_X; assign CH_Y[10] = `CH0_10_Y; assign CH_Z[10] = `CH0_10_Z;
    assign CH_X[11] = `CH0_11_X; assign CH_Y[11] = `CH0_11_Y; assign CH_Z[11] = `CH0_11_Z;
    assign CH_X[12] = `CH0_12_X; assign CH_Y[12] = `CH0_12_Y; assign CH_Z[12] = `CH0_12_Z;
    assign CH_X[13] = `CH0_13_X; assign CH_Y[13] = `CH0_13_Y; assign CH_Z[13] = `CH0_13_Z;
    assign CH_X[14] = `CH0_14_X; assign CH_Y[14] = `CH0_14_Y; assign CH_Z[14] = `CH0_14_Z;
    assign CH_X[15] = `CH0_15_X; assign CH_Y[15] = `CH0_15_Y; assign CH_Z[15] = `CH0_15_Z;
    assign CH_X[16] = `CH0_16_X; assign CH_Y[16] = `CH0_16_Y; assign CH_Z[16] = `CH0_16_Z;
    assign CH_X[17] = `CH0_17_X; assign CH_Y[17] = `CH0_17_Y; assign CH_Z[17] = `CH0_17_Z;
    assign CH_X[18] = `CH0_18_X; assign CH_Y[18] = `CH0_18_Y; assign CH_Z[18] = `CH0_18_Z;
    assign CH_X[19] = `CH0_19_X; assign CH_Y[19] = `CH0_19_Y; assign CH_Z[19] = `CH0_19_Z;
    assign CH_X[20] = `CH0_20_X; assign CH_Y[20] = `CH0_20_Y; assign CH_Z[20] = `CH0_20_Z;
    assign CH_X[21] = `CH0_21_X; assign CH_Y[21] = `CH0_21_Y; assign CH_Z[21] = `CH0_21_Z;
    assign CH_X[22] = `CH0_22_X; assign CH_Y[22] = `CH0_22_Y; assign CH_Z[22] = `CH0_22_Z;
    assign CH_X[23] = `CH0_23_X; assign CH_Y[23] = `CH0_23_Y; assign CH_Z[23] = `CH0_23_Z;
    assign CH_X[24] = `CH0_24_X; assign CH_Y[24] = `CH0_24_Y; assign CH_Z[24] = `CH0_24_Z;
    assign CH_X[25] = `CH0_25_X; assign CH_Y[25] = `CH0_25_Y; assign CH_Z[25] = `CH0_25_Z;
    assign CH_X[26] = `CH0_26_X; assign CH_Y[26] = `CH0_26_Y; assign CH_Z[26] = `CH0_26_Z;
    assign CH_X[27] = `CH0_27_X; assign CH_Y[27] = `CH0_27_Y; assign CH_Z[27] = `CH0_27_Z;
    assign CH_X[28] = `CH0_28_X; assign CH_Y[28] = `CH0_28_Y; assign CH_Z[28] = `CH0_28_Z;
    assign CH_X[29] = `CH0_29_X; assign CH_Y[29] = `CH0_29_Y; assign CH_Z[29] = `CH0_29_Z;
    assign CH_X[30] = `CH0_30_X; assign CH_Y[30] = `CH0_30_Y; assign CH_Z[30] = `CH0_30_Z;
    assign CH_X[31] = `CH0_31_X; assign CH_Y[31] = `CH0_31_Y; assign CH_Z[31] = `CH0_31_Z;
    assign CH_X[32] = `CH0_32_X; assign CH_Y[32] = `CH0_32_Y; assign CH_Z[32] = `CH0_32_Z;
    assign CH_X[33] = `CH1_0_X;  assign CH_Y[33] = `CH1_0_Y;  assign CH_Z[33] = `CH1_0_Z;
    assign CH_X[34] = `CH1_1_X;  assign CH_Y[34] = `CH1_1_Y;  assign CH_Z[34] = `CH1_1_Z;
    assign CH_X[35] = `CH1_2_X;  assign CH_Y[35] = `CH1_2_Y;  assign CH_Z[35] = `CH1_2_Z;
    assign CH_X[36] = `CH1_3_X;  assign CH_Y[36] = `CH1_3_Y;  assign CH_Z[36] = `CH1_3_Z;
    assign CH_X[37] = `CH1_4_X;  assign CH_Y[37] = `CH1_4_Y;  assign CH_Z[37] = `CH1_4_Z;
    assign CH_X[38] = `CH1_5_X;  assign CH_Y[38] = `CH1_5_Y;  assign CH_Z[38] = `CH1_5_Z;
    assign CH_X[39] = `CH1_6_X;  assign CH_Y[39] = `CH1_6_Y;  assign CH_Z[39] = `CH1_6_Z;
    assign CH_X[40] = `CH1_7_X;  assign CH_Y[40] = `CH1_7_Y;  assign CH_Z[40] = `CH1_7_Z;
    assign CH_X[41] = `CH1_8_X;  assign CH_Y[41] = `CH1_8_Y;  assign CH_Z[41] = `CH1_8_Z;
    assign CH_X[42] = `CH1_9_X;  assign CH_Y[42] = `CH1_9_Y;  assign CH_Z[42] = `CH1_9_Z;
    assign CH_X[43] = `CH1_10_X; assign CH_Y[43] = `CH1_10_Y; assign CH_Z[43] = `CH1_10_Z;
    assign CH_X[44] = `CH1_11_X; assign CH_Y[44] = `CH1_11_Y; assign CH_Z[44] = `CH1_11_Z;
    assign CH_X[45] = `CH1_12_X; assign CH_Y[45] = `CH1_12_Y; assign CH_Z[45] = `CH1_12_Z;
    assign CH_X[46] = `CH1_13_X; assign CH_Y[46] = `CH1_13_Y; assign CH_Z[46] = `CH1_13_Z;
    assign CH_X[47] = `CH1_14_X; assign CH_Y[47] = `CH1_14_Y; assign CH_Z[47] = `CH1_14_Z;
    assign CH_X[48] = `CH1_15_X; assign CH_Y[48] = `CH1_15_Y; assign CH_Z[48] = `CH1_15_Z;
    assign CH_X[49] = `CH1_16_X; assign CH_Y[49] = `CH1_16_Y; assign CH_Z[49] = `CH1_16_Z;
    assign CH_X[50] = `CH1_17_X; assign CH_Y[50] = `CH1_17_Y; assign CH_Z[50] = `CH1_17_Z;
    assign CH_X[51] = `CH1_18_X; assign CH_Y[51] = `CH1_18_Y; assign CH_Z[51] = `CH1_18_Z;
    assign CH_X[52] = `CH1_19_X; assign CH_Y[52] = `CH1_19_Y; assign CH_Z[52] = `CH1_19_Z;
    assign CH_X[53] = `CH1_20_X; assign CH_Y[53] = `CH1_20_Y; assign CH_Z[53] = `CH1_20_Z;
    assign CH_X[54] = `CH1_21_X; assign CH_Y[54] = `CH1_21_Y; assign CH_Z[54] = `CH1_21_Z;
    assign CH_X[55] = `CH1_22_X; assign CH_Y[55] = `CH1_22_Y; assign CH_Z[55] = `CH1_22_Z;
    assign CH_X[56] = `CH1_23_X; assign CH_Y[56] = `CH1_23_Y; assign CH_Z[56] = `CH1_23_Z;
    assign CH_X[57] = `CH1_24_X; assign CH_Y[57] = `CH1_24_Y; assign CH_Z[57] = `CH1_24_Z;
    assign CH_X[58] = `CH1_25_X; assign CH_Y[58] = `CH1_25_Y; assign CH_Z[58] = `CH1_25_Z;
    assign CH_X[59] = `CH1_26_X; assign CH_Y[59] = `CH1_26_Y; assign CH_Z[59] = `CH1_26_Z;
    assign CH_X[60] = `CH1_27_X; assign CH_Y[60] = `CH1_27_Y; assign CH_Z[60] = `CH1_27_Z;
    assign CH_X[61] = `CH1_28_X; assign CH_Y[61] = `CH1_28_Y; assign CH_Z[61] = `CH1_28_Z;
    assign CH_X[62] = `CH1_29_X; assign CH_Y[62] = `CH1_29_Y; assign CH_Z[62] = `CH1_29_Z;
    assign CH_X[63] = `CH1_30_X; assign CH_Y[63] = `CH1_30_Y; assign CH_Z[63] = `CH1_30_Z;
    assign CH_X[64] = `CH1_31_X; assign CH_Y[64] = `CH1_31_Y; assign CH_Z[64] = `CH1_31_Z;
    assign CH_X[65] = `CH1_32_X; assign CH_Y[65] = `CH1_32_Y; assign CH_Z[65] = `CH1_32_Z;
    
	 // ── Shared M9K ROM
    (* ramstyle = "M9K" *) reg [10:0] mod_rom [0:16383];
    initial $readmemh("mod1250.hex", mod_rom);

    reg  [10:0] rom_q [0:1];        // Synchronous read data
    wire [13:0] rom_addr_wire [0:1]; // Address from each pipeline

    // Synchronous read block
    always @(posedge clk) begin
        rom_q[0] <= mod_rom[rom_addr_wire[0]];
        rom_q[1] <= mod_rom[rom_addr_wire[1]];
    end

    // ── DSP Pipelines
    genvar p;
    generate
    for (p = 0; p < 2; p = p + 1) begin : pipe

        reg [5:0]  ch_idx;  
        reg        running;
        
        reg [PIPE_LAT:1] pipe_valid;                 
        reg [5:0]        pipe_idx [1:PIPE_LAT];    
        
        reg signed [12:0] dx, dy, dz;
        reg        [25:0] dx_sq, dy_sq, dz_sq;
        reg        [27:0] sum_sq;
        reg        [27:0] intermediate_mult;
        reg        [13:0] rom_addr_reg;
        
        reg [CH_PER_PIPE*11-1:0] pipe_phase;
        wire [13:0] sqrt_out;

        // ALTSQRT MegaFunction
        altsqrt_28i_6c sqrt_inst (
            .clk      (clk),
            .radical  (sum_sq),
            .q        (sqrt_out),
            .remainder()
        );

        wire [6:0] abs_ch = (p * CH_PER_PIPE) + ch_idx;
        assign rom_addr_wire[p] = rom_addr_reg;

        integer s;
		  
		  reg [5:0] write_idx;
		  
        always @(posedge clk) begin
            if (!rst_n) begin
                ch_idx       <= 6'd0;
                running      <= 1'b0;
                pipe_valid   <= 13'b0;
                dx           <= 13'b0; dy <= 13'b0; dz <= 13'b0;
                dx_sq        <= 26'b0; dy_sq <= 26'b0; dz_sq <= 26'b0;
                sum_sq       <= 28'b0;
                intermediate_mult <= 28'b0;
                rom_addr_reg <= 12'b0;
                pipe_phase   <= 0;
                for (s = 1; s <=	 PIPE_LAT; s = s + 1) pipe_idx[s] <= 6'b0;
            end else begin
				
                // Trigger logic
                if (target_valid) begin
                    ch_idx  <= 6'd0;
                    running <= 1'b1;
                end
					 
					 if (running) begin
							pipe_idx[1]   <= ch_idx; 
							pipe_valid[1] <= 1'b1;
					  end else begin
							pipe_valid[1] <= 1'b0;
					  end

                // ── Stage 0 (Input generator) ──
                if (running) begin
                    if (ch_idx == CH_PER_PIPE - 1)
                        running <= 1'b0;
								
                    else
                        ch_idx <= ch_idx + 6'd1;
                end

                // ── stage 1: delta using COMBINATIONAL abs_ch (current ch_idx)
                if (running || target_valid) begin
                    dx <= target_x - CH_X[abs_ch];
                    dy <= target_y - CH_Y[abs_ch];
                    dz <= target_z - CH_Z[abs_ch];
                end
					 
                for (s = 2; s <= PIPE_LAT; s = s + 1) begin
                    pipe_idx[s]   <= pipe_idx[s-1];
                    pipe_valid[s] <= pipe_valid[s-1];
                end

                // ── Stage 2: Square ──
                dx_sq <= dx * dx;
                dy_sq <= dy * dy;
                dz_sq <= dz * dz;

                // ── Stage 3: Sum ──
                sum_sq <= dx_sq + dy_sq + dz_sq;

                // ── Stages 4-9: ALTSQRT (Handled by module) ──

                // ── Stage 10: Scale ──
                intermediate_mult <= sqrt_out * PHASE_SCALE;

                // ── Stage 11: Register ROM Address ──
                rom_addr_reg <= intermediate_mult >> 12;

                // ── Stage 12: Synchronous ROM Read (Handled globally above) ──
                
                // ── Stage 13: Write to Phase Array ──
					 write_idx <= pipe_idx[PIPE_LAT];
                if (pipe_valid[PIPE_LAT]) begin
						if (pipe_idx[PIPE_LAT] == 6'd0)
							  pipe_phase[10:0] <= rom_q[p];
						 else if (pipe_idx[PIPE_LAT] == 6'd1)
							  pipe_phase[21:11] <= rom_q[p];
						 else
							  pipe_phase[pipe_idx[PIPE_LAT] * 11 +: 11] <= rom_q[p];
                end
            end
        end
    end
    endgenerate

    // Flatten both pipes to output
    assign phase_flat = {pipe[1].pipe_phase, pipe[0].pipe_phase};

    // Global Valid pulse
    always @(posedge clk or negedge rst_n) begin
         if (!rst_n) phases_valid <= 1'b0;
         else        phases_valid <= pipe[1].pipe_valid[PIPE_LAT] && 
                                     (pipe[1].pipe_idx[PIPE_LAT] == CH_PER_PIPE - 1);
    end

endmodule