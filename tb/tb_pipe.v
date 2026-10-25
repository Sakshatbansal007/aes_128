`timescale 1ns/1ps

module tb_pipe;
    reg clk = 0, rst = 1;
    reg key_load = 0, in_valid = 0, enc = 1;
    reg [127:0] key, din;
    wire key_ready, out_valid;
    wire [127:0] dout;

    aes128_pipe dut(.clk(clk), .rst(rst), .key_load(key_load), .key(key), .key_ready(key_ready),
                    .in_valid(in_valid), .enc(enc), .din(din),
                    .out_valid(out_valid), .dout(dout));
    always #5 clk = ~clk;

    localparam MAXV = 10010;
    reg [127:0] vk [0:MAXV-1];
    reg [127:0] vd [0:MAXV-1];
    reg [127:0] vx [0:MAXV-1];
    reg ve [0:MAXV-1];
    integer n, fd, rc, e_i, maxn, i, outs, errors, nkat;
    reg [127:0] k_i, d_i, x_i, cur_key;

    initial begin
        outs = 0;
        errors = 0;
    end
    always @(posedge clk) begin
        if (!rst && out_valid) begin
            if (dout !== vx[outs]) begin
                errors = errors + 1;
                if (errors < 10)
                    $display("MISMATCH #%0d enc=%0d key=%h in=%h got=%h exp=%h",
                             outs, ve[outs], vk[outs], vd[outs], dout, vx[outs]);
            end
            outs = outs + 1;
        end
    end

    initial begin
        if (!$value$plusargs("N=%d", maxn)) maxn = 10000;
        n = 0;

        vk[0] = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        ve[0] = 1;
        vd[0] = 128'h3243f6a8885a308d313198a2e0370734;
        vx[0] = 128'h3925841d02dc09fbdc118597196a0b32;
        vk[1] = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        ve[1] = 0;
        vd[1] = 128'h3925841d02dc09fbdc118597196a0b32;
        vx[1] = 128'h3243f6a8885a308d313198a2e0370734;
        vk[2] = 128'h000102030405060708090a0b0c0d0e0f;
        ve[2] = 1;
        vd[2] = 128'h00112233445566778899aabbccddeeff;
        vx[2] = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        vk[3] = 128'h000102030405060708090a0b0c0d0e0f;
        ve[3] = 0;
        vd[3] = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        vx[3] = 128'h00112233445566778899aabbccddeeff;
        nkat = 4;
        n = 4;
        fd = $fopen("vectors/random_grouped.txt", "r");
        if (fd == 0) begin $display("cannot open vectors/random_grouped.txt");
        $finish;
        end
        while (!$feof(fd) && (n - nkat) < maxn) begin
            rc = $fscanf(fd, "%d %h %h %h\n", e_i, k_i, d_i, x_i);
            if (rc == 4) begin ve[n] = e_i[0];
            vk[n] = k_i;
            vd[n] = d_i;
            vx[n] = x_i;
            n = n + 1;
            end
        end
        $fclose(fd);

        repeat (3) @(negedge clk);
        rst = 0;
        for (i = 0; i < n; i = i + 1) begin
            if (i == 0 || vk[i] !== cur_key) begin
                in_valid = 0;
                wait (outs == i);
                @(negedge clk);
                key = vk[i];
                key_load = 1;
                @(negedge clk);
                key_load = 0;
                wait (key_ready);
                @(negedge clk);
                cur_key = vk[i];
            end
            in_valid = 1;
            enc = ve[i];
            din = vd[i];
            @(negedge clk);
            if (($random & 7) == 0) begin
                in_valid = 0;
                repeat (1 + ($random & 3)) @(negedge clk);
            end
        end
        in_valid = 0;
        wait (outs == n);
        @(negedge clk);
        $display("Pipelined core: %0d blocks (%0d FIPS + %0d random), %0d mismatches",
                 n, nkat, n - nkat, errors);
        if (errors == 0) $display("ALL PIPE TESTS PASSED");
        $finish;
    end
    initial begin #2000000000;
    $display("TIMEOUT (outs=%0d of %0d)", outs, n);
    $finish;
    end
endmodule
