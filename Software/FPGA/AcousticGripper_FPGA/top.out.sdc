## Generated SDC file "top.out.sdc"

## Copyright (C) 2025  Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus Prime License Agreement,
## the Altera IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Altera and sold by Altera or its authorized distributors.  Please
## refer to the Altera Software License Subscription Agreements 
## on the Quartus Prime software download page.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 25.1std.0 Build 1129 10/21/2025 SC Lite Edition"

## DATE    "Fri Jun 12 06:12:04 2026"

##
## DEVICE  "EP4CE10E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[0]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[1]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[2]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[3]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[4]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[5]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[6]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[7]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[8]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[9]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[10]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[11]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[12]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[13]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[14]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[15]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[16]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[17]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[18]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[19]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[20]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[21]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[22]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[23]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[24]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[25]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[26]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[27]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[28]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[29]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[30]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[31]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[32]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[33]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[34]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[35]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[36]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[37]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[38]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[39]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[40]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[41]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[42]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[43]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[44]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[45]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[46]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[47]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[48]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[49]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[50]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[51]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[52]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[53]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[54]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[55]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[56]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[57]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[58]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[59]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[60]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[61]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[62]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[63]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[64]}]
set_output_delay -add_delay -max -clock [get_clocks {clk}]  5.000 [get_ports {transducer[65]}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_ports {rx_in}] -to [get_registers *]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

