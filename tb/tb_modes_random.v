`timescale 1ns/1ps

module tb_modes_random;
    reg clk = 0, rst = 1;
    reg mode = 0, dec = 0, init = 0, blk_start = 0;
    reg [127:0] key, iv, din;
    wire [127:0] dout;
    wire blk_done, busy;
    integer fd, rc, errors = 0, tests = 0, cbc_cnt = 0, ctr_cnt = 0;
    integer m_i, d_i, f_i, maxn;
    reg [127:0] k_i, v_i, x_i, e_i;

    aes_modes dut(.clk(clk), .rst(rst), .mode(mode), .dec(dec), .init(init),
                  .key(key), .iv(iv), .blk_start(blk_start), .din(din),
                  .dout(dout), .blk_done(blk_done), .busy(busy));
    always #5 clk = ~clk;

    initial begin
        if (!$value$plusargs("N=%d", maxn)) maxn = 1000000;
        fd = $fopen("vectors/modes.txt", "r");
        if (fd == 0) begin $display("cannot open vectors/modes.txt (run scripts/gen_mode_vectors.py)");
        $finish;
        end
        repeat (3) @(negedge clk);
        rst = 0;
        while (!$feof(fd) && tests < maxn) begin
            rc = $fscanf(fd, "%d %d %d %h %h %h %h\n", m_i, d_i, f_i, k_i, v_i, x_i, e_i);
            if (rc == 7) begin
                if (f_i) begin
                    @(negedge clk);
                    key = k_i;
                    iv = v_i;
                    init = 1;
                    @(negedge clk);
                    init = 0;
                end
                @(negedge clk);
                mode = m_i[0];
                dec = d_i[0];
                din = x_i;
                blk_start = 1;
                @(negedge clk);
                blk_start = 0;
                wait (blk_done);
                @(negedge clk);
                tests = tests + 1;
                if (m_i) ctr_cnt = ctr_cnt + 1;
                else cbc_cnt = cbc_cnt + 1;
                if (dout !== e_i) begin
                    errors = errors + 1;
                    if (errors < 10)
                        $display("MISMATCH #%0d mode=%0d dec=%0d key=%h in=%h got=%h exp=%h",
                                 tests, m_i, d_i, k_i, x_i, dout, e_i);
                end
            end
        end
        $fclose(fd);
        $display("Mode regression: %0d blocks (%0d CBC, %0d CTR), %0d mismatches",
                 tests, cbc_cnt, ctr_cnt, errors);
        if (errors == 0) $display("ALL MODE RANDOM TESTS PASSED");
        $finish;
    end
    initial begin #400000000;
    $display("TIMEOUT");
    $finish;
    end
endmodule
