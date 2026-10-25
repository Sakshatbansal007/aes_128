#!/usr/bin/env python3
import random
from Crypto.Cipher import AES

random.seed(2031)
KEYS, PER_KEY = 100, 100
with open("vectors/random_grouped.txt", "w") as f:
    for _ in range(KEYS):
        key = bytes(random.getrandbits(8) for _ in range(16))
        c = AES.new(key, AES.MODE_ECB)
        for _ in range(PER_KEY):
            blk = bytes(random.getrandbits(8) for _ in range(16))
            if random.random() < 0.5:
                f.write(f"1 {key.hex()} {blk.hex()} {c.encrypt(blk).hex()}\n")
            else:
                f.write(f"0 {key.hex()} {blk.hex()} {c.decrypt(blk).hex()}\n")
print(f"wrote {KEYS * PER_KEY} vectors to vectors/random_grouped.txt")
