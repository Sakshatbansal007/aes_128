module shift_rows(input [127:0] in, output [127:0] out);
    genvar r, c;
    generate
    for (c = 0; c < 4; c = c+1) begin: gc
        for(r = 0; r < 4; r = r+1) begin: gr
            assign out [127-(8*r+32*c):120-(8*r+32*c)] = in [((127-(4*c+5*r)*8)>= 0)?(127-(4*c+5*r)*8):(128+(127-(4*c+5*r)*8)):((120-(4*c+5*r)*8)>= 0)?(120-(4*c+5*r)*8):(128+(120-(4*c+5*r)*8))];
        end
    end
    endgenerate
endmodule

module inv_shift_rows(input [127:0] in, output [127:0] out);
    genvar r, c;
    generate for (c = 0;
    c < 4;
    c = c + 1) begin : gc;
        for (r = 0; r < 4; r = r + 1) begin : gr
           assign out [((127-(4*c+5*r)*8)>= 0)?(127-(4*c+5*r)*8):(128+(127-(4*c+5*r)*8)):((120-(4*c+5*r)*8)>= 0)?(120-(4*c+5*r)*8):(128+(120-(4*c+5*r)*8))] = in [127-(8*r+32*c):120-(8*r+32*c)];
        end
    end
    endgenerate
endmodule
