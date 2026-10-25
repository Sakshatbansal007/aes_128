module mix_columns(input [127:0] in, output [127:0] out);
    function [7:0] xtime(input [7:0] a);
        xtime = {a[6:0], 1'b0} ^ (a[7] ? 8'h1b : 8'h00);
    endfunction
    function [7:0] mul3(input [7:0] a);
        mul3 = xtime(a) ^ a;
    endfunction

        genvar c;
        generate
            for (c = 0; c < 4; c = c + 1) begin : col
            assign out [127-32*c:120-32*c] = xtime(in[127-32*c:120-32*c])^mul3(in[119-32*c:112-32*c])^in[111-32*c:104-32*c]^in[103-32*c:96-32*c];
            assign out [119-32*c:112-32*c] = in[127-32*c:120-32*c]^xtime(in[119-32*c:112-32*c])^mul3(in[111-32*c:104-32*c])^in[103-32*c:96-32*c];
            assign out [111-32*c:104-32*c] = in[127-32*c:120-32*c]^in[119-32*c:112-32*c]^xtime(in[111-32*c:104-32*c])^mul3(in[103-32*c:96-32*c]);
            assign out [103-32*c:96-32*c] = mul3(in[127-32*c:120-32*c])^in[119-32*c:112-32*c]^in[111-32*c:104-32*c]^xtime(in[103-32*c:96-32*c]);
            end
        endgenerate
endmodule

module inv_mix_columns(input [127:0] in, output [127:0] out);
    function [7:0] xtime(input [7:0] a);
        xtime = {a[6:0], 1'b0} ^ (a[7] ? 8'h1b : 8'h00);
    endfunction

    function [7:0] mul9(input [7:0] a);
        mul9 = xtime(xtime(xtime(a))) ^ a;
    endfunction
    function [7:0] mul11(input [7:0] a);
        mul11 = xtime(xtime(xtime(a))) ^ xtime(a) ^ a;
    endfunction
    function [7:0] mul13(input [7:0] a);
        mul13 = xtime(xtime(xtime(a))) ^ xtime(xtime(a)) ^ a;
    endfunction
    function [7:0] mul14(input [7:0] a);
        mul14 = xtime(xtime(xtime(a))) ^ xtime(xtime(a)) ^ xtime(a);
    endfunction

    genvar c;
        generate
            for (c = 0; c < 4; c = c + 1) begin : col
            assign out [127-32*c:120-32*c] = mul14(in[127-32*c:120-32*c])^mul11(in[119-32*c:112-32*c])^mul13(in[111-32*c:104-32*c])^mul9(in[103-32*c:96-32*c]);
            assign out [119-32*c:112-32*c] = mul9(in[127-32*c:120-32*c])^mul14(in[119-32*c:112-32*c])^mul11(in[111-32*c:104-32*c])^mul13(in[103-32*c:96-32*c]);
            assign out [111-32*c:104-32*c] = mul13(in[127-32*c:120-32*c])^mul9(in[119-32*c:112-32*c])^mul14(in[111-32*c:104-32*c])^mul11(in[103-32*c:96-32*c]);
            assign out [103-32*c:96-32*c] = mul11(in[127-32*c:120-32*c])^mul13(in[119-32*c:112-32*c])^mul9(in[111-32*c:104-32*c])^mul14(in[103-32*c:96-32*c]);
            end
        endgenerate
endmodule
