`timescale 1ns/1ps

module tb_modes_nist;
    reg clk = 0, rst = 1;
    reg mode = 0, dec = 0, init = 0, blk_start = 0;
    reg [127:0] key, iv, din;
    wire [127:0] dout;
    wire blk_done, busy;
    integer errors = 0, tests = 0;

    aes_modes dut(.clk(clk), .rst(rst), .mode(mode), .dec(dec), .init(init),
                  .key(key), .iv(iv), .blk_start(blk_start), .din(din),
                  .dout(dout), .blk_done(blk_done), .busy(busy));
    always #5 clk = ~clk;

    localparam [127:0] K = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] IV = 128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] CT0 = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
    reg [127:0] P [0:3];
    reg [127:0] CBC [0:3];
    reg [127:0] CTR [0:3];
    integer i;

    task do_init(input [127:0] k, input [127:0] v);
        begin
            @(negedge clk);
            key = k;
            iv = v;
            init = 1;
            @(negedge clk);
            init = 0;
        end
    endtask

    task do_block(input m, input d, input [127:0] x, input [127:0] exp, input [255:0] name);
        begin
            @(negedge clk);
            mode = m;
            dec = d;
            din = x;
            blk_start = 1;
            @(negedge clk);
            blk_start = 0;
            wait (blk_done);
            @(negedge clk);
            tests = tests + 1;
            if (dout === exp) $display("PASS  %0s", name);
            else begin
                errors = errors + 1;
                $display("FAIL  %0s  got %h  expected %h", name, dout, exp);
            end
        end
    endtask

    initial begin
        P[0] = 128'h6bc1bee22e409f96e93d7e117393172a;
        P[1] = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
        P[2] = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
        P[3] = 128'hf69f2445df4f9b17ad2b417be66c3710;
        CBC[0] = 128'h7649abac8119b246cee98e9b12e9197d;
        CBC[1] = 128'h5086cb9b507219ee95db113a917678b2;
        CBC[2] = 128'h73bed6b8e3c1743b7116e69e22229516;
        CBC[3] = 128'h3ff1caa1681fac09120eca307586e1a7;
        CTR[0] = 128'h874d6191b620e3261bef6864990db6ce;
        CTR[1] = 128'h9806f66b7970fdff8617187bb9fffdff;
        CTR[2] = 128'h5ae4df3edbd5d35e5b4f09020db03eab;
        CTR[3] = 128'h1e031dda2fbe03d1792170a0f3009cee;

        repeat (3) @(negedge clk);
        rst = 0;

        do_init(K, IV);
        for (i = 0; i < 4; i = i + 1) do_block(0, 0, P[i], CBC[i], "SP800-38A CBC encrypt block");
        do_init(K, IV);
        for (i = 0; i < 4; i = i + 1) do_block(0, 1, CBC[i], P[i], "SP800-38A CBC decrypt block");
        do_init(K, CT0);
        for (i = 0; i < 4; i = i + 1) do_block(1, 0, P[i], CTR[i], "SP800-38A CTR encrypt block");
        do_init(K, CT0);
        for (i = 0; i < 4; i = i + 1) do_block(1, 1, CTR[i], P[i], "SP800-38A CTR decrypt block");

        $display("----");
        $display("SP 800-38A tests: %0d run, %0d failed", tests, errors);
        if (errors == 0) $display("ALL MODE NIST TESTS PASSED");
        $finish;
    end
    initial begin #5000000;
    $display("TIMEOUT");
    $finish;
    end
endmodule
