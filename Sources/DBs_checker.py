import random

n = 0

DBs = [
    0x00,
    0x55,
    0x33,
    0x99,
    0x11,
    0x22,
    0x44,
    0x88,
    0x0F,
    0x1E,
    0x3C,
    0x78,
    0x2D,
    0x5A,
    0xB4,
    0x69,
]

#DBs = [i for i in range(256)]

def pat_5N(pat, l1, l2, l3):
    DBpat1 = (l1 << 3) & 0x10
    DBpat2 = (l2 << 1) & 0xA
    DBpat3 = (l3 >> 1) & 0x1
    DBpat = DBpat1 | DBpat2 | DBpat3
    return 1 if pat == DBpat else 0
def pat_9N(pat, l1, l2, l3):
    DBpat1 = (l1 << 6)
    DBpat2 = (l2 << 3) & 0x28
    DBpat3 = (l3 << 0)
    DBpat = DBpat1 | DBpat2 | DBpat3
    return 1 if pat == DBpat else 0
def pat_13N(pat, l1, l2, l3, l4, l5):
    DBpat1 = (l1 << 10) & 0x10000
    DBpat2 = (l2 <<  8) & 0xE00
    DBpat3 = (l3 <<  4) & 0x1B0
    DBpat4 = (l4 >>  0) & 0xE
    DBpat5 = (l5 >>  2) & 0x1
    DBpat = DBpat1 | DBpat2 | DBpat3 | DBpat4 | DBpat5
    return 1 if pat == DBpat else 0

def check_DBs_5N(DBs):
    matches = 0
    total = 0
    for i in range(2**5):
        pattern = i & 0x1A
        match = False
        for ii, DB in enumerate(DBs):
            for iii in range(8-3+1):
                DBp = (DB >> iii) & 0x7
                DBpi = ~DBp & 0x7

                pat_match = 0
                pat_match += pat_5N(pattern, DBp , DBp , DBp )
                pat_match += pat_5N(pattern, DBpi, DBp , DBp )
                pat_match += pat_5N(pattern, DBpi, DBpi, DBp )
                pat_match += pat_5N(pattern, DBpi, DBpi, DBpi)
                pat_match += pat_5N(pattern, DBp , DBpi, DBpi)
                pat_match += pat_5N(pattern, DBp , DBp , DBpi)

                pat_match += pat_5N(pattern, DBp , DBpi, DBp )
                pat_match += pat_5N(pattern, DBpi, DBp , DBpi)

                if pat_match == 0 and ii < len(DBs) - 1:
                    nDBp = (DBs[ii + 1] >> iii) & 0x7
                    nDBpi = ~nDBp & 0x7

                    pat_match += pat_5N(pattern, nDBp ,  DBp ,  DBp )
                    pat_match += pat_5N(pattern, nDBp , nDBp ,  DBp )

                    pat_match += pat_5N(pattern, nDBp ,  DBpi,  DBp )
                    pat_match += pat_5N(pattern, nDBpi,  DBp ,  DBpi)
                    pat_match += pat_5N(pattern, nDBp , nDBpi,  DBp )
                    pat_match += pat_5N(pattern, nDBpi, nDBp ,  DBpi)
                    
                if pat_match > 0:
                    match = True
                    break

            if match:
                break

        if match:
            matches += 1
        total += 1

    print(f"\tMatches for  5N patterns: {matches} out of {total}")
    return matches

def check_DBs_9N(DBs):
    matches = 0
    total = 0
    for i in range(2**9):
        pattern = i & 0x1EF
        match = False
        for ii, DB in enumerate(DBs):
            for iii in range(8-3+1):
                DBp = (DB >> iii) & 0x7
                DBpi = ~DBp & 0x7

                pat_match = 0
                pat_match += pat_9N(pattern, DBp , DBp , DBp )
                pat_match += pat_9N(pattern, DBpi, DBp , DBp )
                pat_match += pat_9N(pattern, DBpi, DBpi, DBp )
                pat_match += pat_9N(pattern, DBpi, DBpi, DBpi)
                pat_match += pat_9N(pattern, DBp , DBpi, DBpi)
                pat_match += pat_9N(pattern, DBp , DBp , DBpi)

                pat_match += pat_9N(pattern, DBp , DBpi, DBp )
                pat_match += pat_9N(pattern, DBpi, DBp , DBpi)

                if pat_match == 0 and ii < len(DBs) - 1:
                    nDBp = (DBs[ii + 1] >> iii) & 0x7
                    nDBpi = ~nDBp & 0x7

                    pat_match += pat_9N(pattern, nDBp ,  DBp ,  DBp )
                    pat_match += pat_9N(pattern, nDBp , nDBp ,  DBp )

                    pat_match += pat_9N(pattern, nDBp ,  DBpi,  DBp )
                    pat_match += pat_9N(pattern, nDBpi,  DBp ,  DBpi)
                    pat_match += pat_9N(pattern, nDBp , nDBpi,  DBp )
                    pat_match += pat_9N(pattern, nDBpi, nDBp ,  DBpi)
                    
                if pat_match > 0:
                    match = True
                    break

            if match:
                break

        if match:
            matches += 1
        total += 1

    print(f"\tMatches for  9N patterns: {matches} out of {total}")
    return matches

def check_DBs_13N(DBs):
    matches = 0
    total = 0
    for i in range(2**13):
        pattern = i & 0x1FBF
        match = False
        for ii, DB in enumerate(DBs):
            for iii in range(8-5+1):
                DBp = (DB >> iii) & 0x1F
                DBpi = ~DBp & 0x1F

                pat_match = 0
                pat_match += pat_13N(pattern, DBp , DBp , DBp , DBp , DBp )
                pat_match += pat_13N(pattern, DBpi, DBp , DBp , DBp , DBp )
                pat_match += pat_13N(pattern, DBpi, DBpi, DBp , DBp , DBp )
                pat_match += pat_13N(pattern, DBpi, DBpi, DBpi, DBp , DBp )
                pat_match += pat_13N(pattern, DBpi, DBpi, DBpi, DBpi, DBp )
                pat_match += pat_13N(pattern, DBpi, DBpi, DBpi, DBpi, DBpi)
                pat_match += pat_13N(pattern, DBp , DBpi, DBpi, DBpi, DBpi)
                pat_match += pat_13N(pattern, DBp , DBp , DBpi, DBpi, DBpi)
                pat_match += pat_13N(pattern, DBp , DBp , DBp , DBpi, DBpi)
                pat_match += pat_13N(pattern, DBp , DBp , DBp , DBp , DBpi)

                pat_match += pat_13N(pattern, DBpi, DBp , DBpi, DBp , DBpi)
                pat_match += pat_13N(pattern, DBp , DBp , DBpi, DBp , DBpi)
                pat_match += pat_13N(pattern, DBp , DBpi, DBpi, DBp , DBpi)
                pat_match += pat_13N(pattern, DBp , DBpi, DBp , DBp , DBpi)
                pat_match += pat_13N(pattern, DBp , DBpi, DBp , DBpi, DBpi)
                pat_match += pat_13N(pattern, DBp , DBpi, DBp , DBpi, DBp )
                pat_match += pat_13N(pattern, DBpi, DBpi, DBp , DBpi, DBp )
                pat_match += pat_13N(pattern, DBpi, DBp , DBp , DBpi, DBp )
                pat_match += pat_13N(pattern, DBpi, DBp , DBpi, DBpi, DBp )
                pat_match += pat_13N(pattern, DBpi, DBp , DBpi, DBp , DBp )

                if pat_match == 0 and ii < len(DBs) - 1:
                    nDBp = (DBs[ii + 1] >> iii) & 0x1F
                    nDBpi = ~nDBp & 0x1F

                    pat_match += pat_13N(pattern, nDBp ,  DBp ,  DBp ,  DBp ,  DBp )
                    pat_match += pat_13N(pattern, nDBp , nDBp ,  DBp ,  DBp ,  DBp )
                    pat_match += pat_13N(pattern, nDBp , nDBp , nDBp ,  DBp ,  DBp )
                    pat_match += pat_13N(pattern, nDBp , nDBp , nDBp , nDBp ,  DBp )
                    
                    pat_match += pat_13N(pattern, nDBp ,  DBpi,  DBp ,  DBpi,  DBp )
                    pat_match += pat_13N(pattern, nDBpi,  DBp ,  DBpi,  DBp ,  DBpi)
                    pat_match += pat_13N(pattern, nDBp , nDBpi,  DBp ,  DBpi,  DBp )
                    pat_match += pat_13N(pattern, nDBpi, nDBp ,  DBpi,  DBp ,  DBpi)
                    pat_match += pat_13N(pattern, nDBp , nDBpi, nDBp ,  DBpi,  DBp )
                    pat_match += pat_13N(pattern, nDBpi, nDBp , nDBpi,  DBp ,  DBpi)
                    pat_match += pat_13N(pattern, nDBp , nDBpi, nDBp , nDBpi,  DBp )
                    pat_match += pat_13N(pattern, nDBpi, nDBp , nDBpi, nDBp ,  DBpi)
                    
                if pat_match > 0:
                    match = True
                    break

            if match:
                break

        if match:
            matches += 1
        total += 1

    print(f"\tMatches for 13N patterns: {matches} out of {total}")
    return matches



print(f"Checking DBs: {[hex(DB) for DB in DBs]}")
matches_5N  = check_DBs_5N(DBs)
matches_9N  = check_DBs_9N(DBs)
matches_13N = check_DBs_13N(DBs)

#Randomize order
R = random.Random(42)
new_DBs = DBs.copy()
DBlist = new_DBs[1:]

if n > 0:
    for i in range(n):
        R.shuffle(DBlist)
        new_DBs[1:] = DBlist

        print(f"\n[i:{i:06d}] Shuffled DBs: {[hex(DB) for DB in new_DBs]}")
        new_matches_5N = check_DBs_5N(new_DBs)
        new_matches_9N  = check_DBs_9N(new_DBs)
        if new_matches_9N >= matches_9N:
            new_matches_13N = check_DBs_13N(new_DBs)

            if new_matches_13N > matches_13N:
                print(f"New best 13N matches: {new_matches_13N} (previous: {matches_13N})")
                matches_5N = new_matches_5N
                matches_9N = new_matches_9N
                matches_13N = new_matches_13N
                DBs = new_DBs.copy()

    print(f"\nFinal DBs after {n} shuffles: {[hex(DB) for DB in DBs]}")
    print(f"Matches for 5N patterns: {matches_5N} of {2**5}")
    print(f"Matches for 9N patterns: {matches_9N} of {2**9}")
    print(f"Matches for 13N patterns: {matches_13N} of {2**13}")
    print()

# Final DBs after 250000 shuffles: ['0x0', '0x33', '0x55', '0x99', '0x78', '0x22', '0xb4', '0x11', '0x88', '0x69', '0x5a', '0x3c', '0x1e', '0x44', '0xf', '0x2d']
# Matches for 5N patterns: 32 of 32
# Matches for 9N patterns: 382 of 512
# Matches for 13N patterns: 1124 of 8192