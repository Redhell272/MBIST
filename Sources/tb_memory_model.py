
filepath = "testbench.log"

def state_map(state):
    state_dict = {
        0b0000: "IDLE",
        0b0010: "M0.1",
        0b1000: "M1.1",
        0b1011: "M1.2",
        0b1001: "M2.1",
        0b1010: "M2.2",
        0b1100: "M3.1",
        0b1111: "M3.2",
        0b1101: "M4.1",
        0b1110: "M4.2",
        0b0100: "M5.1",
        0b0001: "END"
    }
    return state_dict.get(state, f"ERR({state})")

# Read the log file and extract the relevant information
text_array = []
with open(filepath, 'r') as file:
    for line in file:
        text_array.append(line.split())
        #print(line.split())

# Extract the number of faults and their details
n_faults = int(text_array[1][2])
faults = []
primitives = []
for i in range(n_faults):
    addr = int(text_array[2 + i][1].split("=")[1], 16)
    bit = int(text_array[2 + i][2].split("=")[1])
    prim = int(text_array[2 + i][3].split("=")[1], 16)

    faults.append([[addr, bit],[]])
    primitives.append(prim)

# Match the faults found by the MBIST with the faults
for text in text_array[5 + n_faults:-3]:
    addr = int(text[3].split("=")[1], 16)
    bit = int(text[4].split("=")[1], 16).bit_length() - 1
    state = int(text[5].split("=")[1], 16)
    dout = (int(text[6].split("=")[1], 16) >> bit) & 0x01
    expc = (int(text[7].split("=")[1], 16) >> bit) & 0x01

    for i in range(n_faults):
        if faults[i][0] == [addr, bit]:
            faults[i][1].append([state, dout, expc])

# Print the fault detection results
print(f'\nFault Detection by MBIST Simulation:')
n_found = 0
for i, fault in enumerate(faults):
    n = len(fault[1])
    reads = ""
    for read in fault[1]:
        reads += f'[{state_map(read[0])}:r{read[2]}]'
    print(f'[{i:02d}] addr=0x{fault[0][0]:02X} bit={fault[0][1]:02d} prim={primitives[i]} | Failing Reads={reads} n={n}')

    if n > 0:
        n_found += 1
print(f'\nTotal Faults Detected by MBIST: {n_found} / {n_faults} = {n_found/n_faults*100:.2f}%\n')
