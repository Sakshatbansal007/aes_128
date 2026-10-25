`timescale 1ns/1ps

module tb_key_expand;
    reg [127:0] kin;
    reg [7:0] rcon;
    wire [127:0] kout;
    key_expand_round dut(.key_in(kin), .rcon(rcon), .key_out(kout));

    reg [7:0] rc_tab [0:9];
    reg [127:0] k0, e [1:10];
    reg [127:0] cur;
    integer fd, rc, errors = 0, tests = 0, r;

    initial begin
        rc_tab[0] = 8'h01;
        rc_tab[1] = 8'h02;
        rc_tab[2] = 8'h04;
        rc_tab[3] = 8'h08;
        rc_tab[4] = 8'h10;
        rc_tab[5] = 8'h20;
        rc_tab[6] = 8'h40;
        rc_tab[7] = 8'h80;
        rc_tab[8] = 8'h1b;
        rc_tab[9] = 8'h36;
        fd = $fopen("vectors/unit_keyexp.txt", "r");
        if (fd == 0) begin $display("cannot open vectors/unit_keyexp.txt");
        $finish;
        end
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%h %h %h %h %h %h %h %h %h %h %h\n",
                         k0, e[1], e[2], e[3], e[4], e[5], e[6], e[7], e[8], e[9], e[10]);
            if (rc == 11) begin
                cur = k0;
                tests = tests + 1;
                for (r = 1; r <= 10; r = r + 1) begin
                    kin = cur;
                    rcon = rc_tab[r-1];
                    #1;
                    if (kout !== e[r]) begin
                        errors = errors + 1;
                        $display("key %h round %0d: got %h exp %h", k0, r, kout, e[r]);
                    end
                    cur = kout;
                end
            end
        end
        $fclose(fd);

        kin = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        rcon = 8'h01;
        #1;
        if (kout !== 128'ha0fafe1788542cb123a339392a6c7605) begin errors = errors + 1;
        $display("A.1 round 1 wrong: %h", kout);
        end
        $display("Key expansion unit test: %0d keys x 10 rounds, %0d errors", tests, errors);
        if (errors == 0) $display("ALL KEY EXPANSION TESTS PASSED");
        $finish;
    end
endmodule
