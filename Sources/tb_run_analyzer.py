
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

parallel_mems   = _param("parallel_mems")
mem_sections    = _param("mem_sections")
disturb_n       = _param("disturb_count")
couple_n        = _param("couple_count")
watch_depth     = _param("watch_depth")
addrW           = _param("addrW")
dataW           = _param("dataW")

# Derived parameters, mirroring faults_database.sv localparams
mem_addrW   = addrW - math.ceil(math.log2(mem_sections))
mem_dataW   = dataW // parallel_mems
depthW      = math.ceil(math.log2(watch_depth)) if watch_depth > 1 else 1
addrW       = mem_addrW
dataW       = math.ceil(math.log2(mem_dataW))
primitiveW  = (2 * watch_depth) + depthW + 20
dataAddrW   = mem_addrW + math.ceil(math.log2(mem_dataW))
disturbW    = primitiveW - 20 + dataAddrW

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
        0b10001010: "M0.1",
        0b10000000: "M1.1",
        0b10000011: "M1.2",
        0b10010011: "M1.3",
        0b10001001: "M1.4",
        0b10000101: "M2.1",
        0b10000110: "M2.2",
        0b10010110: "M2.3",
        0b10001100: "M2.4",
        0b10000100: "M3.1",
        0b10100110: "M3.2",
        0b10000111: "M3.3",
        0b10001101: "M3.4",
        0b10000001: "M4.1",
        0b10100011: "M4.2",
        0b10000010: "M4.3",
        0b10010000: "M4.4",
        0b10001000: "M4.5",
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

labels_dict = [
['',2],
['   SAF:  SAF',0,0],
['   SOF:  RRF',0,0],
['   USF:  RRF',0,0],
['   NAF:  RRF',0,0],
['',2],
['    TF:   TF',0,0],
['   WDF:  WDF',0,0],
['   RDF:  RDF',0,0],
['  DRDF: DRDF',0,0],
['   IRF:  IRF',0,0],
['   RRF:  RRF',0,0],
['',2],
['  CFst:  SAF',0,0],
['  CFds:  RDF',0,0],
['',1],
['  CFtr:   TF',0,0],
['  CFwd:  WDF',0,0],
['  CFrd:  RDF',0,0],
[' CFdrd: DRDF',0,0],
['  CFir:  IRF',0,0],
['  CFrr:  RRF',0,0],
['',2],
['   LRF:  RDF',0,0],
['   DRF:  DRF',0,0],
['   D1X:  DRF',0,0],
['   D2X:  DRF',0,0],
['   D1X:  SAF',0,0],
['   D2X:  SAF',0,0],
['',1],
['   D1X:   TF',0,0],
['   D2X:   TF',0,0],
['   D1X:  WDF',0,0],
['   D2X:  WDF',0,0],
['   D1X:  RDF',0,0],
['   D2X:  RDF',0,0],
['   D1X: DRDF',0,0],
['   D2X: DRDF',0,0],
['   D1X:  IRF',0,0],
['   D2X:  IRF',0,0],
['   D1X:  RRF',0,0],
['   D2X:  RRF',0,0],
['',4],
['SNPSFk:  SAF',0,0],
['PNPSFk:   TF',0,0],
['ANPSFk:  RDF',0,0],
['',2],
['   ADF:  RRF',0,0],
['  ADOF:  RDF',0,0],
['',2],
['  SWDF:   TF',0,0],
['d2cIRF:  IRF',0,0]
]



# Log the output to both the console and a results file
results_file = open(results_filepath, 'w')
sys.stdout = Tee(sys.__stdout__, results_file)

labels = []
with open("testbench.faults", 'r') as f:
    for line in f:
        index = int(line[1:5])
        label = line[7:13]
        labels.append([index, label])

# Read the log file and extract the relevant information
text_array = []
with open(filepath, 'r') as file:
    for line in file:
        text_array.append(line.split())


# Extract the number of faults and their details
n_faults = int(text_array[1][2])
faults = []
primitives = []
prim_type_counts = [0, 0, 0, 0, 0, 0, 0, 0]
for i in range(n_faults):
    index = int(text_array[2 + i][0].split("[")[1].split("]")[0])
    addr = int(text_array[2 + i][1].split("=")[1], 16)
    bit = int(text_array[2 + i][2].split("=")[1])
    faults.append([[index, addr, bit],[]])

    addr_offset = (addr >> addrW) << addrW
    bit_offset = (bit >> dataW) << dataW

    prim = int(text_array[2 + i][3].split("=")[1], 16)
    disturb = int(text_array[2 + i][4].split("=")[1], 16)
    couple = int(text_array[2 + i][5].split("=")[1], 16)

    prim_text = " "
    for label in labels:
        if label[0] == index:
            prim_text += f'{label[1]}:'
            break                                                                                                               

    prim_type = (prim >> 1) & 0x07
    prim_text += fault_type_map(prim_type) + f'({((prim >> 4) & 0x01)})'
    prim_watch_cnt = (prim >> 20) & bitmask(depthW)
    prim_watch_pattern = (prim >> (20+depthW)) & bitmask(prim_watch_cnt*2)

    if prim_type == 0b001:  # DRF
        prim_text += f'(t={((prim >> 4) & 0x0FFFF):04X})'
    else:
        prim_text += f'        '

    prim_text += f'|'

    if prim_watch_cnt != 0:
        prim_text += f'(w={prim_watch_cnt:01d}:'
        for j in range(prim_watch_cnt):
            watch_code = (prim_watch_pattern >> (j*2)) & 0x03
            if watch_code == 3:
                prim_text += f'W1'
            elif watch_code == 2:
                prim_text += f'W0'
            else:
                prim_text += f'RX'
        for j in range(prim_watch_cnt, watch_depth):
            prim_text += f'  '
        prim_text += f')'
    else:
        prim_text += f'            '

    prim_text += f'|'

    for j in range(disturb_n):
        disturb_prim = (disturb >> (j*disturbW)) & bitmask(disturbW)
        disturb_addr = (disturb_prim & bitmask(addrW)) + addr_offset
        disturb_bit = ((disturb_prim >> addrW) & bitmask(dataW)) + bit_offset
        disturb_count = (disturb_prim >> (addrW+dataW)) & bitmask(depthW)
        disturb_pattern = (disturb_prim >> (addrW+dataW+depthW)) & bitmask(2**(depthW+1))
        
        if disturb_count != 0:
            prim_text += f'(d={disturb_addr:04X}:{disturb_bit:02d}|'
            for j in range(disturb_count):
                disturb_code = (disturb_pattern >> (j*2)) & 0x03
                if disturb_code == 3:
                    prim_text += f'W1'
                elif disturb_code == 2:
                    prim_text += f'W0'
                else:
                    prim_text += f'RX'
            for j in range(disturb_count, watch_depth):
                prim_text += f'  '
            prim_text += f')'
        else:
            prim_text += f'                  '

    prim_text += f'|'

    for j in range(couple_n):
        couple_prim = (couple >> (j*(2+addrW+dataW))) & bitmask(2+addrW+dataW)
        couple_en = couple_prim & 0x01
        couple_value = (couple_prim >> 1) & 0x01
        couple_addr = ((couple_prim >> 2) & bitmask(addrW)) + addr_offset
        couple_bit = ((couple_prim >> (2+addrW)) & bitmask(dataW)) + bit_offset
        
        if couple_en != 0:
            prim_text += f'(c={couple_addr:04X}:{couple_bit:02d}|{couple_value:01d})'
        else:
            prim_text += f'             '

    primitives.append([prim_type, prim_text])
    prim_type_counts[prim_type] += 1


# Sort faults and primitives together by index
faults, primitives = map(list, zip(*sorted(zip(faults, primitives), key=lambda x: x[0][0][0])))
for fault in faults:
    fault[0] = fault[0][1:]  # Remove the index from the fault entry


# Match the faults found by the MBIST with the faults
mismatches = []
for text in text_array[5 + n_faults:-3]:
    sect = int(text[0].split("-")[1].split("]")[0])
    state = int(text[6].split("=")[1], 16)
    addr = int(text[7].split("=")[1], 16)
    data = int(text[8].split("=")[1], 16)
    dout = int(text[9].split("=")[1], 16)

    bit_offset = sect % parallel_mems

    n = 0
    err = data ^ dout
    while err != 0:
        if err & 0x01:
            bit = n + (bit_offset * mem_dataW)
            expc = data & 0x01
            out = dout & 0x01

            found = False
            for i in range(n_faults):
                if faults[i][0] == [addr, bit]:
                    found = True
                    faults[i][1].append([state, out, expc])
            if not found:
                mismatches.append([addr, bit, state, out, expc])

        n += 1
        err = err >> 1
        data = data >> 1
        dout = dout >> 1


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
    print(f'[{i:04d}] 0x{fault[0][0]:04X}:{fault[0][1]:02d} |n:{n if n > 0 else " "}| prim={primitives[i][1]} | Failing Reads={reads} n={n}')

    if n > 0:
        n_found += 1

print(linebreak)
print(f'\nTotal Faults Detected by MBIST: {n_found} / {n_faults} = {n_found/n_faults*100:.2f}%\n')



# Analyze undetected faults by type
detected_faults = [[],[],[],[],[],[],[],[]]
undetected_faults = [[],[],[],[],[],[],[],[]]
for i, fault in enumerate(faults):
    n = len(fault[1])
    if n == 0:
        undetected_faults[primitives[i][0]].append(i)
    else:
        detected_faults[primitives[i][0]].append(i)

    if n > 1: n = 1
    for ii, key in enumerate(labels_dict):
        if primitives[i][1][1:13] == key[0]:
            labels_dict[ii][1] += 1
            labels_dict[ii][2] += n
            break

print(linebreak)
print(f'\nDetected/Undetected Faults by Type:\n')
for i in range(8):
    detected = detected_faults[i]
    undetected = undetected_faults[i]
    print(f'  Detected Faults of type{fault_type_map(i)}: (Fault Success Rate = {(len(detected)/prim_type_counts[i])*100:.2f}%)')
    for j in detected:
        print(f'    [{j:04d}] 0x{faults[j][0][0]:04X}:{faults[j][0][1]:02d} prim={primitives[j][1]}')
    if len(undetected) != 0:
        print(f'  Undetected Faults of type{fault_type_map(i)}:')
        for j in undetected:
            print(f'    [{j:04d}] 0x{faults[j][0][0]:04X}:{faults[j][0][1]:02d} prim={primitives[j][1]}')
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
        print(f'addr=0x{faults[indices[0]][0][0]:04X} bit={faults[indices[0]][0][1]:02d} has linked faults {[f"{i:04d}" for i in indices]} | Primitives {[primitives[i][1].replace(" ", "") for i in indices]}')
    print()

if mismatches != []:
    print(linebreak)
    print(f'\nMismatches Occurring in MBIST Simulation:\n')
    for mismatch in mismatches:
        print(f'addr=0x{mismatch[0]:04X} bit={mismatch[1]:02d} | state={state_map(mismatch[2])} | dout={mismatch[3]} | expc={mismatch[4]}')
    print()

print(linebreak)
print()

sys.stdout = sys.__stdout__
results_file.close()

with open('testbench.coverage', 'w') as lf:
    lf.write(f"'{n_found}/{n_faults}\n")
    i = 0
    while i < len(labels_dict):
        if labels_dict[i][0] == '':
            lf.write(f'{"\n" * labels_dict[i][1]}')
        else:
            if "D1X" in labels_dict[i][0] and "D2X" in labels_dict[i+1][0]:
                lf.write(f"'{labels_dict[i][2]}/{labels_dict[i][1]} | {labels_dict[i+1][2]}/{labels_dict[i+1][1]}\n")
                i += 1
            else:
                lf.write(f"'{labels_dict[i][2]}/{labels_dict[i][1]}\n")
        i += 1