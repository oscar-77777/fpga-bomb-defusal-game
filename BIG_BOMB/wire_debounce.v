module wire_debounce #(
    parameter integer CLK_HZ = 50_000_000,
    parameter integer STABLE_MS = 2               // 需要穩定幾毫秒才承認
)(
    input  wire       clk,
    input  wire       rst,        // active-low
    input  wire [5:0] wire_in,    // 原始外部線訊號
    output reg  [5:0] wire_out    // 濾波後穩定訊號（level）
);
    // 計算需要穩定多少個 clock
    localparam integer STABLE_CYCLES = (CLK_HZ/1000) * STABLE_MS;

    // 兩級同步
    reg [5:0] in_ff1, in_ff2;

    // 每一條線一個 counter
    integer i;
    reg [$clog2(STABLE_CYCLES+1)-1:0] cnt [0:5];

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            in_ff1   <= 6'b0;
            in_ff2   <= 6'b0;
            wire_out <= 6'b0;
            for (i=0; i<6; i=i+1) begin
                cnt[i] <= 'd0;
            end
        end else begin
            // sync
            in_ff1 <= wire_in;
            in_ff2 <= in_ff1;

            // filter per bit
            for (i=0; i<6; i=i+1) begin
                if (in_ff2[i] == wire_out[i]) begin
                    // 已經一致 -> 不用更新，counter 歸零
                    cnt[i] <= 'd0;
                end else begin
                    // 想改變 -> 需要連續穩定 STABLE_CYCLES 才接受
                    if (cnt[i] < STABLE_CYCLES-1) begin
                        cnt[i] <= cnt[i] + 1'b1;
                    end else begin
                        wire_out[i] <= in_ff2[i];
                        cnt[i] <= 'd0;
                    end
                end
            end
        end
    end
endmodule
