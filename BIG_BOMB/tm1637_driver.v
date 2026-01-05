// ======================================================
// Module: tm1637_driver
// Description: TM1637 4-Digit 7-Segment Display Driver
// Target: DE10-Lite (Intel MAX 10) or any FPGA
// ======================================================

module tm1637_driver (
    input            clk,      // 50MHz Clock
    input            rst_n,    // Active Low Reset
    input      [2:0] n1,       // Digit 1 (1-4)
    input      [2:0] n2,       // Digit 2 (1-4)
    input      [2:0] n3,       // Digit 3 (1-4)
    input      [2:0] n4,       // Digit 4 (1-4)
    input      [2:0] current_stage,
    output reg       tm_clk,   // Pin to TM1637 CLK
    inout            tm_dio    // Pin to TM1637 DIO (Bidirectional)
);

    // --- 三態緩衝器設定 (Tri-state Buffer) ---
    reg  dio_out;
    reg  dio_oe; // 1: Output, 0: Input (High-Z)
    assign tm_dio = dio_oe ? dio_out : 1'bz;

    // --- 分頻器: 產生約 100kHz 操作頻率 ---
    reg [9:0] clk_div;
    reg       slow_tick;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 0;
            slow_tick <= 0;
        end
        else if (clk_div == 10'd500)begin 
            clk_div <= 0;
            slow_tick <= 1;
        end
        else begin 
            clk_div <= clk_div + 1;
            slow_tick <= 0;
        end
    end


    // --- 七段碼解碼器 (LSB First: 0b[DP]GFEDCBA) ---
    function [6:0] to_7seg;
        input [2:0] val;
        
        case(val)
            3'd1: to_7seg = 7'b000_0110; // "1"
            3'd2: to_7seg = 7'b101_1011; // "2"
            3'd3: to_7seg = 7'b100_1111; // "3"
            3'd4: to_7seg = 7'b110_0110; // "4"
            default: to_7seg = 7'b000_0000; // 不顯示 (全滅)
        endcase
    endfunction

    // --- 狀態機參數 ---
    reg [5:0] state;
    reg [7:0] send_data;
    reg [3:0] bit_cnt;
    reg [2:0] step_cnt;

    // TM1637 指令
    localparam CMD_SET_DATA = 8'h40; // 自動位址增加
    localparam CMD_SET_ADDR = 8'hC0; // 從第一位開始
    localparam CMD_DISPLAY  = 8'h88; // 開啟顯示, 亮度最低

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0; tm_clk <= 1; dio_out <= 1; dio_oe <= 1;
            bit_cnt <= 0; step_cnt <= 0;
        end else if (slow_tick) begin
            case (state)
                // --- Step 1: 發送數據模式指令 (0x40) ---
                0: begin dio_oe <= 1; dio_out <= 0; state <= 1; end // START 當clk是高電位然後DIO變低電位就知道通訊開始
                1: begin tm_clk <= 0; send_data <= CMD_SET_DATA; state <= 2; end
                2: begin // 發送 8-bit
                    dio_out <= send_data[0]; 
                    state <= 3; 
                end
                3: begin tm_clk <= 1; state <= 4; end
                4: begin 
                    tm_clk <= 0; 
                    if (bit_cnt < 7) begin
                        send_data <= send_data >> 1;
                        bit_cnt <= bit_cnt + 1;
                        state <= 2;
                    end else begin
                        bit_cnt <= 0;
                        state <= 5; // ACK
                    end
                end
                5: begin dio_oe <= 0; state <= 6; end // Wait ACK
                6: begin tm_clk <= 1; state <= 7; end
                7: begin tm_clk <= 0; dio_oe <= 1; state <= 8; end // STOP
                8: begin tm_clk <= 1; state <= 9; end
                9: begin dio_out <= 1; state <= 10; end 

                // --- Step 2: 發送位址指令 (0xC0) 與 4 位數據 ---
                10: begin dio_out <= 0; state <= 11; end // START
                11: begin tm_clk <= 0; send_data <= CMD_SET_ADDR; state <= 12; end
                12: begin // 發送 Byte (重複邏輯)
                    dio_out <= send_data[0]; state <= 13;
                end
                13: begin tm_clk <= 1; state <= 14; end
                14: begin
                    tm_clk <= 0;
                    if (bit_cnt < 7) begin
                        send_data <= send_data >> 1;
                        bit_cnt <= bit_cnt + 1;
                        state <= 12;
                    end else begin
                        bit_cnt <= 0; state <= 15; // ACK
                    end
                end
                15: begin dio_oe <= 0; state <= 16; end // ACK
                16: begin tm_clk <= 1; state <= 17; end
                17: begin 
                    tm_clk <= 0; dio_oe <= 1; 
                    // 根據 step_cnt 決定下一個數據
                    case (step_cnt)
                        0: begin send_data <= to_7seg(n1); step_cnt <= 1; state <= 12; end
                        1: begin send_data <= {1'd0,to_7seg(n2)}; step_cnt <= 2; state <= 12; end
                        2: begin send_data <= to_7seg(n3); step_cnt <= 3; state <= 12; end
                        3: begin send_data <= to_7seg(n4); step_cnt <= 4; state <= 12; end
                        4: begin step_cnt <= 0; state <= 18; end // 結束數據發送
                    endcase
                end
                18: begin dio_out <= 0; state <= 19; end // STOP
                19: begin tm_clk <= 1; state <= 20; end
                20: begin dio_out <= 1; state <= 21; end

                // --- Step 3: 發送控制指令 (0x88) 開啟顯示 ---
                21: begin dio_out <= 0; state <= 22; end // START
                22: begin tm_clk <= 0; send_data <= CMD_DISPLAY; state <= 23; end
                23: begin // 發送 Byte
                    dio_out <= send_data[0]; state <= 24;
                end
                24: begin tm_clk <= 1; state <= 25; end
                25: begin
                    tm_clk <= 0;
                    if (bit_cnt < 7) begin
                        send_data <= send_data >> 1;
                        bit_cnt <= bit_cnt + 1;
                        state <= 23;
                    end else begin
                        bit_cnt <= 0; state <= 26; // ACK
                    end
                end
                26: begin dio_oe <= 0; state <= 27; end // ACK
                27: begin tm_clk <= 1; state <= 28; end
                28: begin tm_clk <= 0; dio_oe <= 1; state <= 29; end // STOP
                29: begin dio_out <= 0; state <= 30; end
                30: begin tm_clk <= 1; state <= 31; end
                31: begin dio_out <= 1; state <= 0; end // 完成循環，回頭重整

                default: state <= 0;
            endcase
        end
    end

endmodule