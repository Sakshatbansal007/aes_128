module key_expand_round(
    input [127:0] key_in,
    input [7:0] rcon,
    output [127:0] key_out
);
    wire [31:0] w0 = key_in[127:96];
    wire [31:0] w1 = key_in[95:64];
    wire [31:0] w2 = key_in[63:32];
    wire [31:0] w3 = key_in[31:0];

    wire [31:0] rot = {w3[23:0], w3[31:24]};
    wire [31:0] sub;
    sbox s0(.in(rot[31:24]), .out(sub[31:24]));
    sbox s1(.in(rot[23:16]), .out(sub[23:16]));
    sbox s2(.in(rot[15:8]), .out(sub[15:8]));
    sbox s3(.in(rot[7:0]), .out(sub[7:0]));

    wire [31:0] n0 = w0 ^ sub ^ {rcon, 24'h0};
    wire [31:0] n1 = w1 ^ n0;
    wire [31:0] n2 = w2 ^ n1;
    wire [31:0] n3 = w3 ^ n2;
    assign key_out = {n0, n1, n2, n3};
endmodule
