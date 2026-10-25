`timescale 1ns/1ps

module tb_shift_rows;
    reg [127:0] x;
    wire [127:0] sr, isr, rt;
    shift_rows u_sr (.in(x), .out(sr));
    inv_shift_rows u_isr(.in(x), .out(isr));
    inv_shift_rows u_rt (.in(sr), .out(rt));

    integer fd, rc, errors = 0, tests = 0;
    reg [127:0] a, esr, eisr;
    initial begin
        fd = $fopen("vectors/unit_shiftrows.txt", "r");
        if (fd == 0) begin $display("cannot open vectors/unit_shiftrows.txt");
        $finish;
        end
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%h %h %h\n", a, esr, eisr);
            if (rc == 3) begin
                x = a;
                #1;
                tests = tests + 1;
                if (sr !== esr) begin errors = errors + 1;
                $display("shift_rows(%h) = %h, exp %h", a, sr, esr);
                end
                if (isr !== eisr) begin errors = errors + 1;
                $display("inv_shift_rows(%h) = %h, exp %h", a, isr, eisr);
                end
                if (rt !== a) begin errors = errors + 1;
                $display("round trip failed for %h", a);
                end
            end
        end
        $fclose(fd);
        $display("ShiftRows unit test: %0d vectors, %0d errors", tests, errors);
        if (errors == 0) $display("ALL SHIFTROWS TESTS PASSED");
        $finish;
    end
endmodule
