module aes_round_comb #(parameter LAST = 0)(
    input [127:0] s,
    input enc,
    input [127:0] rk_e,
    input [127:0] rk_d,
    output [127:0] s_next
);

    wire [127:0] e_sub, e_shift, e_mix;
    sub_bytes u_sb (.in(s), .out(e_sub));
    shift_rows u_sr (.in(e_sub), .out(e_shift));
    mix_columns u_mc (.in(e_shift), .out(e_mix));
    wire [127:0] e_out = (LAST ? e_shift : e_mix) ^ rk_e;

    wire [127:0] d_shift, d_sub, d_mix;
    inv_shift_rows u_isr(.in(s), .out(d_shift));
    inv_sub_bytes u_isb(.in(d_shift), .out(d_sub));
    wire [127:0] d_ark = d_sub ^ rk_d;
    inv_mix_columns u_imc(.in(d_ark), .out(d_mix));
    wire [127:0] d_out = LAST ? d_ark : d_mix;

    assign s_next = enc ? e_out : d_out;
endmodule
