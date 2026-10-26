import sys
import os

SBOX = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
]

INV_SBOX = [0] * 256
for idx, val in enumerate(SBOX):
    INV_SBOX[val] = idx

RCON = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36]

def xtime(a):
    a = a << 1
    if a & 0x100:
        return (a ^ 0x11B) & 0xFF
    return a

def gmul(a, b):
    p = 0
    while b:
        if b & 1:
            p ^= a
        a = xtime(a)
        b >>= 1
    return p

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
    return [
        gmul(m[0], col[r]) ^ gmul(m[1], col[(r + 1) % 4]) ^
        gmul(m[2], col[(r + 2) % 4]) ^ gmul(m[3], col[(r + 3) % 4])
        for r in range(4)
    ]

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

def key_expansion_steps(key_bytes):
    w = [list(key_bytes[4 * i:4 * i + 4]) for i in range(4)]
    rcon = 1
    steps_info = []
    
    for i in range(4, 44):
        t = list(w[i - 1])
        is_subword_step = (i % 4 == 0)
        rot_word = None
        sub_word = None
        rcon_val = None
        
        if is_subword_step:
            rot_word = t[1:] + t[:1]
            sub_word = [SBOX[b] for b in rot_word]
            rcon_val = rcon
            sub_word[0] ^= rcon
            t = list(sub_word)
            rcon = xtime(rcon)
            
        w_next = [a ^ b for a, b in zip(w[i - 4], t)]
        w.append(w_next)
        
        if is_subword_step:
            rnd_num = i // 4
            steps_info.append({
                "round": rnd_num,
                "prev_w": list(w[i - 1]),
                "rot": rot_word,
                "sub": sub_word,
                "rcon": rcon_val,
                "w_i_4": list(w[i - 4]),
                "w_i": list(w_next)
            })
            
    round_keys = [sum(w[4 * r:4 * r + 4], []) for r in range(11)]
    return round_keys, steps_info

def fmt_hex(byte_list):
    return " ".join(f"{b:02x}" for b in byte_list)

def fmt_hex_compact(byte_list):
    return "".join(f"{b:02x}" for b in byte_list)

def fmt_matrix(byte_list):
    lines = []
    for r in range(4):
        row_bytes = [byte_list[r + 4 * c] for c in range(4)]
        lines.append("      [ " + "  ".join(f"{b:02x}" for b in row_bytes) + " ]")
    return "\n".join(lines)

def run_trace(key_hex, pt_hex, decrypt=False):
    key_bytes = list(bytes.fromhex(key_hex.replace(" ", "")))
    data_bytes = list(bytes.fromhex(pt_hex.replace(" ", "")))
    
    if len(key_bytes) != 16 or len(data_bytes) != 16:
        print("Error: Key and Data must be exactly 16 bytes (32 hex characters).")
        return
        
    round_keys, key_steps = key_expansion_steps(key_bytes)
    
    print("\n" + "=" * 78)
    print("                AES-128 STEP-BY-STEP SUBMODULE EXECUTION TRACE")
    print("=" * 78)
    print(f" Mode      : {'DECRYPTION' if decrypt else 'ENCRYPTION'}")
    print(f" Master Key: {fmt_hex(key_bytes)}  ({fmt_hex_compact(key_bytes)})")
    print(f" Input Data: {fmt_hex(data_bytes)}  ({fmt_hex_compact(data_bytes)})")
    print("=" * 78)
    
    state = list(data_bytes)
    
    if not decrypt:
        print("\n" + "-" * 78)
        print(" [ROUND 0] INITIAL ADDKEY STEP")
        print("-" * 78)
        print(f"  Input State (Plaintext) : {fmt_hex(state)}")
        print(fmt_matrix(state))
        print(f"  Round Key 0 (Master Key): {fmt_hex(round_keys[0])}")
        state = add_round_key(state, round_keys[0])
        print(f"  --> State after AddRoundKey(RK0): {fmt_hex(state)}")
        print(fmt_matrix(state))
        
        for r in range(1, 10):
            print("\n" + "-" * 78)
            print(f" [ROUND {r}]")
            print("-" * 78)
            k_info = key_steps[r - 1]
            print(f"  [Key Schedule Step {r}]:")
            print(f"    w[{4*r - 1}]           = {fmt_hex(k_info['prev_w'])}")
            print(f"    RotWord          = {fmt_hex(k_info['rot'])}")
            print(f"    SubWord ^ Rcon   = {fmt_hex(k_info['sub'])}  (Rcon={k_info['rcon']:02x})")
            print(f"    w[{4*r - 4}]           = {fmt_hex(k_info['w_i_4'])}")
            print(f"    w[{4*r}] = w[{4*r-4}]^t = {fmt_hex(k_info['w_i'])}")
            print(f"    --> Full Round Key {r}: {fmt_hex(round_keys[r])}")
            print()
            print(f"  1. Start of Round {r} State: {fmt_hex(state)}")
            state = sub_bytes(state)
            print(f"  2. SubBytes  (S-Box)     : {fmt_hex(state)}")
            state = shift_rows(state)
            print(f"  3. ShiftRows (Permutation): {fmt_hex(state)}")
            state = mix_columns(state)
            print(f"  4. MixColumns (MDS GF2^8) : {fmt_hex(state)}")
            state = add_round_key(state, round_keys[r])
            print(f"  5. AddRoundKey (ARK with RK{r}): {fmt_hex(state)}")
            print(fmt_matrix(state))
            
        print("\n" + "-" * 78)
        print(" [ROUND 10] (FINAL ROUND - MixColumns Skipped)")
        print("-" * 78)
        k_info = key_steps[9]
        print(f"  [Key Schedule Step 10]:")
        print(f"    --> Full Round Key 10: {fmt_hex(round_keys[10])}")
        print()
        print(f"  1. Start of Round 10 State: {fmt_hex(state)}")
        state = sub_bytes(state)
        print(f"  2. SubBytes  (S-Box)      : {fmt_hex(state)}")
        state = shift_rows(state)
        print(f"  3. ShiftRows (Permutation): {fmt_hex(state)}")
        print("  4. MixColumns             : [SKIPPED IN FINAL ROUND]")
        state = add_round_key(state, round_keys[10])
        print(f"  5. AddRoundKey (ARK with RK10): {fmt_hex(state)}")
        print(fmt_matrix(state))
        
        print("\n" + "=" * 78)
        print("                        FINAL ENCRYPTION RESULT")
        print("=" * 78)
        print(f" Plaintext  : {fmt_hex_compact(data_bytes)}")
        print(f" Master Key : {fmt_hex_compact(key_bytes)}")
        print(f" Ciphertext : {fmt_hex_compact(state)}")
        print("=" * 78)
        
    else:
        print("\n" + "-" * 78)
        print(" [DECRYPTION ROUND 0] INITIAL ADDKEY STEP (RK10)")
        print("-" * 78)
        print(f"  Input State (Ciphertext): {fmt_hex(state)}")
        print(fmt_matrix(state))
        print(f"  Round Key 10            : {fmt_hex(round_keys[10])}")
        state = add_round_key(state, round_keys[10])
        print(f"  --> State after AddRoundKey(RK10): {fmt_hex(state)}")
        print(fmt_matrix(state))
        
        for cnt in range(1, 10):
            r = 10 - cnt
            print("\n" + "-" * 78)
            print(f" [DECRYPTION ROUND {cnt}] (Applying Round Key {r})")
            print("-" * 78)
            print(f"  1. Start of Decrypt State: {fmt_hex(state)}")
            state = inv_shift_rows(state)
            print(f"  2. InvShiftRows          : {fmt_hex(state)}")
            state = inv_sub_bytes(state)
            print(f"  3. InvSubBytes           : {fmt_hex(state)}")
            state = add_round_key(state, round_keys[r])
            print(f"  4. AddRoundKey (with RK{r}): {fmt_hex(state)}")
            state = inv_mix_columns(state)
            print(f"  5. InvMixColumns         : {fmt_hex(state)}")
            print(fmt_matrix(state))
            
        print("\n" + "-" * 78)
        print(" [DECRYPTION ROUND 10] (FINAL ROUND - InvMixColumns Skipped)")
        print("-" * 78)
        print(f"  1. Start of Final Decrypt: {fmt_hex(state)}")
        state = inv_shift_rows(state)
        print(f"  2. InvShiftRows          : {fmt_hex(state)}")
        state = inv_sub_bytes(state)
        print(f"  3. InvSubBytes           : {fmt_hex(state)}")
        print("  4. InvMixColumns         : [SKIPPED IN FINAL ROUND]")
        state = add_round_key(state, round_keys[0])
        print(f"  5. AddRoundKey (with RK0): {fmt_hex(state)}")
        print(fmt_matrix(state))
        
        print("\n" + "=" * 78)
        print("                        FINAL DECRYPTION RESULT")
        print("=" * 78)
        print(f" Ciphertext : {fmt_hex_compact(data_bytes)}")
        print(f" Master Key : {fmt_hex_compact(key_bytes)}")
        print(f" Plaintext  : {fmt_hex_compact(state)}")
        print("=" * 78)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="AES-128 Step-by-Step Execution Visualizer")
    parser.add_argument("--key", type=str, default="", help="128-bit hex key (32 hex characters)")
    parser.add_argument("--input", type=str, default="", help="128-bit hex input block (32 hex characters)")
    parser.add_argument("--decrypt", action="store_true", help="Run decryption instead of encryption")
    args = parser.parse_args()
    
    key = args.key.strip()
    data = args.input.strip()
    
    if not key or not data:
        print("\n=== AES-128 Submodule Execution Trace Tool ===")
        print("Press ENTER to use official NIST FIPS-197 Appendix B vectors, or type custom 32-char hex.\n")
        
        if not key:
            default_key = "2b7e151628aed2a6abf7158809cf4f3c"
            try:
                user_key = input(f"Enter Key (32 hex) [default: {default_key}]: ").strip()
                key = user_key if user_key else default_key
            except (EOFError, KeyboardInterrupt):
                key = default_key
                
        if not data:
            default_data = "3243f6a8885a308d313198a2e0370734"
            try:
                user_data = input(f"Enter Data (32 hex) [default: {default_data}]: ").strip()
                data = user_data if user_data else default_data
            except (EOFError, KeyboardInterrupt):
                data = default_data
                
    run_trace(key, data, decrypt=args.decrypt)
