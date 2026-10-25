`ifndef MODES_CORE
`define MODES_CORE aes128_core
`endif
module aes_modes(
    input clk,
    input rst,
    input mode,
    input dec,
    input init,
    input [127:0] key,
    input [127:0] iv,
    input blk_start,
    input [127:0] din,
    output reg [127:0] dout,
    output reg blk_done,
    output busy
);
    localparam W_IDLE = 1'b0, W_RUN = 1'b1;

    reg wst;
    reg [127:0] key_q;
    reg [127:0] chain;
    reg [127:0] in_q;
    reg mode_q, dec_q;

    reg c_start;
    reg c_enc;
    reg [127:0] c_din;
    wire [127:0] c_dout;
    wire c_done;

    `MODES_CORE core(.clk(clk), .rst(rst), .start(c_start), .enc(c_enc),
                     .key(key_q), .din(c_din), .dout(c_dout), .done(c_done));

    assign busy = (wst == W_RUN);

    always @(posedge clk) begin
        if (rst) begin
            wst <= W_IDLE;
            c_start <= 1'b0;
            blk_done <= 1'b0;
            key_q <= 128'h0;
            chain <= 128'h0;
            in_q <= 128'h0;
            mode_q <= 1'b0;
            dec_q <= 1'b0;
            c_enc <= 1'b1;
            c_din <= 128'h0;
            dout <= 128'h0;
        end else begin
            c_start <= 1'b0;
            blk_done <= 1'b0;
            case (wst)
                W_IDLE: begin
                    if (init) begin
                        key_q <= key;
                        chain <= iv;
                    end else if (blk_start) begin
                        in_q <= din;
                        mode_q <= mode;
                        dec_q <= dec;
                        if (mode) begin
                            c_enc <= 1'b1;
                            c_din <= chain;
                        end else if (dec) begin
                            c_enc <= 1'b0;
                            c_din <= din;
                        end else begin
                            c_enc <= 1'b1;
                            c_din <= din ^ chain;
                        end
                        c_start <= 1'b1;
                        wst <= W_RUN;
                    end
                end
                W_RUN: begin
                    if (c_done) begin
                        if (mode_q) begin
                            dout <= in_q ^ c_dout;
                            chain <= chain + 128'd1;
                        end else if (dec_q) begin
                            dout <= c_dout ^ chain;
                            chain <= in_q;
                        end else begin
                            dout <= c_dout;
                            chain <= c_dout;
                        end
                        blk_done <= 1'b1;
                        wst <= W_IDLE;
                    end
                end
            endcase
        end
    end
endmodule
