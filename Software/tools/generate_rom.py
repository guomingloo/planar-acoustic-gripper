depth = 16384  # must cover max possible distance_scaled value
with open(".\\mod1250.hex", "w") as f:
    for i in range(depth):
        f.write(f"{i % 1250:03X}\n")