`timescale 1ns / 1ps

module tb_top();

    // ── Simulation Parameters ────────────────────────────────────────────────
    // Assuming a 50 MHz clock (20ns period)
    localparam CLK_PERIOD = 20;
    
    // UART Timing based on your top.v prescale (54)
    // Bit period = 54 * CLK_PERIOD = 1080 ns per bit
    localparam BIT_PERIOD = 432 * CLK_PERIOD;

    // ── Testbench Signals ────────────────────────────────────────────────────
    reg  clk;
    reg  rst_n;
    reg  rx_in;
	 reg button;
    reg led_data;
    wire tx_out;
    wire rs485_dir;
    wire [65:0] transducer;

    // ── Instantiate the Top Module ───────────────────────────────────────────
    top uut (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_in      (rx_in),
        .tx_out     (tx_out),
        .rs485_dir  (rs485_dir),
        .transducer (transducer),
		  .btn_n (button)
		  );

    // ── Clock Generator ──────────────────────────────────────────────────────
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // ── UART Bit-Banger Task ─────────────────────────────────────────────────
    task send_byte(input [7:0] data);
        integer i;
        begin
		  #15;
		  $display("[%0t] Starting send_byte(0x%h) with BIT_PERIOD=%d", $time, data, BIT_PERIOD);
            // 1. Send Start Bit (Low)
            rx_in = 1'b0;
            #(BIT_PERIOD);
            
            // 2. Send 8 Data Bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx_in = data[i];
                #(BIT_PERIOD);
            end
            
            // 3. Send Stop Bit (High)
            rx_in = 1'b1;
            #(BIT_PERIOD*2);
        end
    endtask

    // ── Main Test Sequence ───────────────────────────────────────────────────
    initial begin
        // 1. Initial State (Reset)
        rst_n = 0;
        rx_in = 1; // UART idle state is high
        #500;
        rst_n = 1;
		  button = 1;
        #1000;

        $display("--------------------------------------------------");
        $display("[%0t] Starting Simulation...", $time);

        // 2. Send First Target: X=0, Y=0, Z=100 (Dead Center, 10cm up)
        $display("[%0t] Sending Target 1: (0, 0, 100)", $time);
        
        send_byte(8'hAA); // Header
        send_byte(8'h00); // X High
        send_byte(8'h00); // X Low  (0)
        send_byte(8'h00); // Y High
        send_byte(8'h00); // Y Low  (0)
        send_byte(8'h00); // Z High
        send_byte(8'h00); // Z Low  (100 in hex is 0x64)

        // 3. Wait for the pipeline to do its math
        // The pipeline takes ~33 cycles + 13 pipeline latency + UART latency
        #(CLK_PERIOD * 200); 

        // 4. Let the 40kHz PWM generators run for a bit
        // A 40kHz wave takes 25us (25,000ns) to complete one cycle. 
        // Let's watch 3 full waves to ensure 50% duty cycle is stable.
        $display("[%0t] Watching PWM waves for 75us...", $time);
        #(75000); 

        // 5. Send Second Target: X=50, Y=0, Z=100 (Shifted to the side)
        $display("[%0t] Sending Target 2: (50, 0, 100)", $time);
        
        send_byte(8'hAA); // Header
        send_byte(8'h01); // X High
        send_byte(8'h40); // X Low  (50 in hex is 0x32)
        send_byte(8'h01); // Y High
        send_byte(8'h50); // Y Low  (0)
        send_byte(8'h02); // Z High
        send_byte(8'h80); // Z Low  (100)

        // 6. Let the new PWM waves run for another 3 cycles
        #(75000);


		  
		  button = 1'b0;
		  #(6000);
		  button = 1'b1;
		  #(1200000);
		  
		   button = 1'b0;
		  #(6000);
		  button = 1'b1;
		  #(1200000);
		  
		          $display("[%0t] Simulation Complete.", $time);
        $display("--------------------------------------------------");
        $finish; // Stop the simulator
    end

    // ── Pipeline Monitor (Optional, for easy debugging) ──────────────────────
    // This watches the internal signal to tell you exactly when the math finishes
    always @(posedge clk) begin
        if (uut.u_calc.phases_valid) begin
            $display("[%0t] >>> DSP PIPELINE FINISHED: Phase Array Updated! <<<", $time);
        end
    end

endmodule