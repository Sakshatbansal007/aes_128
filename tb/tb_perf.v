`timescale 1ns/1ps

module tb_perf;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;
    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

    localparam [127:0] K = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] X = 128'h3243f6a8885a308d313198a2e0370734;

    reg i_start = 0, i_enc = 1;
    wire [127:0] i_dout;
    wire i_done;
    aes128_core u_iter(.clk(clk), .rst(rst), .start(i_start), .enc(i_enc),
                          .key(K), .din(X), .dout(i_dout), .done(i_done));
    reg c_start = 0, c_enc = 1;
    wire [127:0] c_dout;
    wire c_done;
    aes128_compact u_comp(.clk(clk), .rst(rst), .start(c_start), .enc(c_enc),
                          .key(K), .din(X), .dout(c_dout), .done(c_done));
    reg p_load = 0, p_valid = 0, p_enc = 1;
    reg [127:0] p_din;
    wire p_ready, p_ovalid;
    wire [127:0] p_dout;
    aes128_pipe u_pipe(.clk(clk), .rst(rst), .key_load(p_load), .key(K), .key_ready(p_ready),
                          .in_valid(p_valid), .enc(p_enc), .din(p_din),
                          .out_valid(p_ovalid), .dout(p_dout));

    integer t0, li_e, li_d, lc_e, lc_d, lp, ks, st0, st1, nblk;
    localparam STREAM = 1000;

    task time_iter(input e, output integer lat);
        begin
            @(negedge clk);
            i_enc = e;
            i_start = 1;
            t0 = cyc;
            @(negedge clk);
            i_start = 0;
            wait (i_done);
            @(negedge clk);
            lat = cyc - t0;
        end
    endtask
    task time_comp(input e, output integer lat);
        begin
            @(negedge clk);
            c_enc = e;
            c_start = 1;
            t0 = cyc;
            @(negedge clk);
            c_start = 0;
            wait (c_done);
            @(negedge clk);
            lat = cyc - t0;
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        time_iter(1, li_e);
        time_iter(0, li_d);
        time_comp(1, lc_e);
        time_comp(0, lc_d);

        @(negedge clk);
        p_load = 1;
        t0 = cyc;
        @(negedge clk);
        p_load = 0;
        wait (p_ready);
        @(negedge clk);
        ks = cyc - t0;
        p_din = X;
        p_enc = 1;
        p_valid = 1;
        t0 = cyc;
        @(negedge clk);
        p_valid = 0;
        wait (p_ovalid);
        @(negedge clk);
        lp = cyc - t0;
        repeat (3) @(negedge clk);
        st0 = cyc;
        p_valid = 1;
        for (nblk = 0; nblk < STREAM; nblk = nblk + 1) begin
            p_din = {$random, $random, $random, $random};
            p_enc = $random;
            @(negedge clk);
        end
        p_valid = 0;
        wait (p_ovalid == 0);
        @(negedge clk);
        st1 = cyc;

        $display("PERF iterative enc_latency=%0d dec_latency=%0d cycles_per_block=%0d", li_e, li_d, li_e);
        $display("PERF compact   enc_latency=%0d dec_latency=%0d cycles_per_block=%0d", lc_e, lc_d, lc_e);
        $display("PERF pipelined key_setup=%0d latency=%0d stream_%0d_blocks_cycles=%0d", ks, lp, STREAM, st1 - st0);
        $finish;
    end
    initial begin #100000000;
    $display("TIMEOUT");
    $finish;
    end
endmodule
