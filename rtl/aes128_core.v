module aes128_core(
    input clk,
    input rst,
    input start,
    input enc,
    input [127:0] key,
    input [127:0] din,
    output [127:0] dout,
    output reg done
);
    localparam IDLE = 3'd0, KEYEXP = 3'd1, INIT = 3'd2, ROUNDS = 3'd3, DONE = 3'd4;

    reg [2:0] st;
    reg [3:0] cnt;
    reg [127:0] rk [0:10];
    reg [127:0] state;
    reg [127:0] data_q;
    reg enc_q;

    assign dout = state;

    reg [7:0] rcon;
    always @(*) begin
        case (cnt)
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

    wire [127:0] next_rk;
    key_expand_round ke(.key_in(rk[cnt]), .rcon(rcon), .key_out(next_rk));

    wire [127:0] e_sub, e_shift, e_mix;
    sub_bytes u_sb (.in(state), .out(e_sub));
    shift_rows u_sr (.in(e_sub), .out(e_shift));
    mix_columns u_mc (.in(e_shift), .out(e_mix));
    wire [127:0] enc_next = ((cnt == 4'd10) ? e_shift : e_mix) ^ rk[cnt];

    wire [127:0] d_shift, d_sub, d_mix;
    inv_shift_rows u_isr (.in(state), .out(d_shift));
    inv_sub_bytes u_isb (.in(d_shift), .out(d_sub));
    wire [127:0] d_ark = d_sub ^ rk[4'd10 - cnt];
    inv_mix_columns u_imc (.in(d_ark), .out(d_mix));
    wire [127:0] dec_next = (cnt == 4'd10) ? d_ark : d_mix;

    always @(posedge clk) begin
        if (rst) begin
            st <= IDLE;
            done <= 1'b0;
            cnt <= 4'd0;
            state <= 128'h0;
        end else begin
            done <= 1'b0;
            case (st)
                IDLE: if (start) begin
                    rk[0] <= key;
                    data_q <= din;
                    enc_q <= enc;
                    cnt <= 4'd0;
                    st <= KEYEXP;
                end
                KEYEXP: begin
                    rk[cnt + 4'd1] <= next_rk;
                    if (cnt == 4'd9) st <= INIT;
                    cnt <= cnt + 4'd1;
                end
                INIT: begin
                    state <= data_q ^ (enc_q ? rk[0] : rk[10]);
                    cnt <= 4'd1;
                    st <= ROUNDS;
                end
                ROUNDS: begin
                    state <= enc_q ? enc_next : dec_next;
                    if (cnt == 4'd10) st <= DONE;
                    cnt <= cnt + 4'd1;
                end
                DONE: begin
                    done <= 1'b1;
                    st <= IDLE;
                end
                default: st <= IDLE;
            endcase
        end
    end
endmodule
