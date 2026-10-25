`timescale 1ns/1ps

module tb_mix_columns;
    reg [127:0] x;
    wire [127:0] mc, imc, rt;
    mix_columns u_mc (.in(x), .out(mc));
    inv_mix_columns u_imc(.in(x), .out(imc));
    inv_mix_columns u_rt (.in(mc), .out(rt));

    integer fd, rc, errors = 0, tests = 0;
    reg [127:0] a, emc, eimc;
    initial begin
        fd = $fopen("vectors/unit_mixcol.txt", "r");
        if (fd == 0) begin $display("cannot open vectors/unit_mixcol.txt");
        $finish;
        end
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%h %h %h\n", a, emc, eimc);
            if (rc == 3) begin
                x = a;
                #1;
                tests = tests + 1;
                if (mc !== emc) begin errors = errors + 1;
                $display("mix_columns(%h) = %h, exp %h", a, mc, emc);
                end
                if (imc !== eimc) begin errors = errors + 1;
                $display("inv_mix_columns(%h) = %h, exp %h", a, imc, eimc);
                end
                if (rt !== a) begin errors = errors + 1;
                $display("round trip failed for %h", a);
                end
            end
        end
        $fclose(fd);

        x = {4{32'hdb135345}};
        #1;
        if (mc !== {4{32'h8e4da1bc}}) begin errors = errors + 1;
        $display("db135345 column wrong");
        end
        x = {4{32'hf20a225c}};
        #1;
        if (mc !== {4{32'h9fdc589d}}) begin errors = errors + 1;
        $display("f20a225c column wrong");
        end
        $display("MixColumns unit test: %0d vectors, %0d errors", tests, errors);
        if (errors == 0) $display("ALL MIXCOLUMNS TESTS PASSED");
        $finish;
    end
endmodule
