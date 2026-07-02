import math

# Configuration
DIAMETER = 10.0
HEIGHT = 42.89
LAMBDA = 8.575  # mm (Speed of sound / Frequency)
WAVE_PERIOD = 1250

def get_channel_coords():
    coords = []
    # Grid: 2 sides, 5 width, 7 length (66 channels total)
    SIDE, WIDTH, LENGTH = 2, 5, 7
    for j in range(SIDE):
        for i in range(WIDTH * LENGTH):
            if i != (LENGTH-1) and i != (LENGTH*WIDTH-1):
                x = int(i/LENGTH) * DIAMETER
                y = j * HEIGHT
                z = (i % LENGTH) * DIAMETER
                coords.append((x, y, z))
    return coords[:66]

def calculate_levitator_phase(target, channels):
    tx, ty, tz = target
    results = []
    
    for idx, (cx, cy, cz) in enumerate(channels):
        # 1. Exact Euclidean distance
        dist = math.sqrt((tx-cx)**2 + (ty-cy)**2 + (tz-cz)**2)
        
        # 2. Map distance to wavelength, then to 1250 cycle
        # This is the physical phase: (dist / lambda) % 1
        # Multiplied by 1250 to get PWM ticks
        pwm_val = int((dist / LAMBDA) * WAVE_PERIOD) % WAVE_PERIOD
        
        results.append({
            "ch": idx,
            "dist": round(dist, 4),
            "pwm": pwm_val
        })
    return results

# Target Coordinate (as processed by your system)
target = (0, 21.4375, 0)
channels = get_channel_coords()
data = calculate_levitator_phase(target, channels)

# Print the table for verification
print(f"{'Ch':<4} | {'Distance':<10} | {'PWM Phase'}")
print("-" * 30)
for entry in data[:65]: # Showing first 10 for brevity
    print(f"{entry['ch']:<4} | {entry['dist']:<10} | {entry['pwm']}")