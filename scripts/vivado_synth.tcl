set top [lindex $argv 0]
file mkdir logs
read_verilog [list rtl/sbox.v rtl/sub_bytes.v rtl/shift_rows.v rtl/mix_columns.v \
                   rtl/key_expand_round.v rtl/aes128_core.v rtl/aes128_compact.v \
                   rtl/aes_round_comb.v rtl/aes128_pipe.v]
synth_design -top $top -part xc7a100tcsg324-1 -mode out_of_context
create_clock -period 10.0 -name clk [get_ports clk]
report_utilization    -file logs/vivado_${top}_utilization.rpt
report_timing_summary -file logs/vivado_${top}_timing.rpt
puts "done: $top"
