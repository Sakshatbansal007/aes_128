#!/bin/bash

set -e
cd "$(dirname "$0")"
mkdir -p sim
RTL="rtl/sbox.v rtl/sub_bytes.v rtl/shift_rows.v rtl/mix_columns.v rtl/key_expand_round.v rtl/aes128_core.v"
for t in nist random roundtrip; do
    echo "=== tb_aes_$t ==="
    [ $t = roundtrip ] && tb=tb/tb_roundtrip.v || tb=tb/tb_aes_$t.v
    iverilog -g2005 -o sim/$t.vvp $tb $RTL
    vvp sim/$t.vvp | grep -v '^VCD'
done
