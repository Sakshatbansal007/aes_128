`timescale 1ns/1ps

module tb_aes_nist;
    reg clk = 0, rst = 1, start = 0, enc = 1;
    reg [127:0] key, din;
    wire [127:0] dout;
    wire done;
    integer errors = 0, tests = 0;

    aes128_core dut(.clk(clk), .rst(rst), .start(start), .enc(enc),
                    .key(key), .din(din), .dout(dout), .done(done));
    always #5 clk = ~clk;

    task run(input e, input [127:0] k, input [127:0] d, input [127:0] exp, input [255:0] name);
        begin
            @(negedge clk);
            key = k;
            din = d;
            enc = e;
            start = 1;
            @(negedge clk);
            start = 0;
            wait (done);
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
        $dumpfile("sim/nist.vcd");
        $dumpvars(0, tb_aes_nist);
        repeat (3) @(negedge clk);
        rst = 0;
        @(negedge clk);
        key = 128'h000102030405060708090a0b0c0d0e0f;
        din = 128'h00112233445566778899aabbccddeeff;
        enc = 1;
        start = 1;
        @(negedge clk);
        start = 0;

        wait (done);
        @(negedge clk);
        $display("\n=============================================");
        $display("KEY        : %h", key);
        $display("INPUT (PT) : %h", din);
        $display("CORE CIPHERTEXT: %h", dout);
        $display("=============================================\n");

        run(1, 128'h2b7e151628aed2a6abf7158809cf4f3c, 128'h3243f6a8885a308d313198a2e0370734,
               128'h3925841d02dc09fbdc118597196a0b32, "FIPS-197 App.B encrypt");
        run(0, 128'h2b7e151628aed2a6abf7158809cf4f3c, 128'h3925841d02dc09fbdc118597196a0b32,
               128'h3243f6a8885a308d313198a2e0370734, "FIPS-197 App.B decrypt");

        run(1, 128'h000102030405060708090a0b0c0d0e0f, 128'h00112233445566778899aabbccddeeff,
               128'h69c4e0d86a7b0430d8cdb78070b4c55a, "FIPS-197 App.C.1 encrypt");
        run(0, 128'h000102030405060708090a0b0c0d0e0f, 128'h69c4e0d86a7b0430d8cdb78070b4c55a,
               128'h00112233445566778899aabbccddeeff, "FIPS-197 App.C.1 decrypt");
        $display("----");
        $display("NIST tests: %0d run, %0d failed", tests, errors);
        if (errors == 0) $display("ALL NIST TESTS PASSED");
        $finish;
    end
    initial begin #100000;
    $display("TIMEOUT");
    $finish;
    end
endmodule
