
import re
import math
import os
import random

def bitmask(w):
    return (1 << w) - 1

# Read base parameters from testbench
_tb_path = os.path.join(os.path.dirname(__file__), "tb_memory_model.sv")
with open(_tb_path) as _f:
    _src = _f.read()

def _param(name):
    m = re.search(rf"localparam\s+int\s+{name}\s*=\s*(\d+)\s*;", _src)
    if not m:
        raise ValueError(f"Parameter '{name}' not found in tb_memory_model.sv")
    return int(m.group(1))

random_seed   = _param("random_seed")
parallel_mems = _param("parallel_mems")
mem_sections  = _param("mem_sections")
fault_count   = _param("fault_count")
disturb_count = _param("disturb_count")
couple_count  = _param("couple_count")
watch_depth   = _param("watch_depth")
addrW         = _param("addrW")
dataW         = _param("dataW")

# Derived parameters, mirroring faults_database.sv localparams
mem_addrW  = addrW - math.ceil(math.log2(mem_sections))
mem_dataW  = dataW // parallel_mems
depthW     = math.ceil(math.log2(watch_depth)) if watch_depth > 1 else 1
primitiveW = (2 * watch_depth) + depthW + 20
dataAddrW  = mem_addrW + math.ceil(math.log2(mem_dataW))
disturbW   = primitiveW - 20 + dataAddrW

R = random.Random(random_seed)
base = [(R.randint(0x00, 0xFF)) for _ in range(fault_count)]
addr = [(R.randint(0, 2**dataAddrW - 1)) for _ in range(fault_count)]
p_vals = []
d_vals = []
c_vals = []

for i, b in enumerate(base):

    init_bit = R.randint(0, 1)
    primitive = 0
    prim_rand = R.randint(0, 2**16)

    prim_couple = 0
    prim_couple_pattern = 0

    disturb = [[0, 0, 0] for _ in range(disturb_count)] #[addr, count, pattern]
    couple = [[0, 0, 0] for _ in range(couple_count)] #[en, value, addr]



    match b % 8:
        case 0:
            primitive = R.randint(0, 7)
            prim_couple = R.randint(0, bitmask(depthW))
            prim_couple_pattern = R.randint(0, bitmask(watch_depth*2))
        case 1:
            primitive = R.randint(0, 7)
            for j in range(disturb_count):
                disturb[j][0] = R.randint(0, 2**dataAddrW - 1)
                disturb[j][1] = R.randint(0, bitmask(depthW))
                disturb[j][2] = R.randint(0, bitmask(watch_depth*2))
        case 2:
            primitive = R.randint(0, 7)
            for j in range(couple_count):
                couple[j][0] = R.randint(0, 1)
                couple[j][1] = R.randint(0, 1)
                couple[j][2] = R.randint(0, 2**dataAddrW - 1)
        case _:
            primitive = R.randint(0, 7)



    p_val = 0
    p_val |= (init_bit & 0x1) << 0
    p_val |= (primitive & 0x7) << 1
    p_val |= (prim_rand & 0xFFFF) << 4
    p_val |= (prim_couple & bitmask(depthW)) << 20
    p_val |= (prim_couple_pattern & bitmask(watch_depth*2)) << (20+depthW)

    d_val = 0
    for j in range(disturb_count):
        d_val |= (disturb[j][0] & bitmask(dataAddrW)) << (j*disturbW + 0)
        d_val |= (disturb[j][1] & bitmask(depthW)) << (j*disturbW + dataAddrW)
        d_val |= (disturb[j][2] & bitmask(watch_depth*2)) << (j*disturbW + dataAddrW + depthW)

    c_val = 0
    for j in range(couple_count):
        c_val |= (couple[j][0] & 0x1) << (j*(2+dataAddrW) + 0)
        c_val |= (couple[j][1] & 0x1) << (j*(2+dataAddrW) + 1)
        c_val |= (couple[j][2] & bitmask(dataAddrW)) << (j*(2+dataAddrW) + 2)

    p_vals.append(p_val)
    d_vals.append(d_val)
    c_vals.append(c_val)



with open(os.path.join(os.path.dirname(__file__), "fault_addr.mem"), "w") as f:
    for i in range(fault_count):
        value = addr[i]
        hex_digits = (dataAddrW + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")

with open(os.path.join(os.path.dirname(__file__), "fault_primitives.mem"), "w") as f:
    for i in range(fault_count):
        value = p_vals[i]
        hex_digits = (primitiveW + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")

with open(os.path.join(os.path.dirname(__file__), "disturb_primitives.mem"), "w") as f:
    for i in range(fault_count):
        value = d_vals[i]
        hex_digits = (disturb_count*disturbW + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")

with open(os.path.join(os.path.dirname(__file__), "couple_primitives.mem"), "w") as f:
    for i in range(fault_count):
        value = c_vals[i]
        hex_digits = (couple_count*(dataAddrW+2) + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")
