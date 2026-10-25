#!/usr/bin/env python3

def xtime(a):
    a <<= 1
    return (a ^ 0x11B) & 0xFF if a & 0x100 else a

def gmul(a, b):
    p = 0
    while b:
        if b & 1:
            p ^= a
        a = xtime(a)
        b >>= 1
    return p

def ginv(a):

    if a == 0:
        return 0
    r = 1
    for _ in range(254):
        r = gmul(r, a)
    return r

def _rotl8(x, n):
    return ((x << n) | (x >> (8 - n))) & 0xFF

def _sbox_val(a):
    b = ginv(a)
    return b ^ _rotl8(b, 1) ^ _rotl8(b, 2) ^ _rotl8(b, 3) ^ _rotl8(b, 4) ^ 0x63

SBOX = [_sbox_val(i) for i in range(256)]
INV_SBOX = [0] * 256
for _i, _v in enumerate(SBOX):
    INV_SBOX[_v] = _i

def sub_bytes(s):
    return [SBOX[b] for b in s]
def inv_sub_bytes(s):
    return [INV_SBOX[b] for b in s]

def shift_rows(s):
    out = [0] * 16
    for c in range(4):
        for r in range(4):
            out[r + 4 * c] = s[r + 4 * ((c + r) % 4)]
    return out

def inv_shift_rows(s):
    out = [0] * 16
    for c in range(4):
        for r in range(4):
            out[r + 4 * ((c + r) % 4)] = s[r + 4 * c]
    return out

def _mix_col(col, m):

    return [gmul(m[0], col[r]) ^ gmul(m[1], col[(r + 1) % 4]) ^
            gmul(m[2], col[(r + 2) % 4]) ^ gmul(m[3], col[(r + 3) % 4])
            for r in range(4)]

def mix_columns(s):
    out = []
    for c in range(4):
        out += _mix_col(s[4 * c:4 * c + 4], (2, 3, 1, 1))
    return out

def inv_mix_columns(s):
    out = []
    for c in range(4):
        out += _mix_col(s[4 * c:4 * c + 4], (14, 11, 13, 9))
    return out

def add_round_key(s, rk):
    return [a ^ b for a, b in zip(s, rk)]

def key_expansion(key):
    w = [list(key[4 * i:4 * i + 4]) for i in range(4)]
    rcon = 1
    for i in range(4, 44):
        t = list(w[i - 1])
        if i % 4 == 0:
            t = t[1:] + t[:1]
            t = [SBOX[b] for b in t]
            t[0] ^= rcon
            rcon = xtime(rcon)
        w.append([a ^ b for a, b in zip(w[i - 4], t)])
    return [sum(w[4 * r:4 * r + 4], []) for r in range(11)]

def encrypt_block(key, block):
    rk = key_expansion(key)
    s = add_round_key(list(block), rk[0])
    for r in range(1, 10):
        s = add_round_key(mix_columns(shift_rows(sub_bytes(s))), rk[r])
    return bytes(add_round_key(shift_rows(sub_bytes(s)), rk[10]))

def decrypt_block(key, block):
    rk = key_expansion(key)
    s = add_round_key(list(block), rk[10])
    for r in range(9, 0, -1):
        s = inv_mix_columns(add_round_key(inv_sub_bytes(inv_shift_rows(s)), rk[r]))
    return bytes(add_round_key(inv_sub_bytes(inv_shift_rows(s)), rk[0]))

if __name__ == "__main__":
    import random
    from Crypto.Cipher import AES

    k = bytes.fromhex("2b7e151628aed2a6abf7158809cf4f3c")
    p = bytes.fromhex("3243f6a8885a308d313198a2e0370734")
    c = bytes.fromhex("3925841d02dc09fbdc118597196a0b32")
    assert encrypt_block(k, p) == c and decrypt_block(k, c) == p
    k = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
    p = bytes.fromhex("00112233445566778899aabbccddeeff")
    c = bytes.fromhex("69c4e0d86a7b0430d8cdb78070b4c55a")
    assert encrypt_block(k, p) == c and decrypt_block(k, c) == p

    assert SBOX[0x00] == 0x63 and SBOX[0x53] == 0xED and SBOX[0xFF] == 0x16

    random.seed(1)
    for _ in range(500):
        key = bytes(random.getrandbits(8) for _ in range(16))
        blk = bytes(random.getrandbits(8) for _ in range(16))
        ref = AES.new(key, AES.MODE_ECB)
        assert encrypt_block(key, blk) == ref.encrypt(blk)
        assert decrypt_block(key, blk) == ref.decrypt(blk)
    print("aes_ref.py self-check OK (FIPS-197 + 500 random vs pycryptodome)")
