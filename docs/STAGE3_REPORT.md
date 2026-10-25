# Stage 3 - Progress in Development
**A Multi-Architecture AES-128 Encryption/Decryption Engine with CBC and CTR Modes**
Group 6: Rishit Gupta, Sakshat Bansal, Poorab Singhi, Namit Jain, Pragam Dixit

## 1. Where we are

All three microarchitectures from the proposal are implemented and verified in simulation,
the CBC/CTR wrapper works on top of them, and the verification flow (Python golden model,
coverage, one-command regression, CI file) is in place. What is left is real Fmax numbers
from Vivado and the final presentation material.

| Item from proposal | Status |
|---|---|
| 1. Iterative 128-bit encryption core | Done (stage 2) |
| 2. FIPS-197 known-answer tests | Done, all pass on all three architectures |
| 3. Unified encrypt/decrypt with shared hardware | Done (iterative, compact and pipelined all do both) |
| 4. CBC and CTR, verified against SP 800-38A | Done, 16/16 KAT blocks pass, plus random messages |
| 5. Compact and pipelined architectures, compared | Done in simulation and Yosys; Vivado Fmax still to run |
| 6. Golden model, coverage, CI | Done; CI workflow written, to be confirmed on first push |

## 2. Final design

**Iterative (`aes128_core`)** - unchanged from stage 2. One round per clock. It first computes
and stores the 10 round keys (10 cycles), so a block takes 23 cycles in total.

**Compact (`aes128_compact`)** - 32-bit datapath. Only one column goes through SubBytes /
MixColumns per clock, so it needs 4 forward and 4 inverse S-boxes (the iterative core has 16 +
16 + 4 for the key schedule). The 4 forward S-boxes are shared with the key schedule's
SubWord. It does not store round keys: a single 128-bit key register is stepped forward each
round for encryption. For decryption it first walks the key forward to round key 10 (10
cycles) and then steps it backwards, one inverse key step per round. A round takes 5 cycles
(1 for ShiftRows + key step, 4 for the columns).

**Pipelined (`aes128_pipe`)** - stage 0 is the initial AddRoundKey and stages 1 to 10 are the
rounds, each with both the forward and inverse round logic selected by an `enc` bit that
travels with the block. Round keys are computed once at `key_load` and stored. After that one
block enters every clock and results come out 11 clocks later; encrypt and decrypt blocks
can be mixed in the stream.

**Modes (`aes_modes`)** - CBC XORs with the previous ciphertext block (encrypt) or after the
core (decrypt). CTR encrypts a 128-bit counter, XORs with the data and increments the counter;
the core always runs in encrypt direction for CTR.

## 3. Verification results

All results below were produced with `regress.sh` (Icarus Verilog 12, Python/pycryptodome).

| Test | What it checks | Result |
|---|---|---|
| S-box unit test | all 256 inputs, forward and inverse, inverse(sbox(x)) = x | 256/256 pass |
| ShiftRows unit test | 504 vectors from the Python model + round trip | pass |
| MixColumns unit test | 510 vectors (incl. FIPS column examples) + round trip | pass |
| Key expansion unit test | 204 keys x 10 rounds (incl. FIPS-197 App. A.1) | pass |
| FIPS-197 App. B and C.1 | encrypt + decrypt, iterative and compact (pipelined in its testbench) | 4/4 pass each |
| SP 800-38A CBC and CTR | F.2.1, F.2.2, F.5.1, F.5.2 (4 blocks each) | 16/16 pass, on iterative and compact core |
| Random vs golden model, iterative | 10,000 vectors, enc/dec mixed | 0 mismatches (stage 2 testbench, unchanged) |
| Random vs golden model, compact | 10,000 vectors, enc/dec mixed | 0 mismatches |
| Random vs golden model, pipelined | 10,000 vectors, back-to-back with random idle gaps, enc/dec mixed | 0 mismatches |
| Random CBC/CTR messages | 678 blocks in 150 messages (including counter carry cases) | 0 mismatches |
| Cross-architecture equivalence | 300 blocks, 12 keys, enc/dec mixed, all three compared | 0 mismatches |
| Functional coverage | see below | full |

Coverage (300 encrypt + decrypt round trips on the iterative core): forward S-box inputs
256/256, inverse S-box inputs 256/256, key-schedule S-box inputs 256/256, rounds x direction
20/20, Rcon steps 10/10, FSM states 5/5.

The golden model has two parts: pycryptodome for full-block vectors, and our own step-by-step
Python AES (`scripts/aes_ref.py`, checked against pycryptodome and FIPS-197) for unit-test
vectors, so the unit tests do not depend on the Verilog generator script.

## 4. Performance analysis

Cycle counts are measured in simulation (`tb_perf.v`), area comes from Yosys (generic
mapping to 6-input LUTs):

| Architecture | LUT6 | Flip-flops | Cycles / block | Latency | Blocks per 1000 cycles |
|---|---|---|---|---|---|
| Compact (32-bit) | 1327 | 270 | 53 enc / 63 dec | 53 / 63 | ~19 |
| Iterative (128-bit) | 4167 | 1943 | 23 | 23 | ~43 |
| Pipelined | 22315 | 4259 | 1 | 11 (+11 key setup, once) | ~990 (1000 blocks in 1011 cycles) |

Area: the iterative design is about 3.1x the compact one, and the pipelined design about 5.4x
the iterative one (16.8x compact). The compact core has only 270 flip-flops, basically the state and
key registers, because it does not store the key schedule. In cycles per block, the pipeline is about
23x faster than the iterative core in steady state.

Yosys also reports the longest path in LUT levels (compact 9, iterative 9, pipelined 7). This is a
unit-delay proxy and not a real clock frequency: the pipelined design shows fewer levels
(probably because each stage is just one round and there is no round-key array mux, though we did not
investigate), and the number does not account for routing, so we are not quoting MHz from it. Real Fmax needs Vivado (`scripts/vivado_synth.tcl`),
which is the one measurement still pending.

## 5. Comparison with the proposal

- The proposal estimated ~11 cycles for the iterative core. Ours is 23 because it precomputes
  the whole key schedule (10 cycles) before the 11 datapath cycles. If the same key were
  reused over many blocks (CBC/CTR), skipping that step would give about 13 cycles per
  block; we have not done this.
- Compact: proposal said "~40+" cycles, we measured 53 (enc) and 63 (dec). The extra
  10 for decrypt is the forward key walk.
- Area ordering is as expected: compact < iterative < pipelined.

## 6. Design changes during development

1. Compact core uses an on-the-fly key (one register) instead of stored round keys, with a
   forward-then-backward key walk for decryption. This was chosen to make the area difference to the iterative core real,
   since storing 11 round keys would cost more than the S-boxes it saves.
2. ShiftRows in the compact core is its own cycle, so columns can be updated in place without
   a second state buffer.
3. Pipelined core supports both directions per block and stores round keys, so its key must be
   loaded before streaming (11 cycles) and must not change while blocks are in flight.
4. Unit-test vectors come from our own Python AES instead of the S-box generator, to avoid
   testing a table against the script that wrote it.
5. Regression is split into `quick` (about 3 min, used by CI) and `full` (all 10,000-vector runs),
   because Icarus is slow on the unrolled S-box tables.

## 7. Problems we ran into

The first pipeline testbench produced mismatches. The cause was in the testbench: the
input-valid signal stayed high while we waited for the pipeline to drain before changing the
key, so blocks were fed twice. The RTL was fine. We fixed the testbench driver.

## 8. Remaining work

- Run `scripts/vivado_synth.tcl` for all three designs and add the real Fmax / utilisation numbers.
- Confirm the GitHub Actions run is green after the first push.
- Waveform screenshots (GTKWave) for the final demo.
- Final presentation and demo.
