`timescale 1ns/1ps

module tb_sbox;
    reg [7:0] x;
    wire [7:0] s, is_, back;
    sbox u_s (.in(x), .out(s));
    inv_sbox u_i (.in(x), .out(is_));
    reg [7:0] sx;
    inv_sbox u_b (.in(sx), .out(back));

    integer fd, rc, errors = 0, tests = 0, i, covered;
    reg [7:0] a, es, ei;
    reg [255:0] seen;

    initial begin
        seen = 0;
        fd = $fopen("vectors/unit_sbox.txt", "r");
        if (fd == 0) begin $display("cannot open vectors/unit_sbox.txt (run scripts/gen_unit_vectors.py)");
        $finish;
        end
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%h %h %h\n", a, es, ei);
            if (rc == 3) begin
                x = a;
                #1;
                tests = tests + 1;
                seen[a] = 1'b1;
                if (s !== es) begin errors = errors + 1;
                $display("sbox(%h) = %h, expected %h", a, s, es);
                end
                if (is_ !== ei) begin errors = errors + 1;
                $display("inv_sbox(%h) = %h, expected %h", a, is_, ei);
                end
            end
        end
        $fclose(fd);

        x = 8'h00;
        #1;
        if (s !== 8'h63) begin errors = errors + 1;
        $display("sbox(00) wrong");
        end
        x = 8'h53;
        #1;
        if (s !== 8'hed) begin errors = errors + 1;
        $display("sbox(53) wrong");
        end
        x = 8'hff;
        #1;
        if (s !== 8'h16) begin errors = errors + 1;
        $display("sbox(ff) wrong");
        end

        for (i = 0; i < 256; i = i + 1) begin
            x = i;
            #1;
            sx = s;
            #1;
            if (back !== i[7:0]) begin errors = errors + 1;
            $display("inv_sbox(sbox(%h)) = %h", i[7:0], back);
            end
        end
        covered = 0;
        for (i = 0; i < 256; i = i + 1) if (seen[i]) covered = covered + 1;
        $display("S-box unit test: %0d inputs checked, coverage %0d/256, %0d errors", tests, covered, errors);
        if (errors == 0 && covered == 256) $display("ALL SBOX TESTS PASSED");
        $finish;
    end
endmodule
