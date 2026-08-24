
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

fault_count   = _param("fault_count")
random_seed   = _param("random_seed")
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
baseline = R.randint()

def compute_addr(i):
    return R.randint(0, 2**dataAddrW - 1)

def compute_primitive(i):
    return R.randint(0, 2**primitiveW - 1)

def compute_disturb(i):
    return R.randint(0, 2**(disturb_count * disturbW) - 1)

def compute_couple(i):
    return R.randint(0, 2**(couple_count * (dataAddrW + 2)) - 1)

with open(os.path.join(os.path.dirname(__file__), "fault_addr.mem"), "w") as f:
    for i in range(fault_count):
        value = compute_addr(i)
        hex_digits = (dataAddrW + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")

with open(os.path.join(os.path.dirname(__file__), "fault_primitives.mem"), "w") as f:
    for i in range(fault_count):
        value = compute_primitive(i)
        hex_digits = (primitiveW + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")

with open(os.path.join(os.path.dirname(__file__), "disturb_primitives.mem"), "w") as f:
    for i in range(fault_count):
        value = compute_disturb(i)
        hex_digits = (disturb_count*disturbW + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")

with open(os.path.join(os.path.dirname(__file__), "couple_primitives.mem"), "w") as f:
    for i in range(fault_count):
        value = compute_couple(i)
        hex_digits = (couple_count*(dataAddrW+2) + 3) // 4
        f.write(f"{value:0{hex_digits}X}\n")
