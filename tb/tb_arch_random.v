`timescale 1ns/1ps

`ifndef DUT_MOD
`define DUT_MOD aes128_core
`endif
module tb_arch_random;
    reg clk = 0, rst = 1, start = 0, enc = 1;
    reg [127:0] key, din, exp;
    wire [127:0] dout;
    wire done;
    integer fd, rc, e_i, errors = 0, tests = 0, enc_cnt = 0, dec_cnt = 0, maxn;
    reg [127:0] k_i, d_i, x_i;

    `DUT_MOD dut(.clk(clk), .rst(rst), .start(start), .enc(enc),
                 .key(key), .din(din), .dout(dout), .done(done));
    always #5 clk = ~clk;

    initial begin
        if (!$value$plusargs("N=%d", maxn)) maxn = 1000000;
        fd = $fopen("vectors/random.txt", "r");
        if (fd == 0) begin $display("cannot open vector file");
        $finish;
        end
        repeat (3) @(negedge clk);
        rst = 0;
        while (!$feof(fd) && tests < maxn) begin
            rc = $fscanf(fd, "%d %h %h %h\n", e_i, k_i, d_i, x_i);
            if (rc == 4) begin
                @(negedge clk);
                key = k_i;
                din = d_i;
                enc = e_i[0];
                exp = x_i;
                start = 1;
                @(negedge clk);
                start = 0;
                wait (done);
                @(negedge clk);
                tests = tests + 1;
                if (e_i) enc_cnt = enc_cnt + 1;
                else dec_cnt = dec_cnt + 1;
                if (dout !== exp) begin
                    errors = errors + 1;
                    if (errors < 10)
                        $display("MISMATCH #%0d enc=%0d key=%h in=%h got=%h exp=%h",
                                 tests, e_i, k_i, d_i, dout, exp);
                end
            end
        end
        $fclose(fd);
        $display("Random regression: %0d tests (%0d enc, %0d dec), %0d mismatches",
                 tests, enc_cnt, dec_cnt, errors);
        if (errors == 0) $display("ALL RANDOM TESTS PASSED");
        $finish;
    end
    initial begin #2000000000;
    $display("TIMEOUT");
    $finish;
    end
endmodule
