#!/bin/bash

set -u
cd "$(dirname "$0")/.."
mkdir -p logs
command -v yosys >/dev/null || { echo "yosys not found. WSL me:  sudo apt install yosys"; exit 1; }

BASE="rtl/sbox.v rtl/sub_bytes.v rtl/shift_rows.v rtl/mix_columns.v rtl/key_expand_round.v"
declare -A FILES=(
  [aes128_core]="$BASE rtl/aes128_core.v"
  [aes128_compact]="$BASE rtl/aes128_compact.v"
  [aes128_pipe]="$BASE rtl/aes_round_comb.v rtl/aes128_pipe.v"
)
for top in aes128_compact aes128_core aes128_pipe; do
    echo "== synthesizing $top ..."
    yosys -q -l "logs/synth_$top.log" -p "
        read_verilog ${FILES[$top]}
        hierarchy -check -top $top
        synth -flatten -top $top
        abc -lut 6
        opt_clean
        stat
        ltp -noff
    " > /dev/null 2>&1 || { echo "yosys failed for $top, see logs/synth_$top.log"; exit 1; }
done
python3 scripts/synth_report.py
