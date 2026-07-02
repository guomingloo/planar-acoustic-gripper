# Clean up previous simulation
quit -sim

# Create work library (only needed first time, harmless to repeat)
vlib work

# Compile files in dependency order
vlog "altsqrt_28i_6c_sim.v"
vlog "transducer_coords.vh"
vlog "pwm_channel.v"
vlog "calc_phase.v"
vlog "top.v"
vlog "tb_top.v"
vlog "ws2812_controller.v"

# Start simulation
vsim -t 1ns -voptargs="+acc" work.tb_top

# Add all signals to wave window
add wave -divider "UART"
add wave -radix hex      /tb_top/uut/m_axis_tdata
add wave -radix binary   /tb_top/uut/m_axis_tvalid
add wave -radix binary   /tb_top/uut/send_ack
add wave -radix binary   /tb_top/uut/target_valid

add wave -divider "Target Registers"
add wave -radix decimal  /tb_top/uut/target_x_reg
add wave -radix decimal  /tb_top/uut/target_y_reg
add wave -radix decimal  /tb_top/uut/target_z_reg

add wave -divider "Pipeline Pipe 0"
add wave -radix binary   /tb_top/uut/u_calc/pipe[0]/running
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/ch_idx
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/sum_sq
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/sqrt_out
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/intermediate_mult
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/rom_addr_reg
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/abs_ch
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/pipe_phase
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/dx
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/dy
add wave -radix unsigned /tb_top/uut/u_calc/pipe[0]/dz
add wave -radix unsigned -label "ch0  phase" /tb_top/uut/u_calc/pipe[0]/pipe_phase[10:0]
add wave -radix unsigned -label "ch0  phase 2" /tb_top/uut/u_calc/pipe[0]/pipe_phase[362:352]

add wave -divider "Pipeline Pipe 1"
add wave -radix binary   /tb_top/uut/u_calc/pipe[1]/running
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/ch_idx
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/sum_sq
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/sqrt_out
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/intermediate_mult
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/rom_addr_reg
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/abs_ch
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/pipe_phase
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/dx
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/dy
add wave -radix unsigned /tb_top/uut/u_calc/pipe[1]/dz
add wave -radix unsigned     /tb_top/uut/u_calc/CH_Z[1]
add wave -radix unsigned -label "ch1  phase" /tb_top/uut/u_calc/pipe[1]/pipe_phase[10:0]
add wave -radix unsigned -label "ch1  phase 2" /tb_top/uut/u_calc/pipe[1]/pipe_phase[362:352]

add wave -divider "Output"
add wave -radix unsigned   /tb_top/uut/u_calc/rom_q
add wave -radix binary   /tb_top/uut/u_calc/phases_valid
add wave -radix unsigned /tb_top/uut/phase_flat

add wave -divider "PWM"
add wave -radix unsigned /tb_top/uut/master_counter
add wave -radix binary   /tb_top/transducer


# Run simulation
run -all

# Zoom to fit everything in wave window
wave zoom full