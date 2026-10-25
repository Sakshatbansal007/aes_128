module sub_bytes(input [127:0] in, output [127:0] out);
    genvar i;
    generate for (i = 0;
    i < 16;
    i = i + 1) begin : g;
        sbox u(.in(in[8*i +: 8]), .out(out[8*i +: 8]));
    end endgenerate
endmodule

module inv_sub_bytes(input [127:0] in, output [127:0] out);
    genvar i;
    generate for (i = 0;
    i < 16;
    i = i + 1) begin : g;
        inv_sbox u(.in(in[8*i +: 8]), .out(out[8*i +: 8]));
    end endgenerate
endmodule
