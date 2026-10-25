#!/usr/bin/env python3
import os, re, sys

ARCH = [("aes128_compact", "Compact (32-bit)"),
        ("aes128_core", "Iterative (128-bit)"),
        ("aes128_pipe", "Pipelined")]

def parse(top):
    p = f"logs/synth_{top}.log"
    if not os.path.exists(p):
        return None
    txt = open(p).read()

    blk = txt[txt.rfind("Number of cells"):]
    lut = sum(int(n) for k, n in re.findall(r"^\s+(\$lut)\s+(\d+)\s*$", blk, re.M))
    ff = sum(int(n) for k, n in re.findall(r"^\s+(\$_\w*DFF\w*\$?|\$_\w*DLATCH\w*)\s+(\d+)\s*$", blk, re.M))
    m = re.findall(r"Longest topological path in \S+ \(length=(\d+)\)", txt)
    depth = int(m[-1]) if m else None
    return lut, ff, depth

def perf():
    d = {}
    p = "logs/perf.log"
    if os.path.exists(p):
        for line in open(p):
            if line.startswith("PERF"):
                parts = line.split()
                d[parts[1]] = dict(kv.split("=") for kv in parts[2:])
    return d

res = {t: parse(t) for t, _ in ARCH}
pf = perf()
cyc = {"aes128_compact": pf.get("compact", {}).get("enc_latency"),
       "aes128_core": pf.get("iterative", {}).get("enc_latency"),
       "aes128_pipe": "1 (11 latency)" if pf.get("pipelined") else None}
lat = {"aes128_compact": pf.get("compact", {}).get("enc_latency"),
       "aes128_core": pf.get("iterative", {}).get("enc_latency"),
       "aes128_pipe": pf.get("pipelined", {}).get("latency")}

def bpc(t):
    if t == "aes128_pipe": return 1.0
    c = lat[t]; return 1.0 / int(c) if c else None
def idx(t):
    r = res[t]
    if not r or r[2] is None or bpc(t) is None: return None
    return bpc(t) / r[2]
base = idx("aes128_core")

rows = ["| Architecture | LUT6 | Flip-flops | Critical path (LUT levels) | Cycles / block | Latency (cycles) | Rel. throughput index* |",
        "|---|---|---|---|---|---|---|"]
for t, name in ARCH:
    r = res[t]
    if r is None:
        rows.append(f"| {name} | n/a | n/a | n/a | n/a | n/a | n/a |"); continue
    i = idx(t)
    rel = f"{i / base:.2f}x" if (i and base) else "n/a"
    rows.append(f"| {name} | {r[0]} | {r[1]} | {r[2]} | {cyc[t] or 'n/a'} | {lat[t] or 'n/a'} | {rel} |")
out = "\n".join(rows) + ("\n\n*index = (blocks per clock) / (LUT levels), i.e. throughput at the clock a LUT-depth-limited\n"
      "design could reach, normalised to the iterative core. Ye Yosys ka unit-delay proxy h, real MHz nahi -\n"
      "real numbers ke liye scripts/vivado_synth.tcl.\n")
print(out)
open("logs/results_table.md", "w").write(out)
