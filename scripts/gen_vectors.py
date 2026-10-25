#!/usr/bin/env python3
import random
from Crypto.Cipher import AES

random.seed(203)
N = 10000
with open("vectors/random.txt", "w") as f:
    for _ in range(N):
        key = bytes(random.getrandbits(8) for _ in range(16))
        blk = bytes(random.getrandbits(8) for _ in range(16))
        c = AES.new(key, AES.MODE_ECB)
        if random.random() < 0.5:
            f.write(f"1 {key.hex()} {blk.hex()} {c.encrypt(blk).hex()}\n")
        else:
            f.write(f"0 {key.hex()} {blk.hex()} {c.decrypt(blk).hex()}\n")
print(f"wrote {N} vectors to vectors/random.txt")
