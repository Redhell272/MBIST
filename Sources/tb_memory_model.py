
import sys
import re
import math
import os

filepath = "testbench.log"
results_filepath = "testbench.results"

# Read base parameters from testbench
_tb_path = os.path.join(os.path.dirname(__file__), "tb_memory_model.sv")
with open(_tb_path) as _f:
    _src = _f.read()

def _param(name):
    m = re.search(rf"localparam\s+int\s+{name}\s*=\s*(\d+)\s*;", _src)
    if not m:
        raise ValueError(f"Parameter '{name}' not found in tb_memory_model.sv")
    return int(m.group(1))

disturb_n   = _param("disturb_count")
couple_n    = _param("couple_count")
watch_depth = _param("watch_depth")
addrW       = _param("addrW")
dataW       = _param("dataW")

# Derived parameters, mirroring faults_database.sv localparams
depthW     = math.ceil(math.log2(watch_depth)) if watch_depth > 1 else 1
dataW  = math.ceil(math.log2(dataW))

linebreak = "================================================================================================================================"

def bitmask(w):
    return (1 << w) - 1

class Tee:
    def __init__(self, *files):
        self.files = files
    def write(self, obj):
        for f in self.files:
            f.write(obj)
    def flush(self):
        for f in self.files:
            f.flush()

def state_map(state):
    state_dict = {
        0b00000: "IDLE",
        0b01010: "M0.1",
        0b10000: "M1.1",
        0b11011: "M1.2",
        0b10001: "M2.1",
        0b11010: "M2.2",
        0b10100: "M3.1",
        0b11111: "M3.2",
        0b10101: "M4.1",
        0b11110: "M4.2",
        0b01100: "M5.1",
        0b00001: "END"}
    return state_dict.get(state, f"ERR({state})")

def fault_type_map(fault_type):
    fault_type_dict = {
        0b000: "  SAF",
        0b001: "  DRF",
        0b010: "   TF",
        0b011: "  WDF",
        0b100: "  RDF",
        0b101: " DRDF",
        0b110: "  IRF",
        0b111: "  RRF"}
    return fault_type_dict.get(fault_type, f"ERR({fault_type})")



# Log the output to both the console and a results file
results_file = open(results_filepath, 'w')
sys.stdout = Tee(sys.__stdout__, results_file)

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
prim_type_counts = [0, 0, 0, 0, 0, 0, 0, 0]
for i in range(n_faults):
    addr = int(text_array[2 + i][1].split("=")[1], 16)
    bit = int(text_array[2 + i][2].split("=")[1])
    faults.append([[addr, bit],[]])

    prim = int(text_array[2 + i][3].split("=")[1], 16)
    disturb = int(text_array[2 + i][4].split("=")[1], 16)
    couple = int(text_array[2 + i][5].split("=")[1], 16)

    prim_type = (prim >> 1) & 0x07
    prim_text = fault_type_map(prim_type) + f'({((prim >> 4) & 0x01)})'
    prim_watch_cnt = (prim >> 20) & bitmask(depthW)
    prim_watch_pattern = (prim >> (20+depthW)) & bitmask(prim_watch_cnt*2)

    if prim_type == 0b001:  # DRF
        prim_text += f'(t={((prim >> 4) & 0x0FFFF):04X})'
    else:
        prim_text += f'        '

    prim_text += f'|'

    if prim_watch_cnt != 0:
        prim_text += f'(w={prim_watch_cnt:01d}:{prim_watch_pattern:04X})'
    else:
        prim_text += f'          '

    prim_text += f'|'

    for j in range(disturb_n):
        disturb_prim = (disturb >> (j*(addrW+dataW+depthW+2**(depthW+1)))) & bitmask(addrW+dataW+depthW+2**(depthW+1))
        disturb_addr = disturb_prim & bitmask(addrW)
        disturb_bit = (disturb_prim >> addrW) & bitmask(dataW)
        disturb_count = (disturb_prim >> (addrW+dataW)) & bitmask(depthW)
        disturb_pattern = (disturb_prim >> (addrW+dataW+depthW)) & bitmask(2**(depthW+1))
        
        if disturb_count != 0:
            prim_text += f'(d={disturb_addr:03X}:{disturb_bit:02d}|'
            for j in range(disturb_count):
                disturb_code = (disturb_pattern >> (j*2)) & 0x03
                if disturb_code == 3:
                    prim_text += f'W1'
                elif disturb_code == 2:
                    prim_text += f'W0'
                else:
                    prim_text += f'RX'
            prim_text += f')'
        else:
            prim_text += f'             '

    prim_text += f'|'

    for j in range(couple_n):
        couple_prim = (couple >> (j*(2+addrW+dataW))) & bitmask(2+addrW+dataW)
        couple_en = couple_prim & 0x01
        couple_value = (couple_prim >> 1) & 0x01
        couple_addr = (couple_prim >> 2) & bitmask(addrW)
        couple_bit = (couple_prim >> (2+addrW)) & bitmask(dataW)
        
        if couple_en != 0:
            prim_text += f'(c={couple_addr:03X}:{couple_bit:02d}|{couple_value:01d})'
        else:
            prim_text += f'            '

    primitives.append([prim_type, prim_text])
    prim_type_counts[prim_type] += 1


# Match the faults found by the MBIST with the faults
for text in text_array[5 + n_faults:-3]:
    addr = int(text[6].split("=")[1], 16)
    bit = int(text[7].split("=")[1], 16)
    if bit != 0:
        bit = bit.bit_length() - 1
    state = int(text[8].split("=")[1], 16)
    dout = (int(text[9].split("=")[1], 16) >> bit) & 0x01
    expc = (int(text[10].split("=")[1], 16) >> bit) & 0x01

    for i in range(n_faults):
        if faults[i][0] == [addr, bit]:
            faults[i][1].append([state, dout, expc])


# Print the fault detection results
print()
print(linebreak)
print(f'\nFault Detection by MBIST Simulation:\n')
n_found = 0
for i, fault in enumerate(faults):
    n = len(fault[1])
    reads = ""
    for read in fault[1]:
        reads += f'[{state_map(read[0])}:r{read[2]}]'
    print(f'[{i:03d}] 0x{fault[0][0]:03X}:{fault[0][1]:02d} |n:{n if n > 0 else " "}| prim={primitives[i][1]} | Failing Reads={reads} n={n}')

    if n > 0:
        n_found += 1

print(linebreak)
print(f'\nTotal Faults Detected by MBIST: {n_found} / {n_faults} = {n_found/n_faults*100:.2f}%\n')



# Analyze undetected faults by type
detected_faults = [[],[],[],[],[],[],[],[]]
undetected_faults = [[],[],[],[],[],[],[],[]]
for i, fault in enumerate(faults):
    if len(fault[1]) == 0:
        undetected_faults[primitives[i][0]].append(i)
    else:
        detected_faults[primitives[i][0]].append(i)

print(linebreak)
print(f'\nDetected/Undetected Faults by Type:\n')
for i in range(8):
    detected = detected_faults[i]
    undetected = undetected_faults[i]
    print(f'  Detected Faults of type{fault_type_map(i)}: (Fault Success Rate = {(len(detected)/prim_type_counts[i])*100:.2f}%)')
    for j in detected:
        print(f'    [{j:03d}] 0x{faults[j][0][0]:03X}:{faults[j][0][1]:02d} prim={primitives[j][1]}')
    if len(undetected) != 0:
        print(f'  Undetected Faults of type{fault_type_map(i)}:')
        for j in undetected:
            print(f'    [{j:03d}] 0x{faults[j][0][0]:03X}:{faults[j][0][1]:02d} prim={primitives[j][1]}')
    print()

# Analyze linked faults
first_faults = []
linked_fault_cells = []
for i, fault in enumerate(faults):
    cell = fault[0]
    if cell not in first_faults:
        first_faults.append(cell)
    elif cell not in linked_fault_cells:
        linked_fault_cells.append(cell)
linked_fault_cells = sorted(linked_fault_cells, key=lambda x: (x[0], x[1]))

linked_faults = []
for cell in linked_fault_cells:
    fault_indices = []
    for i, fault in enumerate(faults):
        if fault[0] == cell:
            fault_indices.append(i)
    linked_faults.append(fault_indices)

if len(linked_faults) != 0:
    print(linebreak)
    print(f'\nLinked Faults:\n')
    for indices in linked_faults:
        print(f'addr=0x{faults[indices[0]][0][0]:03X} bit={faults[indices[0]][0][1]:02d} has linked faults {indices} | Primitives {[primitives[i][1].replace(" ", "") for i in indices]}')
    print()

print(linebreak)
print()

sys.stdout = sys.__stdout__
results_file.close()
