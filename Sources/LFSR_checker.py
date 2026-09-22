
# LFSR Checker for Up and Down Counting Directions
# Designed for Fibonacci Style LFSR counter with reverse shifting for down counting (shift left = up, shift right = down)
# Provide length [l], polynomial (tab positions) [p], and initial value [val]:
l = 15
up_p = [15,7,4,1]
down_p = [8,5,2,1]
val = 0x00



# Calculate LFSR cycle states for up counting direction
L = 2**l
print(f'UP LFSR Tabs: {up_p}')
up_vals = [val]
for i in range(L-1):
    new_bit = 1 if (val & (2**(l-1)-1)) == 0 else 0
    for bit in up_p:
        new_bit += (val >> (bit-1)) & 1
    new_bit %= 2

    val = ((val << 1) | new_bit) & (L-1)
    up_vals.append(val)
print(f'UP LFSR Values: {up_vals[:16]}|{up_vals[-16:]}')

# Ensure that all possible states are entered once
up_matches = []
all1 = True
for i in range(L):
    m = up_vals.count(i)
    up_matches.append(m)
    if m != 1:
        all1 = False
print(f'UP LFSR Matches: {up_matches[0:63]}')
print(f'UP LFSR Covers All States = {all1}\n')



# Calculate LFSR cycle states for down counting direction
print(f'DOWN LFSR Tabs: {down_p}')
down_vals = [val]
for i in range(L-1):
    new_bit = 1 if (val >> 1) == 0 else 0
    for bit in down_p:
        new_bit += (val >> (bit-1)) & 1
    new_bit %= 2

    val = ((val >> 1) | (new_bit << (l-1))) & (L-1)
    down_vals.append(val)
print(f'DOWN LFSR Values: {down_vals[:16]}|{down_vals[-16:]}')

# Ensure that all possible states are entered once
down_matches = []
all1 = True
for i in range(L):
    m = down_vals.count(i)
    down_matches.append(m)
    if m != 1:
        all1 = False
print(f'DOWN LFSR Matches: {down_matches[0:63]}')
print(f'DOWN LFSR Covers All States = {all1}\n')

# Compare Up and Down LFSR cycle states, should be inverse
up_down_matches = []
all1 = True
for i in range(L):
    if up_vals[i] == down_vals[L-1-i]:
        up_down_matches.append(1)
    else:
        up_down_matches.append(0)
        all1 = False

print(f'UP-DOWN LFSR Matches: {up_down_matches[0:63]}')
print(f'UP-DOWN LFSR Match = {all1}\n')