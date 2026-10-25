module aes128_pipe(
    input clk,
    input rst,

    input key_load,
    input [127:0] key,
    output reg key_ready,

    input in_valid,
    input enc,
    input [127:0] din,

    output out_valid,
    output [127:0] dout
);

    reg [1407:0] rkf;
    reg [3:0] kcnt;
    reg ksetup;

    reg [7:0] rcon;
    always @(*) begin
        case (kcnt)
            4'd0: rcon = 8'h01;
            4'd1: rcon = 8'h02;
            4'd2: rcon = 8'h04;
            4'd3: rcon = 8'h08;
            4'd4: rcon = 8'h10;
            4'd5: rcon = 8'h20;
            4'd6: rcon = 8'h40;
            4'd7: rcon = 8'h80;
            4'd8: rcon = 8'h1b;
            default: rcon = 8'h36;
        endcase
    end

    wire [127:0] cur_rk = rkf[128 * kcnt +: 128];
    wire [127:0] next_rk;
    key_expand_round ke(.key_in(cur_rk), .rcon(rcon), .key_out(next_rk));

    always @(posedge clk) begin
        if (rst) begin
            ksetup <= 1'b0;
            key_ready <= 1'b0;
            kcnt <= 4'd0;
        end else if (key_load && !ksetup) begin
            rkf[127:0] <= key;
            kcnt <= 4'd0;
            ksetup <= 1'b1;
            key_ready <= 1'b0;
        end else if (ksetup) begin
            rkf[128 * (kcnt + 4'd1) +: 128] <= next_rk;
            kcnt <= kcnt + 4'd1;
            if (kcnt == 4'd9) begin
                ksetup <= 1'b0;
                key_ready <= 1'b1;
            end
        end
    end

    reg [127:0] s_q [0:10];
    reg [10:0] v_q;
    reg [10:0] e_q;

    wire accept = in_valid & key_ready;

    always @(posedge clk) begin
        if (rst) v_q[0] <= 1'b0;
        else v_q[0] <= accept;
        if (accept) begin
            s_q[0] <= din ^ (enc ? rkf[127:0] : rkf[1407:1280]);
            e_q[0] <= enc;
        end
    end

    genvar i;
    generate
        for (i = 1; i <= 10; i = i + 1) begin : stg
            wire [127:0] prev = s_q[i-1];
            wire [127:0] nxt;
            aes_round_comb #(.LAST(i == 10)) rnd(
                .s(prev), .enc(e_q[i-1]),
                .rk_e(rkf[128 * i +: 128]),
                .rk_d(rkf[128 * (10 - i) +: 128]),
                .s_next(nxt));
            always @(posedge clk) begin
                if (rst) v_q[i] <= 1'b0;
                else v_q[i] <= v_q[i-1];
                s_q[i] <= nxt;
                e_q[i] <= e_q[i-1];
            end
        end
    endgenerate

    assign out_valid = v_q[10];
    assign dout = s_q[10];
endmodule
