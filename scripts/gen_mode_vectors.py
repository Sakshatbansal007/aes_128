#!/usr/bin/env python3
import random
from Crypto.Cipher import AES
from Crypto.Util import Counter

KEY = bytes.fromhex("2b7e151628aed2a6abf7158809cf4f3c")
PT = bytes.fromhex("6bc1bee22e409f96e93d7e117393172a" "ae2d8a571e03ac9c9eb76fac45af8e51"
                   "30c81c46a35ce411e5fbc1191a0a52ef" "f69f2445df4f9b17ad2b417be66c3710")
IV = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
CBC_CT = bytes.fromhex("7649abac8119b246cee98e9b12e9197d" "5086cb9b507219ee95db113a917678b2"
                       "73bed6b8e3c1743b7116e69e22229516" "3ff1caa1681fac09120eca307586e1a7")
CTR0 = bytes.fromhex("f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")
CTR_CT = bytes.fromhex("874d6191b620e3261bef6864990db6ce" "9806f66b7970fdff8617187bb9fffdff"
                       "5ae4df3edbd5d35e5b4f09020db03eab" "1e031dda2fbe03d1792170a0f3009cee")

def cbc(key, iv, data, dec):
    c = AES.new(key, AES.MODE_CBC, iv=iv)
    return c.decrypt(data) if dec else c.encrypt(data)

def ctr(key, ctr0, data):

    cnt = Counter.new(128, initial_value=int.from_bytes(ctr0, "big"), allow_wraparound=True)
    return AES.new(key, AES.MODE_CTR, counter=cnt).encrypt(data)

assert cbc(KEY, IV, PT, 0) == CBC_CT and cbc(KEY, IV, CBC_CT, 1) == PT
assert ctr(KEY, CTR0, PT) == CTR_CT and ctr(KEY, CTR0, CTR_CT) == PT
print("SP 800-38A CBC/CTR vectors confirmed against pycryptodome")

random.seed(2032)
rb = lambda n: bytes(random.getrandbits(8) for _ in range(n))
MSGS = 150
n_blocks = 0
with open("vectors/modes.txt", "w") as f:
    for m in range(MSGS):
        mode = m % 2
        dec = random.getrandbits(1)
        key, iv = rb(16), rb(16)
        if m % 10 == 9:
            iv = rb(12) + bytes([0xFF, 0xFF, 0xFF, 0xFE + random.getrandbits(1)])
        nb = random.randint(1, 8)
        data = rb(16 * nb)
        out = ctr(key, iv, data) if mode else cbc(key, iv, data, dec)
        for b in range(nb):
            i, o = data[16 * b:16 * b + 16], out[16 * b:16 * b + 16]
            f.write(f"{mode} {dec} {1 if b == 0 else 0} {key.hex()} {iv.hex()} {i.hex()} {o.hex()}\n")
            n_blocks += 1
print(f"wrote {n_blocks} blocks ({MSGS} messages) to vectors/modes.txt")
