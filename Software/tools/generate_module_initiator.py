import os

WIDTH = 5
LENGTH = 7
SIDE = 2
N = 33

output_filename = ".\module_initiator.txt"

print(f"Generating {output_filename}...")

with open(output_filename, "w") as f:
    for j in range(SIDE):
        # Reset the sequential channel counter for each side (or move outside the 'j' loop 
        # if you want channel numbers to go from 0 all the way to 65 continuously)
        channel_num = 0 
        
        for i in range(WIDTH * LENGTH):
            # Skip the specific physical layout positions (6 and 34)
            if i == (LENGTH - 1) or i == (LENGTH * WIDTH - 1):
                continue
                
            # Write out the Verilog instantiation using the clean sequential channel_num
            f.write(f"""    // --- CHANNEL{j}_{channel_num} ---
    calc_phase #(.X_POS(`CH{j}_{channel_num}_X), .Y_POS(`CH{j}_{channel_num}_Y), .Z_POS(`CH{j}_{channel_num}_Z)) calc_unit_ch{j}_{channel_num} (
        .clk(clk), .rst_n(rst_n),
        .target_x(target_x), .target_y(target_y), .target_z(target_z),
        .phase(phase[{channel_num+j*N}])
    );
    pwm_channel pwm_unit_ch{j}_{channel_num} (
        .clk(clk), .rst_n(rst_n),
        .master_counter(master_counter), .phase(phase[{channel_num+j*N}]), .pwm_out(pwm[{channel_num+j*N}])
    );\n\n""")
            
            # Only increment our naming counter when a block is successfully written!
            channel_num += 1

print("Done!")
     
            