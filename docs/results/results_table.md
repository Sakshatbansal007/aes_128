| Architecture | LUT6 | Flip-flops | Critical path (LUT levels) | Cycles / block | Latency (cycles) | Rel. throughput index* |
|---|---|---|---|---|---|---|
| Compact (32-bit) | 1327 | 270 | 9 | 53 | 53 | 0.43x |
| Iterative (128-bit) | 4167 | 1943 | 9 | 23 | 23 | 1.00x |
| Pipelined | 22315 | 4259 | 7 | 1 (11 latency) | 11 | 29.57x |

*index = (blocks per clock) / (LUT levels), i.e. throughput at the clock a LUT-depth-limited
design could reach, normalised to the iterative core. Ye Yosys ka unit-delay proxy h, real MHz nahi -
real numbers ke liye scripts/vivado_synth.tcl.
