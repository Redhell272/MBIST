
import re
import math
import os
import random
import sys

def bitmask(w):
    return (1 << w) - 1

def near_addr(R, addr, mem_dataW, mem_addrW):
    bit = addr >> mem_addrW
    addr = addr & bitmask(mem_addrW)
    ns = 0
    ew = 0
    while(((ns == 0) and (ew == 0)) or ((addr + ns) >= 2**mem_addrW) or ((addr + ns) < 0) or ((bit + ew) >= mem_dataW) or ((bit + ew) < 0)):
        ns = R.randint(0, 11)
        ew = R.randint(0, 11)

        if ns == 0:
            ns = -2
        elif ns < 4:
            ns = -1
        elif ns < 8:
            ns = 0
        elif ns < 11:
            ns = 1
        else: #ns == 11
            ns = 2

        if ew == 0:
            ew = -2
        elif ew < 4:
            ew = -1
        elif ew < 8:
            ew = 0
        elif ew < 11:
            ew = 1
        else: #ew == 11
            ew = 2

    return ((bit + ew) << mem_addrW) | ((addr + ns) & bitmask(mem_addrW))

def pattern_addr(R, addr, couple_count, mem_dataW, mem_addrW):
    pattern = []
    for i in range(couple_count):
        while True:
            new_addr = near_addr(R, addr, mem_dataW, mem_addrW)
            if new_addr not in pattern:
                pattern.append(new_addr)
                break
    return pattern

def column_addr(addr, couple_count, mem_addrW):
    column = []
    row = addr & bitmask(mem_addrW)
    for i in range(couple_count):
        upDown = i & 0x01
        amount = (i >> 1) + 1
        change = -amount if upDown == 0 else amount
        if upDown == 0:
            if row + change > 0:
                column.append(addr + change)
            else:
                change = -change + (couple_count // 2)
                column.append(addr + change)
        elif upDown == 1:
            if row + change < 2**mem_addrW:
                column.append(addr + change)
            else:
                change = -change - (couple_count // 2)
                column.append(addr + change)
    return column



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
base = [(R.randint(0, 999)) for _ in range(fault_count)]
addr = [(R.randint(0, 2**dataAddrW - 1)) for _ in range(fault_count)]
p_vals = []
d_vals = []
c_vals = []
labels = []

print(f'Generating {fault_count} random faults...\n')
for i, b in enumerate(base):
    sys.stdout.write("\033[F") # Clear status line for next print
    print(f"\tGenerating fault {i+1}/{fault_count} (base={b})")

    label = ""
    init_bit = R.randint(0, 1)
    primitive = 0
    prim_rand = R.randint(0, (2**16)-1)

    prim_watch = 0
    prim_watch_pattern = 0

    disturb = [[0, 0, 0] for _ in range(disturb_count)] #[addr, count, pattern]
    couple = [[0, 0, 0] for _ in range(couple_count)] #[en, value, addr]



    near_coupling = 0
    near_disturb = 0
    pattern_coupling = []
    pattern_disturb = []

    if b < 250: #SAF - 25%
        label = "   SAF"
        primitive = 0b000
    elif b < 330: #DRF - 8%
        label = "   DRF"
        primitive = 0b001
    elif b < 430: #TF - 10%
        label = "    TF"
        primitive = 0b010
    elif b < 460: #WDF - 3%
        label = "   WDF"
        primitive = 0b011
    elif b < 510: #RDF - 5%
        label = "   RDF"
        primitive = 0b100
    elif b < 530: #DRDF - 2%
        label = "  DRDF"
        primitive = 0b101
    elif b < 550: #IRF - 2%
        label = "   IRF"
        primitive = 0b110
    elif b < 560: #RRF - 1%
        label = "   RRF"
        primitive = 0b111

    elif b < 640: #SOF - 8%
        label = "   SOF"
        primitive = 0b111
    elif b < 650: #USF - 1%
        label = "   USF"
        primitive = 0b111
    elif b < 660: #NAF - 1%
        label = "   NAF"
        primitive = 0b111

    elif b < 700: #CFst - 4%
        label = "  CFst"
        primitive = 0b000
        near_coupling = R.randint(1, 8)
    elif b < 720: #CFds - 2%
        label = "  CFds"
        primitive = 0b100
        near_disturb = R.randint(1, 8)

    elif b < 740: #CFtr - 2%
        label = "  CFtr"
        primitive = 0b010
        near_coupling = R.randint(1, 8)
    elif b < 750: #CFwd - 1%
        label = "  CFwd"
        primitive = 0b011
        near_coupling = R.randint(1, 8)
    elif b < 765: #CFrd - 1.5%
        label = "  CFrd"
        primitive = 0b100
        near_coupling = R.randint(1, 8)
    elif b < 775: #CFdrd - 1%
        label = " CFdrd"
        primitive = 0b101
        near_coupling = R.randint(1, 8)
    elif b < 785: #CFir - 1%
        label = "  CFir"
        primitive = 0b110
        near_coupling = R.randint(1, 8)
    elif b < 790: #CFrr - 0.5%
        label = "  CFrr"
        primitive = 0b111
        near_coupling = R.randint(1, 8)

    elif b < 805: #LRF - 1.5%
        label = "   LRF"
        primitive = 0b100
        pattern_bit = [~prim_rand & 0x01 for _ in range(couple_count)]
        pattern_coupling = column_addr(addr[i], couple_count, mem_addrW)

    elif b < 845: #D1X - 4%
        label = "   D1X"
        primitive = R.randint(0, 7)
        prim_watch = 1
        prim_watch_pattern = R.randint(0, 3)
    elif b < 855: #D2X - 1%
        label = "   D2X"
        primitive = R.randint(0, 7)
        prim_watch = 2
        prim_watch_pattern = R.randint(0, 15)

    elif b < 875: #SNPSFk - 2%
        label = "SNPSFk"
        primitive = 0b000
        pattern_bit = [R.randint(0, 1) for _ in range(couple_count)]
        pattern_coupling = pattern_addr(R, addr[i], couple_count, mem_dataW, mem_addrW)
    elif b < 885: #PNPSFk - 1%
        label = "PNPSFk"
        primitive = 0b010
        pattern_bit = [R.randint(0, 1) for _ in range(couple_count)]
        pattern_coupling = pattern_addr(R, addr[i], couple_count, mem_dataW, mem_addrW)
    elif b < 890: #ANPSFk - 0.5%
        label = "ANPSFk"
        primitive = 0b100
        pattern_bit = [R.randint(2, 3) for _ in range(couple_count)]
        pattern_disturb = pattern_addr(R, addr[i], disturb_count, mem_dataW, mem_addrW)

    elif b < 940: #ADF - 5%
        label = "   ADF"
        primitive = 0b111
    elif b < 970: #ADOF - 3%
        label = "  ADOF"
        primitive = 0b100
        disturb[0][0] = near_addr(R, addr[i], mem_dataW, mem_addrW)
        disturb[0][1] = 1
        disturb[0][2] = R.randint(2, 3)

    elif b < 990: #SWDF - 2%
        label = "  SWDF"
        primitive = 0b010
        prim_watch = 1
        prim_watch_pattern = R.randint(2, 3)
    elif b < 1000: #d2cIRF - 1%
        label = "d2cIRF"
        primitive = 0b110
        disturb[0][0] = near_addr(R, addr[i], mem_dataW, mem_addrW)
        disturb[0][1] = 1
        disturb[0][2] = R.randint(0, 1)


    near_coupling = 2 if near_coupling == 8 else 1 if near_coupling > 0 else 0
    for ii in range(couple_count):
        if near_coupling > ii and couple_count > 0:
            couple[ii][0] = 1
            couple[ii][1] = R.randint(0, 1)
            couple[ii][2] = near_addr(R, addr[i], mem_dataW, mem_addrW)

    near_disturb = 2 if near_disturb == 8 else 1 if near_disturb > 0 else 0
    for ii in range(disturb_count):
        if near_disturb > ii and disturb_count > 0:
            depth = R.randint(1, 8)
            depth = 2 if depth == 8 else 1
            disturb[ii][0] = near_addr(R, addr[i], mem_dataW, mem_addrW)
            disturb[ii][1] = depth
            disturb[ii][2] = R.randint(0, (4**depth)-1)

    for ii, addrs in enumerate(pattern_coupling):
        couple[ii][0] = 1
        couple[ii][1] = pattern_bit[ii]
        couple[ii][2] = addrs

    for ii, addrs in enumerate(pattern_disturb):
        disturb[ii][0] = addrs
        disturb[ii][1] = 1
        disturb[ii][2] = R.randint(2, 3)


    p_val = 0
    p_val |= (init_bit & 0x1) << 0
    p_val |= (primitive & 0x7) << 1
    p_val |= (prim_rand & 0xFFFF) << 4
    p_val |= (prim_watch & bitmask(depthW)) << 20
    p_val |= (prim_watch_pattern & bitmask(watch_depth*2)) << (20+depthW)

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
    labels.append(label)



print(f'Faults generated. Writing to files...\n')

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

with open("testbench.faults", "w") as f:
    for i in range(fault_count):
        f.write(f"[{i:04d}] {labels[i]}\n")
