`timescale 1ns/1ps

module tb_roundtrip;
    reg clk = 0, rst = 1, start = 0, enc = 1;
    reg [127:0] key, din, ct, orig;
    wire [127:0] dout;
    wire done;
    integer i, errors = 0;
    localparam N = 1000;

    aes128_core dut(.clk(clk), .rst(rst), .start(start), .enc(enc),
                    .key(key), .din(din), .dout(dout), .done(done));
    always #5 clk = ~clk;

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

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        for (i = 0; i < N; i = i + 1) begin
            key = {$random, $random, $random, $random};
            orig = {$random, $random, $random, $random};
            go(1, orig);
            ct = dout;
            go(0, ct);
            if (dout !== orig) errors = errors + 1;
        end
        $display("Round-trip: %0d tests, %0d failures", N, errors);
        if (errors == 0) $display("ALL ROUND-TRIP TESTS PASSED");
        $finish;
    end
endmodule
