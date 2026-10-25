#!/bin/bash

set -u
cd "$(dirname "$0")"
MODE=${1:-quick}
mkdir -p sim logs vectors

BASE="rtl/sbox.v rtl/sub_bytes.v rtl/shift_rows.v rtl/mix_columns.v rtl/key_expand_round.v"
ITER="$BASE rtl/aes128_core.v"
COMP="$BASE rtl/aes128_compact.v"
PIPE="$BASE rtl/aes_round_comb.v rtl/aes128_pipe.v"
ALL="$BASE rtl/aes128_core.v rtl/aes128_compact.v rtl/aes_round_comb.v rtl/aes128_pipe.v"

PASSED=0; FAILED=0; SUMMARY=""

run_tb () {
    local name=$1 marker=$2; shift 2
    local ivargs=() vvpargs=() seen_sep=0
    for a in "$@"; do
        if [ "$a" = "--" ]; then seen_sep=1; continue; fi
        if [ $seen_sep -eq 0 ]; then ivargs+=("$a"); else vvpargs+=("$a"); fi
    done
    local t0=$(date +%s)
    if ! iverilog -g2005 -o "sim/$name.vvp" "${ivargs[@]}" > "logs/$name.log" 2>&1; then
        echo "  [COMPILE ERROR] $name (see logs/$name.log)"; FAILED=$((FAILED+1))
        SUMMARY+=$(printf "  %-28s %s\n" "$name" "COMPILE ERROR"); SUMMARY+=$'\n'; return
    fi
    vvp "sim/$name.vvp" "${vvpargs[@]}" 2>&1 | grep -v '^VCD' >> "logs/$name.log"
    local dt=$(( $(date +%s) - t0 ))
    if grep -q "$marker" "logs/$name.log" && ! grep -qE "FAIL|MISMATCH|TIMEOUT|COVERAGE INCOMPLETE" "logs/$name.log"; then
        echo "  [PASS] $name  (${dt}s)"; PASSED=$((PASSED+1)); SUMMARY+=$(printf "  %-28s PASS  %4ss\n" "$name" "$dt")
    else
        echo "  [FAIL] $name  (see logs/$name.log)"; FAILED=$((FAILED+1)); SUMMARY+=$(printf "  %-28s FAIL  %4ss\n" "$name" "$dt")
    fi
    SUMMARY+=$'\n'
}

gen_vectors () {
    echo "generating vectors (python golden model)"
    [ -f vectors/random.txt ] || python3 scripts/gen_vectors.py
    python3 scripts/aes_ref.py            || { echo "golden model self-check failed"; exit 1; }
    python3 scripts/gen_unit_vectors.py   || exit 1
    python3 scripts/gen_vectors_pipe.py   || exit 1
    python3 scripts/gen_mode_vectors.py   || exit 1
}

unit_tests () {
    echo "== unit tests"
    run_tb unit_sbox        "ALL SBOX TESTS PASSED"         tb/tb_sbox.v        $BASE
    run_tb unit_shift_rows  "ALL SHIFTROWS TESTS PASSED"    tb/tb_shift_rows.v  $BASE
    run_tb unit_mix_columns "ALL MIXCOLUMNS TESTS PASSED"   tb/tb_mix_columns.v $BASE
    run_tb unit_key_expand  "ALL KEY EXPANSION TESTS PASSED" tb/tb_key_expand.v $BASE
}

kat_tests () {
    echo "== known-answer tests (FIPS-197, SP 800-38A)"
    run_tb nist_iterative   "ALL NIST TESTS PASSED" -DDUT_MOD=aes128_core    tb/tb_arch_nist.v $ITER
    run_tb nist_compact     "ALL NIST TESTS PASSED" -DDUT_MOD=aes128_compact tb/tb_arch_nist.v $COMP
    run_tb modes_nist       "ALL MODE NIST TESTS PASSED" tb/tb_modes_nist.v $ITER rtl/aes_modes.v
    run_tb modes_nist_compact "ALL MODE NIST TESTS PASSED" -DMODES_CORE=aes128_compact tb/tb_modes_nist.v $COMP rtl/aes_modes.v
}

perf_tests () {
    echo "performance (cycle counts)"
    run_tb perf "PERF pipelined" tb/tb_perf.v $ALL
    grep PERF logs/perf.log
}

case "$MODE" in
  unit)  gen_vectors; unit_tests ;;
  perf)  perf_tests ;;
  synth) bash scripts/run_synth.sh; exit $? ;;
  quick|full)
    gen_vectors
    unit_tests
    kat_tests
    if [ "$MODE" = quick ]; then N=300; NP=1000; NM=200; else N=1000000; NP=10000; NM=1000000; fi
    echo "randomized regression vs python golden model"
    run_tb random_iterative "ALL RANDOM TESTS PASSED" -DDUT_MOD=aes128_core    tb/tb_arch_random.v $ITER -- +N=$N
    run_tb random_compact   "ALL RANDOM TESTS PASSED" -DDUT_MOD=aes128_compact tb/tb_arch_random.v $COMP -- +N=$N
    run_tb random_pipe      "ALL PIPE TESTS PASSED"   tb/tb_pipe.v $PIPE -- +N=$NP
    run_tb random_modes     "ALL MODE RANDOM TESTS PASSED" tb/tb_modes_random.v $ITER rtl/aes_modes.v -- +N=$NM
    if [ "$MODE" = full ]; then
        echo "original stage-2 testbenches (unchanged)"
        run_tb stage2_nist      "ALL NIST TESTS PASSED"       tb/tb_aes_nist.v   $ITER
        run_tb stage2_random    "ALL RANDOM TESTS PASSED"     tb/tb_aes_random.v $ITER
        run_tb stage2_roundtrip "ALL ROUND-TRIP TESTS PASSED" tb/tb_roundtrip.v  $ITER
    fi
    echo "== cross-architecture equivalence"
    run_tb equivalence "ALL ARCHITECTURES EQUIVALENT" tb/tb_equiv.v $ALL
    ;;
  *) echo "usage: bash regress.sh [quick|full|unit|perf|synth]"; exit 2 ;;
esac

echo
echo "SUMMARY"
printf "%s" "$SUMMARY"
echo "passed: $PASSED   failed: $FAILED"
[ $FAILED -eq 0 ]
