`timescale 1ns/1ps

module tb_coverage;
    reg clk = 0, rst = 1, start = 0, enc = 1;
    reg [127:0] key, din, orig, ct;
    wire [127:0] dout;
    wire done;
    aes128_core dut(.clk(clk), .rst(rst), .start(start), .enc(enc),
                    .key(key), .din(din), .dout(dout), .done(done));
    always #5 clk = ~clk;

    localparam IDLE = 0, KEYEXP = 1, INIT = 2, ROUNDS = 3, DONE = 4;

    reg [255:0] cov_fwd, cov_inv, cov_key;
    reg [9:0] cov_rnd_e, cov_rnd_d, cov_rcon;
    reg [4:0] cov_st;
    integer b, i, n_fwd, n_inv, n_key, n_rnd, n_rcon, n_st, errors = 0;
    localparam NBLK = 300;

    always @(posedge clk) if (!rst) begin
        cov_st[dut.st] = 1'b1;
        if (dut.st == ROUNDS) begin
            if (dut.enc_q) begin
                cov_rnd_e[dut.cnt - 1] = 1'b1;
                for (i = 0; i < 16; i = i + 1) cov_fwd[dut.state[8*i +: 8]] = 1'b1;
            end else begin
                cov_rnd_d[dut.cnt - 1] = 1'b1;
                for (i = 0; i < 16; i = i + 1) cov_inv[dut.d_shift[8*i +: 8]] = 1'b1;
            end
        end
        if (dut.st == KEYEXP) begin
            cov_rcon[dut.cnt] = 1'b1;
            for (i = 0; i < 4; i = i + 1) cov_key[dut.ke.rot[8*i +: 8]] = 1'b1;
        end
    end

    task go(input e, input [127:0] d);
        begin
            @(negedge clk);
            din = d;
            enc = e;
            start = 1;
            @(negedge clk);
            start = 0;
            wait (done);
            @(negedge clk);
        end
    endtask

    function integer ones(input [255:0] v);
        integer j;
        begin ones = 0;
        for (j = 0;
        j < 256;
        j = j + 1) if (v[j]) ones = ones + 1;
        end
    endfunction

    initial begin
        cov_fwd = 0;
        cov_inv = 0;
        cov_key = 0;
        cov_rnd_e = 0;
        cov_rnd_d = 0;
        cov_rcon = 0;
        cov_st = 0;
        repeat (3) @(negedge clk);
        rst = 0;
        for (b = 0; b < NBLK; b = b + 1) begin
            key = {$random, $random, $random, $random};
            orig = {$random, $random, $random, $random};
            go(1, orig);
            ct = dout;
            go(0, ct);
            if (dout !== orig) errors = errors + 1;
        end
        n_fwd = ones(cov_fwd);
        n_inv = ones(cov_inv);
        n_key = ones(cov_key);
        n_rnd = ones({246'b0, cov_rnd_e}) + ones({246'b0, cov_rnd_d});
        n_rcon = ones({246'b0, cov_rcon});
        n_st = ones({251'b0, cov_st});
        $display("Coverage after %0d enc+dec round trips (%0d data errors):", NBLK, errors);
        $display("  forward S-box inputs (datapath)   : %0d / 256", n_fwd);
        $display("  inverse S-box inputs (datapath)   : %0d / 256", n_inv);
        $display("  key-schedule S-box inputs         : %0d / 256", n_key);
        $display("  rounds x direction                : %0d / 20", n_rnd);
        $display("  Rcon steps                        : %0d / 10", n_rcon);
        $display("  FSM states                        : %0d / 5", n_st);
        if (errors == 0 && n_fwd == 256 && n_inv == 256 && n_key == 256 && n_rnd == 20 && n_rcon == 10 && n_st == 5)
            $display("FULL COVERAGE REACHED");
        else $display("COVERAGE INCOMPLETE");
        $finish;
    end
    initial begin #500000000;
    $display("TIMEOUT");
    $finish;
    end
endmodule
