import random

n = 0

DBs = [
    0x00000000,
    0x55555555,
    0x33333333,
    0x99999999,
    0x11111111,
    0x22222222,
    0x44444444,
    0x88888888,
    0x0F0F0F0F,
    0x1E1E1E1E,
    0x3C3C3C3C,
    0x78787878,
    0x2D2D2D2D,
    0x5A5A5A5A,
    0xB4B4B4B4,
    0x69696969,
]

#DBs = [i | (i << 8) | (i << 16) | (i << 24) for i in range(256)]

def pat_5P(pat, l1, l2, l3):
    DBpat1 = (l1 << 3) & 0x10
    DBpat2 = (l2 << 1) & 0xA
    DBpat3 = (l3 >> 1) & 0x1
    DBpat = DBpat1 | DBpat2 | DBpat3
    return 1 if pat == DBpat else 0
def pat_9P(pat, l1, l2, l3):
    DBpat1 = (l1 << 6)
    DBpat2 = (l2 << 3) & 0x28
    DBpat3 = (l3 << 0)
    DBpat = DBpat1 | DBpat2 | DBpat3
    return 1 if pat == DBpat else 0
def pat_13P(pat, l1, l2, l3, l4, l5):
    DBpat1 = (l1 << 10) & 0x10000
    DBpat2 = (l2 <<  8) & 0xE00
    DBpat3 = (l3 <<  4) & 0x1B0
    DBpat4 = (l4 >>  0) & 0xE
    DBpat5 = (l5 >>  2) & 0x1
    DBpat = DBpat1 | DBpat2 | DBpat3 | DBpat4 | DBpat5
    return 1 if pat == DBpat else 0

def check_DBs_5P(DBs):
    matches = 0
    total = 0
    for i in range(2**5):
        pattern = i & 0x1A
        match = False
        for ii, DB in enumerate(DBs):
            for iii in range(32-3+1):
                DBp = (DB >> iii) & 0x7
                DBpi = ~DBp & 0x7

                pat_match = 0
                pat_match += pat_5P(pattern, DBp , DBp , DBp )
                pat_match += pat_5P(pattern, DBpi, DBp , DBp )
                pat_match += pat_5P(pattern, DBpi, DBpi, DBp )
                pat_match += pat_5P(pattern, DBpi, DBpi, DBpi)
                pat_match += pat_5P(pattern, DBp , DBpi, DBpi)
                pat_match += pat_5P(pattern, DBp , DBp , DBpi)

                pat_match += pat_5P(pattern, DBp , DBpi, DBp )
                pat_match += pat_5P(pattern, DBpi, DBp , DBpi)

                if pat_match == 0 and ii < len(DBs) - 1:
                    nDBp = (DBs[ii + 1] >> iii) & 0x7
                    nDBpi = ~nDBp & 0x7

                    pat_match += pat_5P(pattern, nDBp ,  DBp ,  DBp )
                    pat_match += pat_5P(pattern, nDBp , nDBp ,  DBp )

                    pat_match += pat_5P(pattern, nDBp ,  DBpi,  DBp )
                    pat_match += pat_5P(pattern, nDBpi,  DBp ,  DBpi)
                    pat_match += pat_5P(pattern, nDBp , nDBpi,  DBp )
                    pat_match += pat_5P(pattern, nDBpi, nDBp ,  DBpi)
                    
                if pat_match > 0:
                    match = True
                    break

            if match:
                break

        if match:
            matches += 1
        total += 1

    print(f"\tMatches for  5P patterns: {matches} out of {total}")
    return matches

def check_DBs_9P(DBs):
    matches = 0
    total = 0
    for i in range(2**9):
        pattern = i & 0x1EF
        match = False
        for ii, DB in enumerate(DBs):
            for iii in range(32-3+1):
                DBp = (DB >> iii) & 0x7
                DBpi = ~DBp & 0x7

                pat_match = 0
                pat_match += pat_9P(pattern, DBp , DBp , DBp )
                pat_match += pat_9P(pattern, DBpi, DBp , DBp )
                pat_match += pat_9P(pattern, DBpi, DBpi, DBp )
                pat_match += pat_9P(pattern, DBpi, DBpi, DBpi)
                pat_match += pat_9P(pattern, DBp , DBpi, DBpi)
                pat_match += pat_9P(pattern, DBp , DBp , DBpi)

                pat_match += pat_9P(pattern, DBp , DBpi, DBp )
                pat_match += pat_9P(pattern, DBpi, DBp , DBpi)

                if pat_match == 0 and ii < len(DBs) - 1:
                    nDBp = (DBs[ii + 1] >> iii) & 0x7
                    nDBpi = ~nDBp & 0x7

                    pat_match += pat_9P(pattern, nDBp ,  DBp ,  DBp )
                    pat_match += pat_9P(pattern, nDBp , nDBp ,  DBp )

                    pat_match += pat_9P(pattern, nDBp ,  DBpi,  DBp )
                    pat_match += pat_9P(pattern, nDBpi,  DBp ,  DBpi)
                    pat_match += pat_9P(pattern, nDBp , nDBpi,  DBp )
                    pat_match += pat_9P(pattern, nDBpi, nDBp ,  DBpi)
                    
                if pat_match > 0:
                    match = True
                    break

            if match:
                break

        if match:
            matches += 1
        total += 1

    print(f"\tMatches for  9P patterns: {matches} out of {total}")
    return matches

def check_DBs_13P(DBs):
    matches = 0
    total = 0
    for i in range(2**13):
        pattern = i & 0x1FBF
        match = False
        for ii, DB in enumerate(DBs):
            for iii in range(32-5+1):
                DBp = (DB >> iii) & 0x1F
                DBpi = ~DBp & 0x1F

                pat_match = 0
                pat_match += pat_13P(pattern, DBp , DBp , DBp , DBp , DBp )
                pat_match += pat_13P(pattern, DBpi, DBp , DBp , DBp , DBp )
                pat_match += pat_13P(pattern, DBpi, DBpi, DBp , DBp , DBp )
                pat_match += pat_13P(pattern, DBpi, DBpi, DBpi, DBp , DBp )
                pat_match += pat_13P(pattern, DBpi, DBpi, DBpi, DBpi, DBp )
                pat_match += pat_13P(pattern, DBpi, DBpi, DBpi, DBpi, DBpi)
                pat_match += pat_13P(pattern, DBp , DBpi, DBpi, DBpi, DBpi)
                pat_match += pat_13P(pattern, DBp , DBp , DBpi, DBpi, DBpi)
                pat_match += pat_13P(pattern, DBp , DBp , DBp , DBpi, DBpi)
                pat_match += pat_13P(pattern, DBp , DBp , DBp , DBp , DBpi)

                pat_match += pat_13P(pattern, DBpi, DBp , DBpi, DBp , DBpi)
                pat_match += pat_13P(pattern, DBp , DBp , DBpi, DBp , DBpi)
                pat_match += pat_13P(pattern, DBp , DBpi, DBpi, DBp , DBpi)
                pat_match += pat_13P(pattern, DBp , DBpi, DBp , DBp , DBpi)
                pat_match += pat_13P(pattern, DBp , DBpi, DBp , DBpi, DBpi)
                pat_match += pat_13P(pattern, DBp , DBpi, DBp , DBpi, DBp )
                pat_match += pat_13P(pattern, DBpi, DBpi, DBp , DBpi, DBp )
                pat_match += pat_13P(pattern, DBpi, DBp , DBp , DBpi, DBp )
                pat_match += pat_13P(pattern, DBpi, DBp , DBpi, DBpi, DBp )
                pat_match += pat_13P(pattern, DBpi, DBp , DBpi, DBp , DBp )

                if pat_match == 0 and ii < len(DBs) - 1:
                    nDBp = (DBs[ii + 1] >> iii) & 0x1F
                    nDBpi = ~nDBp & 0x1F

                    pat_match += pat_13P(pattern, nDBp ,  DBp ,  DBp ,  DBp ,  DBp )
                    pat_match += pat_13P(pattern, nDBp , nDBp ,  DBp ,  DBp ,  DBp )
                    pat_match += pat_13P(pattern, nDBp , nDBp , nDBp ,  DBp ,  DBp )
                    pat_match += pat_13P(pattern, nDBp , nDBp , nDBp , nDBp ,  DBp )
                    
                    pat_match += pat_13P(pattern, nDBp ,  DBpi,  DBp ,  DBpi,  DBp )
                    pat_match += pat_13P(pattern, nDBpi,  DBp ,  DBpi,  DBp ,  DBpi)
                    pat_match += pat_13P(pattern, nDBp , nDBpi,  DBp ,  DBpi,  DBp )
                    pat_match += pat_13P(pattern, nDBpi, nDBp ,  DBpi,  DBp ,  DBpi)
                    pat_match += pat_13P(pattern, nDBp , nDBpi, nDBp ,  DBpi,  DBp )
                    pat_match += pat_13P(pattern, nDBpi, nDBp , nDBpi,  DBp ,  DBpi)
                    pat_match += pat_13P(pattern, nDBp , nDBpi, nDBp , nDBpi,  DBp )
                    pat_match += pat_13P(pattern, nDBpi, nDBp , nDBpi, nDBp ,  DBpi)
                    
                if pat_match > 0:
                    match = True
                    break

            if match:
                break

        if match:
            matches += 1
        total += 1

    print(f"\tMatches for 13P patterns: {matches} out of {total}")
    return matches



print(f"Checking DBs: {[hex(DB & 0xFF) for DB in DBs]}")
matches_5P  = check_DBs_5P(DBs)
matches_9P  = check_DBs_9P(DBs)
matches_13P = check_DBs_13P(DBs)

#Randomize order
R = random.Random(420)
new_DBs = DBs.copy()
DBlist = new_DBs[1:]

if n > 0:
    for i in range(n):
        R.shuffle(DBlist)
        new_DBs[1:] = DBlist

        print(f"\n[i:{i:06d}] Shuffled DBs: {[hex(DB & 0xFF) for DB in new_DBs]}")
        new_matches_5P = check_DBs_5P(new_DBs)
        new_matches_9P  = check_DBs_9P(new_DBs)
        if new_matches_9P >= matches_9P:
            new_matches_13P = check_DBs_13P(new_DBs)

            if new_matches_13P > matches_13P:
                print(f"New best 13P matches: {new_matches_13P} (previous: {matches_13P})")
                matches_5P = new_matches_5P
                matches_9P = new_matches_9P
                matches_13P = new_matches_13P
                DBs = new_DBs.copy()

    print(f"\nFinal DBs after {n} shuffles: {[hex(DB & 0xFF) for DB in DBs]}")
    print(f"Matches for 5P patterns: {matches_5P} of {2**5}")
    print(f"Matches for 9P patterns: {matches_9P} of {2**9}")
    print(f"Matches for 13P patterns: {matches_13P} of {2**13}")
    print()

#Final DBs after 100000 shuffles: ['0x00', '0x78', '0x22', '0x44', '0x1e', '0x2d', '0x11', '0xb4', '0x33', '0x55', '0x99', '0x0f', '0x69', '0x5a', '0x3c', '0x88']
#Matches for  5P patterns: 32 of 32
#Matches for  9P patterns: 380 of 512
#Matches for 13P patterns: 1382 of 8192