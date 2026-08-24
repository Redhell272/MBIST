
import re
import math
import os
import random

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
fault_count   = _param("fault_count")
disturb_count = _param("disturb_count")
couple_count  = _param("couple_count")
watch_depth   = _param("watch_depth")
addrW         = _param("addrW")
dataW         = _param("dataW")

# Derived parameters, mirroring faults_database.sv localparams
depthW     = math.ceil(math.log2(watch_depth)) if watch_depth > 1 else 1
primitiveW = 2 * watch_depth + depthW + 20
dataAddrW  = addrW + math.ceil(math.log2(dataW))
disturbW   = primitiveW - 20 + dataAddrW

R = random.Random(random_seed)
base = [(R.randint(0x00, 0xFF)) for _ in range(fault_count)]

def fault(c, i):
    p_rand = R.randint(0, 2**primitiveW - 1)
    d_rand = R.randint(0, 2**(disturb_count*disturbW) - 1)
    c_rand = R.randint(0, 2**(couple_count*(dataAddrW+2)) - 1)



    match base[i] % 4:
        case 0:
            p_val = p_rand
            d_val = d_rand
            c_val = c_rand
        case 1:
            p_val = p_rand
            d_val = 0x00
            c_val = c_rand
        case 2:
            p_val = p_rand
            d_val = d_rand
            c_val = 0x00
        case _:
            p_val = p_rand
            d_val = 0x00
            c_val = 0x00



    if c == "d":
        return d_val
    elif c == "c":
        return c_val
    else:
        return p_val



with open(os.path.join(os.path.dirname(__file__), "fault_addr.mem"), "w") as f:
    for i in range(fault_count):
        value = R.randint(0, 2**dataAddrW - 1)
        hex_digits = (dataAddrW + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")

with open(os.path.join(os.path.dirname(__file__), "fault_primitives.mem"), "w") as f:
    for i in range(fault_count):
        value = fault("p", i)
        hex_digits = (primitiveW + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")

with open(os.path.join(os.path.dirname(__file__), "disturb_primitives.mem"), "w") as f:
    for i in range(fault_count):
        value = fault("d", i)
        hex_digits = (disturb_count*disturbW + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")

with open(os.path.join(os.path.dirname(__file__), "couple_primitives.mem"), "w") as f:
    for i in range(fault_count):
        value = fault("c", i)
        hex_digits = (couple_count*(dataAddrW+2) + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")
