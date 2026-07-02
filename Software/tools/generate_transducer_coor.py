import os

WIDTH = 5
LENGTH = 7
SIDE = 2
DIAMETER = 10
HEIGHT = 42.89
N = 33

coordinates_mm = []

def float_to_q8_4_hex(val):
    """Converts a float mm value to a 12-bit signed Q8.4 Verilog hex literal."""
    
    scaled_val = int(round(val * 16))
    
    if scaled_val > 2047 or scaled_val < -2048:
        raise ValueError(f"{val}mm out of 12-bit Q8.4 range (-128 to 127.9375mm)")
    
    if scaled_val < 0:
        scaled_val = (1 << 12) + scaled_val
    
    # Mask to 12 bits
    scaled_val &= 0xFFF
    
    return f"12'h{scaled_val:03X}"

for j in range(SIDE):
    for i in range(WIDTH*LENGTH):
        if i != (LENGTH-1) and i != (LENGTH*WIDTH-1):
            coordinates_mm.append((int(i/LENGTH)*DIAMETER,j*HEIGHT,i%LENGTH*DIAMETER))

output_filename = ".\\transducer_coords.vh"

print(f"Generating {output_filename}...")

with open(output_filename, "w") as f:
    f.write("// ======================================================================\n")
    f.write("// AUTOMATICALLY GENERATED VERILOG HEADER FILE - TRANSDUCER COORDINATES\n")
    f.write("// Generated via Python conversion tool script\n")
    f.write("// Format: 12-bit signed fixed-point integer (Q8.4 format, 4 fractional bits)\n")
    f.write("// ======================================================================\n\n")
    
    for idx, (x_mm, y_mm, z_mm) in enumerate(coordinates_mm):
        x_hex = float_to_q8_4_hex(x_mm)
        y_hex = float_to_q8_4_hex(y_mm)
        z_hex = float_to_q8_4_hex(z_mm)

        side2 = 0

        if idx > 32:
            side2 = 33
        
        f.write(f"// Channel {idx:02d} Configuration (Physical coordinates: X={x_mm:.1f}mm, Y={y_mm:.1f}mm, Z={z_mm:.1f}mm)\n")
        f.write(f"`define CH{int(idx/N)}_{idx-side2}_X {x_hex}\n")
        f.write(f"`define CH{int(idx/N)}_{idx-side2}_Y {y_hex}\n")
        f.write(f"`define CH{int(idx/N)}_{idx-side2}_Z {z_hex}\n\n")

print(f"Success! {output_filename} containing {len(coordinates_mm)} channel mappings has been written successfully.")