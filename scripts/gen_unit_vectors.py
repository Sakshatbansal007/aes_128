#!/usr/bin/env python3
import os, random, sys
sys.path.insert(0, os.path.dirname(__file__))
import aes_ref as A

random.seed(2030)
os.makedirs("vectors", exist_ok=True)
h = lambda b: bytes(b).hex()
rb = lambda n: bytes(random.getrandbits(8) for _ in range(n))

with open("vectors/unit_sbox.txt", "w") as f:
    for i in range(256):
        f.write(f"{i:02x} {A.SBOX[i]:02x} {A.INV_SBOX[i]:02x}\n")

fixed = [bytes.fromhex("d42711aee0bf98f1b8b45de51e415230"),
         bytes(range(16)), bytes(16), bytes([0xFF] * 16)]
states = fixed + [rb(16) for _ in range(500)]
with open("vectors/unit_shiftrows.txt", "w") as f:
    for s in states:
        f.write(f"{h(s)} {h(A.shift_rows(list(s)))} {h(A.inv_shift_rows(list(s)))}\n")
with open("vectors/unit_mixcol.txt", "w") as f:

    cols = ["db135345", "f20a225c", "01010101", "c6c6c6c6", "d4d4d4d5", "2d26314c"]
    for c in cols:
        s = bytes.fromhex(c) * 4
        f.write(f"{h(s)} {h(A.mix_columns(list(s)))} {h(A.inv_mix_columns(list(s)))}\n")
    for s in states:
        f.write(f"{h(s)} {h(A.mix_columns(list(s)))} {h(A.inv_mix_columns(list(s)))}\n")
with open("vectors/unit_keyexp.txt", "w") as f:
    keys = [bytes.fromhex("2b7e151628aed2a6abf7158809cf4f3c"),
            bytes.fromhex("000102030405060708090a0b0c0d0e0f"),
            bytes(16), bytes([0xFF] * 16)] + [rb(16) for _ in range(200)]
    for k in keys:
        rks = A.key_expansion(k)
        f.write(h(k) + " " + " ".join(h(r) for r in rks[1:]) + "\n")
print("wrote vectors/unit_*.txt")
