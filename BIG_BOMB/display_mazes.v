module display_mazes(
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  current_state,
    input  wire [2:0]  cur_x,
    input  wire [2:0]  cur_y,
    input  wire [2:0]  final_x,
    input  wire [2:0]  final_y,
    input  wire        win,
    input  wire        fail,
    output wire        dout
);

    parameter ACTIVATED = 3'b010;

    // WS2812 pixel index
    wire [5:0] pixel_idx;
    wire [2:0] px = pixel_idx[2:0];
    wire [2:0] py = pixel_idx[5:3];

    reg [23:0] color_out;

    // =========================================================
    // dim 50% (Verilog-2001 寫法)
    // =========================================================
    function [23:0] dim50;
        input [23:0] c;
        begin
            dim50 = { (c[23:16] >> 1), (c[15:8] >> 1), (c[7:0] >> 1) };
        end
    endfunction

    // =========================================================
    // WIN: "ALL" / "PASS" 輪播（綠色，GRB）
    // =========================================================
    localparam [23:0] GREEN = 24'hFF0000; // GRB green
    localparam [23:0] OFF   = 24'h000000;

    reg [24:0] win_cnt;
    reg        win_page; // 0: ALL, 1: PASS

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            win_cnt  <= 25'd0;
            win_page <= 1'b0;
        end else if (win) begin
            // 0.6 秒切一次（50MHz）
            if (win_cnt >= 25'd30_000_000) begin
                win_cnt  <= 25'd0;
                win_page <= ~win_page;
            end else begin
                win_cnt <= win_cnt + 1'b1;
            end
        end else begin
            win_cnt  <= 25'd0;
            win_page <= 1'b0;
        end
    end

    // =========================================================
    // 更清楚的 8×8 點陣（bit7 是 x=0，bit0 是 x=7）
    //   ALL：左 4 欄是 A，右兩個 L 各 2 欄
    //   PASS：用更像字的簡化大寫
    // =========================================================
    function pix_on_all;
        input [2:0] x;
        input [2:0] y;
        reg   [7:0] row;
        begin
            case (y)
                3'd0: row = 8'h6A; // 0110 1010
                3'd1: row = 8'h9A; // 1001 1010
                3'd2: row = 8'hFA; // 1111 1010
                3'd3: row = 8'h9A; // 1001 1010
                3'd4: row = 8'h9A; // 1001 1010
                3'd5: row = 8'h9A; // 1001 1010
                3'd6: row = 8'h9F; // 1001 1111  (L 底線)
                default: row = 8'h00;
            endcase
            pix_on_all = row[7 - x];
        end
    endfunction

function pix_on_pass;
    input [2:0] x;
    input [2:0] y;
    reg   [7:0] row;
    begin
        case (y)
            // 這組會讓右邊的 "ass" 更明顯一點（用較寬的筆畫）
            3'd0: row = 8'b1110_1110; // P top + a/s/s top
            3'd1: row = 8'b1010_1001; // P side + a body (讓 a 出現)
            3'd2: row = 8'b1110_1110; // P mid + s bar
            3'd3: row = 8'b1001_1001; // P stem + s curve
            3'd4: row = 8'b1000_1110; // P stem + s bar（底收）
            3'd5: row = 8'b0000_0000;
            3'd6: row = 8'b0000_0000;
            default: row = 8'b0000_0000;
        endcase
        pix_on_pass = row[7 - x];
    end
endfunction

    // =========================================================
    // （保留）爆炸動畫 frame 控制：current_state==3'd3 時用
    // =========================================================
    reg [1:0]  boom_frame;
    reg [23:0] boom_cnt;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            boom_cnt   <= 24'd0;
            boom_frame <= 2'd0;
        end else if (current_state == 3'd3) begin
            if (boom_cnt >= 24'd6_000_000) begin
                boom_cnt   <= 24'd0;
                boom_frame <= boom_frame + 1'b1;
            end else begin
                boom_cnt <= boom_cnt + 1'b1;
            end
        end else begin
            boom_cnt   <= 24'd0;
            boom_frame <= 2'd0;
        end
    end

    // =========================================================
    // 顏色決策（優先順序：WIN文字 > 爆炸 > 遊戲中 > 黑）
    // =========================================================
    always @(*) begin
        // ===== WIN：只顯示 ALL PASS（綠色、亮度降一半）=====
        if (win) begin
            if (!win_page)
                color_out = pix_on_all(px, py)  ? dim50(GREEN) : OFF;
            else
                color_out = pix_on_pass(px, py) ? dim50(GREEN) : OFF;
        end

        // ===== 爆炸動畫（也降亮度一半；GRB 已正確）=====
        else if (current_state == 3'd3) begin
            case (boom_frame)
                2'd0: color_out =
                    (px >= 3 && px <= 4 && py >= 3 && py <= 4) ?
                    dim50(24'hFFFF00) : OFF;

                2'd1: color_out =
                    ((px >= 2 && px <= 5 && py >= 2 && py <= 5)) ?
                    ((px >= 3 && px <= 4 && py >= 3 && py <= 4) ?
                     dim50(24'hFFFFFF) : dim50(24'hAAFF00)) :
                    OFF;

                2'd2: color_out =
                    ((px >= 1 && px <= 6 && py >= 1 && py <= 6)) ?
                    ((px >= 3 && px <= 4 && py >= 3 && py <= 4) ?
                     dim50(24'hFFFFFF) : dim50(24'h33FF00)) :
                    OFF;

                default: color_out =
                    (px >= 2 && px <= 5 && py >= 2 && py <= 5) ?
                    dim50(24'h88AA00) : OFF;
            endcase
        end

        // ===== 遊戲中顯示（全都降亮度一半）=====
        else if (current_state == ACTIVATED) begin
            if (px == cur_x && py == cur_y)
                color_out = dim50(24'h111111);      // 玩家：灰白(降一半後還看得到)
            else if (px == final_x && py == final_y)
                color_out = dim50(24'h110000);      // 終點：綠 (GRB)
            else if (px == 3'd0 || px == 3'd7 || py == 3'd0 || py == 3'd7)
                color_out = dim50(24'h001015);      // 外圍牆：降一半
            else
                color_out = OFF;
        end else begin
            color_out = OFF;
        end
    end

    // =========================================================
    // WS2812 driver
    // =========================================================
    ws2812_driver w1 (
        .clk   (clk),
        .rst   (rst),
        .color (color_out),
        .pixel (pixel_idx),
        .dout  (dout)
    );

endmodule
