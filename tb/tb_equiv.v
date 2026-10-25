`timescale 1ns/1ps

module tb_equiv;
    localparam GROUPS = 12, PER = 25, N = GROUPS * PER;

    reg clk = 0, rst = 1;
    always #5 clk = ~clk;

    reg i_start = 0, i_enc = 1;
    reg [127:0] i_key, i_din;
    wire [127:0] i_dout;
    wire i_done;
    aes128_core u_iter(.clk(clk), .rst(rst), .start(i_start), .enc(i_enc),
                          .key(i_key), .din(i_din), .dout(i_dout), .done(i_done));

    reg c_start = 0, c_enc = 1;
    reg [127:0] c_key, c_din;
    wire [127:0] c_dout;
    wire c_done;
    aes128_compact u_comp(.clk(clk), .rst(rst), .start(c_start), .enc(c_enc),
                          .key(c_key), .din(c_din), .dout(c_dout), .done(c_done));

    reg p_load = 0, p_valid = 0, p_enc = 1;
    reg [127:0] p_key, p_din;
    wire p_ready, p_ovalid;
    wire [127:0] p_dout;
    aes128_pipe u_pipe(.clk(clk), .rst(rst), .key_load(p_load), .key(p_key), .key_ready(p_ready),
                          .in_valid(p_valid), .enc(p_enc), .din(p_din),
                          .out_valid(p_ovalid), .dout(p_dout));

    reg [127:0] t_key [0:N-1];
    reg [127:0] t_din [0:N-1];
    reg t_enc [0:N-1];
    reg [127:0] o_i [0:N-1];
    reg [127:0] o_c [0:N-1];
    reg [127:0] o_p [0:N-1];
    integer n, g, k, errors, e_ic, e_ip, e_cp, pouts;

    initial pouts = 0;
    always @(posedge clk) if (!rst && p_ovalid) begin o_p[pouts] = p_dout;
    pouts = pouts + 1;
    end

    initial begin

        for (g = 0; g < GROUPS; g = g + 1) begin
            k = g * PER;
            t_key[k] = {$random, $random, $random, $random};
            for (n = 0; n < PER; n = n + 1) begin
                t_key[k + n] = t_key[k];
                t_din[k + n] = {$random, $random, $random, $random};
                t_enc[k + n] = $random;
            end
        end
        repeat (3) @(negedge clk);
        rst = 0;

        for (n = 0; n < N; n = n + 1) begin
            @(negedge clk);
            i_key = t_key[n];
            i_din = t_din[n];
            i_enc = t_enc[n];
            i_start = 1;
            @(negedge clk);
            i_start = 0;
            wait (i_done);
            @(negedge clk);
            o_i[n] = i_dout;
        end

        for (n = 0; n < N; n = n + 1) begin
            @(negedge clk);
            c_key = t_key[n];
            c_din = t_din[n];
            c_enc = t_enc[n];
            c_start = 1;
            @(negedge clk);
            c_start = 0;
            wait (c_done);
            @(negedge clk);
            o_c[n] = c_dout;
        end

        for (g = 0; g < GROUPS; g = g + 1) begin
            @(negedge clk);
            p_key = t_key[g * PER];
            p_load = 1;
            @(negedge clk);
            p_load = 0;
            wait (p_ready);
            @(negedge clk);
            for (n = 0; n < PER; n = n + 1) begin
                p_valid = 1;
                p_enc = t_enc[g * PER + n];
                p_din = t_din[g * PER + n];
                @(negedge clk);
            end
            p_valid = 0;
            wait (pouts == (g + 1) * PER);
            @(negedge clk);
        end

        errors = 0;
        e_ic = 0;
        e_ip = 0;
        e_cp = 0;
        for (n = 0; n < N; n = n + 1) begin
            if (o_i[n] !== o_c[n]) e_ic = e_ic + 1;
            if (o_i[n] !== o_p[n]) e_ip = e_ip + 1;
            if (o_c[n] !== o_p[n]) e_cp = e_cp + 1;
        end
        $display("Equivalence over %0d blocks (%0d keys, enc+dec mixed):", N, GROUPS);
        $display("  iterative vs compact   : %0d mismatches", e_ic);
        $display("  iterative vs pipelined : %0d mismatches", e_ip);
        $display("  compact   vs pipelined : %0d mismatches", e_cp);
        if (e_ic + e_ip + e_cp == 0) $display("ALL ARCHITECTURES EQUIVALENT");
        $finish;
    end
    initial begin #2000000000;
    $display("TIMEOUT");
    $finish;
    end
endmodule
