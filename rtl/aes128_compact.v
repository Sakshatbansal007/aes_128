module aes128_compact(
    input clk,
    input rst,
    input start,
    input enc,
    input [127:0] key,
    input [127:0] din,
    output [127:0] dout,
    output reg done
);
    localparam IDLE = 3'd0, KFWD = 3'd1, INIT = 3'd2, KSTEP = 3'd3,
               COLS = 3'd4, DONE = 3'd5;

    reg [2:0] st;
    reg [3:0] cnt;
    reg [1:0] col;
    reg [127:0] S;
    reg [127:0] K;
    reg enc_q;

    assign dout = S;

    wire [3:0] rc_idx = (st == KFWD) ? cnt :
                        enc_q ? (cnt - 4'd1) : (4'd10 - cnt);
    reg [7:0] rcon;
    always @(*) begin
        case (rc_idx)
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

    wire [31:0] w0 = K[127:96];
    wire [31:0] w1 = K[95:64];
    wire [31:0] w2 = K[63:32];
    wire [31:0] w3 = K[31:0];

    wire inv_key = (st == KSTEP) && !enc_q;
    wire [31:0] kw3 = inv_key ? (w3 ^ w2) : w3;
    wire [31:0] k_rot = {kw3[23:0], kw3[31:24]};

    wire [31:0] col_in = S[(3 - col) * 32 +: 32];
    wire [31:0] fs_in = (st == COLS) ? col_in : k_rot;
    wire [31:0] fs_out;
    sbox fs0(.in(fs_in[31:24]), .out(fs_out[31:24]));
    sbox fs1(.in(fs_in[23:16]), .out(fs_out[23:16]));
    sbox fs2(.in(fs_in[15:8]), .out(fs_out[15:8]));
    sbox fs3(.in(fs_in[7:0]), .out(fs_out[7:0]));

    wire [31:0] is_out;
    inv_sbox is0(.in(col_in[31:24]), .out(is_out[31:24]));
    inv_sbox is1(.in(col_in[23:16]), .out(is_out[23:16]));
    inv_sbox is2(.in(col_in[15:8]), .out(is_out[15:8]));
    inv_sbox is3(.in(col_in[7:0]), .out(is_out[7:0]));

    wire [31:0] f0 = w0 ^ fs_out ^ {rcon, 24'h0};
    wire [31:0] f1 = w1 ^ f0;
    wire [31:0] f2 = w2 ^ f1;
    wire [31:0] f3 = w3 ^ f2;
    wire [127:0] k_fwd = {f0, f1, f2, f3};

    wire [31:0] p3 = w3 ^ w2;
    wire [31:0] p2 = w2 ^ w1;
    wire [31:0] p1 = w1 ^ w0;
    wire [31:0] p0 = w0 ^ fs_out ^ {rcon, 24'h0};
    wire [127:0] k_inv = {p0, p1, p2, p3};

    wire [127:0] sr_out, isr_out;
    shift_rows u_sr (.in(S), .out(sr_out));
    inv_shift_rows u_isr(.in(S), .out(isr_out));

    wire [31:0] rk_col = K[(3 - col) * 32 +: 32];
    wire [127:0] mc_wide, imc_wide;
    wire [31:0] e_x = fs_out;
    wire [31:0] d_x = is_out ^ rk_col;
    mix_columns u_mc (.in({4{e_x}}), .out(mc_wide));
    inv_mix_columns u_imc(.in({4{d_x}}), .out(imc_wide));

    wire [31:0] e_col = ((cnt == 4'd10) ? e_x : mc_wide[127:96]) ^ rk_col;
    wire [31:0] d_col = (cnt == 4'd10) ? d_x : imc_wide[127:96];
    wire [31:0] new_col = enc_q ? e_col : d_col;

    always @(posedge clk) begin
        if (rst) begin
            st <= IDLE;
            done <= 1'b0;
            cnt <= 4'd0;
            col <= 2'd0;
            S <= 128'h0;
            K <= 128'h0;
            enc_q <= 1'b1;
        end else begin
            done <= 1'b0;
            case (st)
                IDLE: if (start) begin
                    K <= key;
                    S <= din;
                    enc_q <= enc;
                    cnt <= 4'd0;
                    st <= enc ? INIT : KFWD;
                end
                KFWD: begin
                    K <= k_fwd;
                    cnt <= cnt + 4'd1;
                    if (cnt == 4'd9) st <= INIT;
                end
                INIT: begin
                    S <= S ^ K;
                    cnt <= 4'd1;
                    st <= KSTEP;
                end
                KSTEP: begin
                    S <= enc_q ? sr_out : isr_out;
                    K <= enc_q ? k_fwd : k_inv;
                    col <= 2'd0;
                    st <= COLS;
                end
                COLS: begin
                    S[(3 - col) * 32 +: 32] <= new_col;
                    col <= col + 2'd1;
                    if (col == 2'd3) begin
                        if (cnt == 4'd10) st <= DONE;
                        else begin cnt <= cnt + 4'd1;
                        st <= KSTEP;
                        end
                    end
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
