// 輸入低兩位數字
// 例如：3.505 MHz → 05, 3.515 MHz → 15, 3.600 MHz → 100


module Morse_Code (
    //==================================================
    // Top level inputs (interface)
    //==================================================
    input rst,                      // 非同步負緣 reset
    input clk,                      // 系統時鐘 (假設 50MHz)
    input [2:0] current_state,

    input [31:0] rnd,
    output reg activated,           // latch signal - 初始化完成
    output reg module_failed,       // pulse signal - 答錯
    output reg module_solved,       // latch signal - 答對
    
    //==================================================
    // 頻率編碼輸入 (由外部 ADC 處理模組轉換後傳入)
    // 編碼方式：取頻率小數點後第二、三位
    // 例如：3.505 MHz → 05, 3.515 MHz → 15, 3.600 MHz → 100
    //==================================================
    input [6:0] freq_code,          // 頻率編碼 (0-100)
    
    //==================================================
    // 按鈕輸入 (active high, 經過除彈跳)
    //==================================================
    input btn_submit,               // 提交按鈕
    
    //==================================================
    // 摩斯密碼輸出
    //==================================================
    output reg led_morse,           // LED 輸出 (閃爍摩斯密碼)
    output reg buzzer,              // 蜂鳴器輸出 (與 LED 同步)
    
    output [7:0] display_char_0, // MSB
    output [7:0] display_char_1,
    output [7:0] display_char_2 // LSB
);

    //==================================================
    // Top level states
    //==================================================
    localparam IDLE      = 3'b000;
    localparam ATIVATING = 3'b001;  // 讀取亂數 rnd 生成關卡
    localparam ATIVATED  = 3'b010;  // 開始拆炸彈
    
    //==================================================
    // 參數定義
    //==================================================
    localparam NUM_WORDS = 16;      // 16 個單詞
    
    // 時序參數 (50MHz 時鐘)
    // 一單位 t = 0.1 秒 = 5,000,000 cycles
    localparam TIME_UNIT        = 27'd5_000_000;
    localparam DOT_DURATION     = TIME_UNIT;    // 點: 1t = 0.1 秒
    localparam DASH_DURATION    = TIME_UNIT * 3;   // 劃: 3t = 0.3 秒
    localparam SYMBOL_GAP       = TIME_UNIT;    // 點與劃之間: 1t = 0.1 秒
    localparam LETTER_GAP       = TIME_UNIT * 3;   // 字元間隔: 3t = 0.3 秒
    localparam WORD_GAP         = TIME_UNIT * 7;   // 單詞間隔: 7t = 0.7 秒
    
    //==================================================
    // frequency code display
    //==================================================
    wire [7:0] freq_code_hundreds = freq_code / 100;
    wire [7:0] freq_code_tens = (freq_code % 100) / 10;
    wire [7:0] freq_code_ones = freq_code % 10;

    assign display_char_0 = 8'd48 + freq_code_hundreds + 8'd5;
    assign display_char_1 = 8'd48 + freq_code_tens;
    assign display_char_2 = 8'd48 + freq_code_ones;
    
    //==================================================
    // 單詞表 - 共 16 個單詞
    // 每個單詞最多 6 個字母，每個字母用 5 bits 表示 (0-25 = a-z)
    // 格式: {len[2:0], char5, char4, char3, char2, char1, char0}
    // len = 單詞長度 (5 或 6)
    //==================================================
    reg [3:0] target_word_idx;      // 目標單詞索引 (0-15), 同時選擇目標頻率編碼
    reg [32:0] word_data;           // 3-bit len + 6 letters * 5 bits = 33 bits
    
    // 從 rnd 決定目標單詞，或使用查表
    wire [3:0] word_lookup_idx = target_word_idx;
    
    always @(*) begin
        case (word_lookup_idx)
            // {長度, char5, char4, char3, char2, char1, char0}
            4'd0:  word_data = {3'd5, 5'd0,  5'd11, 5'd11, 5'd4,  5'd7,  5'd18}; // shell
            4'd1:  word_data = {3'd5, 5'd0,  5'd18, 5'd11, 5'd11, 5'd0,  5'd7};  // halls
            4'd2:  word_data = {3'd5, 5'd0,  5'd10, 5'd2,  5'd8,  5'd11, 5'd18}; // slick
            4'd3:  word_data = {3'd5, 5'd0,  5'd10, 5'd2,  5'd8,  5'd17, 5'd19}; // trick
            4'd4:  word_data = {3'd5, 5'd0,  5'd18, 5'd4,  5'd23, 5'd14, 5'd1};  // boxes
            4'd5:  word_data = {3'd5, 5'd0,  5'd18, 5'd10, 5'd0,  5'd4,  5'd11}; // leaks
            4'd6:  word_data = {3'd6, 5'd4,  5'd1,  5'd14, 5'd17, 5'd19, 5'd18}; // strobe
            4'd7:  word_data = {3'd6, 5'd14, 5'd17, 5'd19, 5'd18, 5'd8,  5'd1};  // bistro
            4'd8:  word_data = {3'd5, 5'd0,  5'd10, 5'd2,  5'd8,  5'd11, 5'd5};  // flick
            4'd9:  word_data = {3'd5, 5'd0,  5'd18, 5'd1,  5'd12, 5'd14, 5'd1};  // bombs
            4'd10: word_data = {3'd5, 5'd0,  5'd10, 5'd0,  5'd4,  5'd17, 5'd1};  // break
            4'd11: word_data = {3'd5, 5'd0,  5'd10, 5'd2,  5'd8,  5'd17, 5'd1};  // brick
            4'd12: word_data = {3'd5, 5'd0,  5'd10, 5'd0,  5'd4,  5'd19, 5'd18}; // steak
            4'd13: word_data = {3'd5, 5'd0,  5'd6,  5'd13, 5'd8,  5'd19, 5'd18}; // sting
            4'd14: word_data = {3'd6, 5'd17, 5'd14, 5'd19, 5'd2,  5'd4,  5'd21}; // vector
            4'd15: word_data = {3'd5, 5'd0,  5'd18, 5'd19, 5'd0,  5'd4,  5'd1};  // beats
            default: word_data = {3'd5, 5'd0, 5'd11, 5'd11, 5'd4,  5'd7,  5'd18}; // shell
        endcase
    end
    
    wire [2:0] word_length = word_data[32:30];
    wire [4:0] word_char_0 = word_data[4:0];
    wire [4:0] word_char_1 = word_data[9:5];
    wire [4:0] word_char_2 = word_data[14:10];
    wire [4:0] word_char_3 = word_data[19:15];
    wire [4:0] word_char_4 = word_data[24:20];
    wire [4:0] word_char_5 = word_data[29:25];
    
    //==================================================
    // 頻率編碼對照表 (單詞索引 -> 頻率編碼)
    // 編碼方式：取頻率小數點後第二、三位
    // 例如：3.505 MHz → 05, 3.515 MHz → 15, 3.600 MHz → 100
    //==================================================
    reg [6:0] target_freq_code;
    
    always @(*) begin
        case (target_word_idx)
            4'd0:  target_freq_code = 7'd05;    // shell:  3.505 MHz → 05
            4'd1:  target_freq_code = 7'd15;    // halls:  3.515 MHz → 15
            4'd2:  target_freq_code = 7'd22;    // slick:  3.522 MHz → 22
            4'd3:  target_freq_code = 7'd32;    // trick:  3.532 MHz → 32
            4'd4:  target_freq_code = 7'd35;    // boxes:  3.535 MHz → 35
            4'd5:  target_freq_code = 7'd42;    // leaks:  3.542 MHz → 42
            4'd6:  target_freq_code = 7'd45;    // strobe: 3.545 MHz → 45
            4'd7:  target_freq_code = 7'd52;    // bistro: 3.552 MHz → 52
            4'd8:  target_freq_code = 7'd55;    // flick:  3.555 MHz → 55
            4'd9:  target_freq_code = 7'd65;    // bombs:  3.565 MHz → 65
            4'd10: target_freq_code = 7'd72;    // break:  3.572 MHz → 72
            4'd11: target_freq_code = 7'd75;    // brick:  3.575 MHz → 75
            4'd12: target_freq_code = 7'd82;    // steak:  3.582 MHz → 82
            4'd13: target_freq_code = 7'd92;    // sting:  3.592 MHz → 92
            4'd14: target_freq_code = 7'd95;    // vector: 3.595 MHz → 95
            4'd15: target_freq_code = 7'd100;   // beats:  3.600 MHz → 100
            default: target_freq_code = 7'd05;
        endcase
    end
    
    //==================================================
    // 摩斯密碼對照表
    // 每個字母用 8 bits 表示: {長度[2:0], 符號[4:0]}
    // 符號: 0 = dot (●), 1 = dash (■), 從低位開始讀取
    //==================================================
    reg [7:0] morse_lookup;
    
    always @(*) begin
        // {長度, 符號} - 符號從 bit0 開始，0=dot, 1=dash
        case (current_letter)
            5'd0:  morse_lookup = {3'd2, 5'b00010};  // A: ●■
            5'd1:  morse_lookup = {3'd4, 5'b00001};  // B: ■●●●
            5'd2:  morse_lookup = {3'd4, 5'b00101};  // C: ■●■●
            5'd3:  morse_lookup = {3'd3, 5'b00001};  // D: ■●●
            5'd4:  morse_lookup = {3'd1, 5'b00000};  // E: ●
            5'd5:  morse_lookup = {3'd4, 5'b00100};  // F: ●●■●
            5'd6:  morse_lookup = {3'd3, 5'b00011};  // G: ■■●
            5'd7:  morse_lookup = {3'd4, 5'b00000};  // H: ●●●●
            5'd8:  morse_lookup = {3'd2, 5'b00000};  // I: ●●
            5'd9:  morse_lookup = {3'd4, 5'b01110};  // J: ●■■■
            5'd10: morse_lookup = {3'd3, 5'b00101};  // K: ■●■
            5'd11: morse_lookup = {3'd4, 5'b00010};  // L: ●■●●
            5'd12: morse_lookup = {3'd2, 5'b00011};  // M: ■■
            5'd13: morse_lookup = {3'd2, 5'b00001};  // N: ■●
            5'd14: morse_lookup = {3'd3, 5'b00111};  // O: ■■■
            5'd15: morse_lookup = {3'd4, 5'b00110};  // P: ●■■●
            5'd16: morse_lookup = {3'd4, 5'b01011};  // Q: ■■●■
            5'd17: morse_lookup = {3'd3, 5'b00010};  // R: ●■●
            5'd18: morse_lookup = {3'd3, 5'b00000};  // S: ●●●
            5'd19: morse_lookup = {3'd1, 5'b00001};  // T: ■
            5'd20: morse_lookup = {3'd3, 5'b00100};  // U: ●●■
            5'd21: morse_lookup = {3'd4, 5'b01000};  // V: ●●●■
            5'd22: morse_lookup = {3'd3, 5'b00110};  // W: ●■■
            5'd23: morse_lookup = {3'd4, 5'b01001};  // X: ■●●■
            5'd24: morse_lookup = {3'd4, 5'b01101};  // Y: ■●■■
            5'd25: morse_lookup = {3'd4, 5'b00011};  // Z: ■■●●
            default: morse_lookup = {3'd1, 5'b00000}; // 預設為 E
        endcase
    end
    
    //==================================================
    // 摩斯密碼播放狀態機
    //==================================================
    localparam MORSE_IDLE        = 3'd0;
    localparam MORSE_LOAD_LETTER = 3'd1;  // 載入新字母的摩斯密碼
    localparam MORSE_SYMBOL_ON   = 3'd2;  // 輸出符號 (LED/蜂鳴器 ON)
    localparam MORSE_SYMBOL_GAP  = 3'd3;  // 符號間隔
    localparam MORSE_LETTER_GAP  = 3'd4;  // 字母間隔
    localparam MORSE_WORD_GAP    = 3'd5;  // 單詞循環間隔
    
    reg [2:0] morse_state;
    reg [26:0] morse_timer;             // 計時器
    reg [2:0] current_letter_idx;       // 當前字母索引 (0-5)
    reg [2:0] current_symbol_idx;       // 當前符號索引 (0-4)
    reg [4:0] current_letter;           // 當前字母 (0-25)
    reg [7:0] current_morse;            // 當前字母的摩斯密碼
    reg [2:0] current_morse_len;        // 當前字母的摩斯密碼長度
    
    // 獲取當前字母
    always @(*) begin
        case (current_letter_idx)
            3'd0: current_letter = word_char_0;
            3'd1: current_letter = word_char_1;
            3'd2: current_letter = word_char_2;
            3'd3: current_letter = word_char_3;
            3'd4: current_letter = word_char_4;
            3'd5: current_letter = word_char_5;
            default: current_letter = 5'd0;
        endcase
    end
    
    //==================================================
    // 按鈕邊緣偵測
    //==================================================
    reg btn_submit_prev;
    
    wire btn_submit_edge = btn_submit & ~btn_submit_prev;
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            btn_submit_prev <= 1'b0;
        end else begin
            btn_submit_prev <= btn_submit;
        end
    end
    
    //==================================================
    // 比對：當前輸入的頻率編碼是否等於目標單詞對應的頻率編碼
    //==================================================
    wire match = (freq_code == target_freq_code);
    
    //==================================================
    // 主要邏輯
    //==================================================
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // 非同步負緣 reset
            activated     <= 1'b0;
            module_failed <= 1'b0;
            module_solved <= 1'b0;
            
            target_word_idx <= 4'd0;
            
            // 摩斯密碼播放狀態
            morse_state        <= MORSE_IDLE;
            morse_timer        <= 27'd0;
            current_letter_idx <= 3'd0;
            current_symbol_idx <= 3'd0;
            current_morse      <= 8'd0;
            current_morse_len  <= 3'd0;
            
            led_morse <= 1'b0;
            buzzer    <= 1'b0;
            
        end else begin
            
            case (current_state)
                
                IDLE: begin
                    activated     <= 1'b0;
                    module_failed <= 1'b0;
                    module_solved <= 1'b0;
                    
                    // 重置摩斯密碼狀態
                    morse_state        <= MORSE_IDLE;
                    morse_timer        <= 27'd0;
                    current_letter_idx <= 3'd0;
                    current_symbol_idx <= 3'd0;
                    
                    led_morse <= 1'b0;
                    buzzer    <= 1'b0;
                end
                
                ATIVATING: begin
                    module_solved <= 1'b0;
                    module_failed <= 1'b0;
                    
                    // 只有尚未 activated 時才選擇目標單詞，選完後鎖定
                    if (!activated) begin
                        // 從亂數選擇目標單詞 (只執行一次)
                        target_word_idx <= rnd[3:0];  // 0-15 
                        
                        // 準備開始播放摩斯密碼
                        morse_state        <= MORSE_IDLE;
                        morse_timer        <= 27'd0;
                        current_letter_idx <= 3'd0;
                        current_symbol_idx <= 3'd0;
                        
                        led_morse <= 1'b0;
                        buzzer    <= 1'b0;
                        
                        // 初始化完成，拉高 activated (之後就不會再進入此 if)
                        activated <= 1'b1;
                    end
                    // activated 已拉高後，target_word_idx 保持不變
                end
                
                ATIVATED: begin
                    // 放下 activated
                    activated <= 1'b0;
                    
                    // 如果已解鎖，保持狀態並停止播放
                    if (module_solved) begin
                        module_solved <= 1'b1;
                        module_failed <= 1'b0;
                        led_morse     <= 1'b0;
                        buzzer        <= 1'b0;
                    end else begin
                        // 放下 module_failed (只維持一個 clk)
                        module_failed <= 1'b0;
                        
                        //==============================================
                        // 處理提交按鈕
                        //==============================================
                        if (btn_submit_edge) begin
                            if (match) begin
                                module_solved <= 1'b1;
                                module_failed <= 1'b0;
                            end else begin
                                module_solved <= 1'b0;
                                module_failed <= 1'b1;
                            end
                        end
                        
                        //==============================================
                        // 摩斯密碼播放狀態機
                        //==============================================
                        case (morse_state)
                            
                            MORSE_IDLE: begin
                                // 開始播放：先設定第一個字母的索引
                                current_letter_idx <= 3'd0;
                                current_symbol_idx <= 3'd0;
                                morse_timer        <= 27'd0;
                                morse_state        <= MORSE_LOAD_LETTER;
                                led_morse          <= 1'b0;
                                buzzer             <= 1'b0;
                            end
                            
                            MORSE_LOAD_LETTER: begin
                                // 載入當前字母的摩斯密碼
                                // 此時 current_letter 已經是正確的值，morse_lookup 也已更新
                                current_morse     <= morse_lookup;
                                current_morse_len <= morse_lookup[7:5];
                                morse_state       <= MORSE_SYMBOL_ON;
                                morse_timer       <= 27'd0;
                                led_morse         <= 1'b1;
                                buzzer            <= 1'b1;
                            end
                            
                            MORSE_SYMBOL_ON: begin
                                // 輸出當前符號
                                led_morse <= 1'b1;
                                buzzer    <= 1'b1;
                                
                                // 計算當前符號是 dot 還是 dash
                                // dash duration: 3 units, dot duration: 1 unit
                                if (current_morse[current_symbol_idx]) begin
                                    // Dash (■)
                                    if (morse_timer >= DASH_DURATION - 1) begin
                                        morse_timer <= 27'd0;
                                        morse_state <= MORSE_SYMBOL_GAP;
                                        led_morse   <= 1'b0;
                                        buzzer      <= 1'b0;
                                    end else begin
                                        morse_timer <= morse_timer + 27'd1;
                                    end
                                end else begin
                                    // Dot (●)
                                    if (morse_timer >= DOT_DURATION - 1) begin
                                        morse_timer <= 27'd0;
                                        morse_state <= MORSE_SYMBOL_GAP;
                                        led_morse   <= 1'b0;
                                        buzzer      <= 1'b0;
                                    end else begin
                                        morse_timer <= morse_timer + 27'd1;
                                    end
                                end
                            end
                            
                            MORSE_SYMBOL_GAP: begin
                                // 符號間隔
                                led_morse <= 1'b0;
                                buzzer    <= 1'b0;
                                
                                if (morse_timer >= SYMBOL_GAP - 1) begin
                                    morse_timer <= 27'd0;
                                    
                                    // 檢查是否還有更多符號
                                    if (current_symbol_idx + 1 < current_morse_len) begin
                                        // 還有更多符號
                                        current_symbol_idx <= current_symbol_idx + 3'd1;
                                        morse_state        <= MORSE_SYMBOL_ON;
                                        led_morse          <= 1'b1;
                                        buzzer             <= 1'b1;
                                    end else begin
                                        // 這個字母結束，進入字母間隔
                                        morse_state <= MORSE_LETTER_GAP;
                                    end
                                end else begin
                                    morse_timer <= morse_timer + 27'd1;
                                end
                            end
                            
                            MORSE_LETTER_GAP: begin
                                // 字母間隔
                                led_morse <= 1'b0;
                                buzzer    <= 1'b0;
                                
                                if (morse_timer >= LETTER_GAP - 1) begin
                                    morse_timer <= 27'd0;
                                    
                                    // 檢查是否還有更多字母
                                    if (current_letter_idx + 1 < word_length) begin
                                        // 還有更多字母，進入載入狀態
                                        current_letter_idx <= current_letter_idx + 3'd1;
                                        current_symbol_idx <= 3'd0;
                                        morse_state        <= MORSE_LOAD_LETTER;
                                    end else begin
                                        // 單詞結束，進入單詞循環間隔
                                        morse_state <= MORSE_WORD_GAP;
                                    end
                                end else begin
                                    morse_timer <= morse_timer + 27'd1;
                                end
                            end
                            
                            MORSE_WORD_GAP: begin
                                // 單詞循環間隔 (非常長的間隔)
                                led_morse <= 1'b0;
                                buzzer    <= 1'b0;
                                
                                if (morse_timer >= WORD_GAP - 1) begin
                                    morse_timer <= 27'd0;
                                    // 重新開始播放
                                    morse_state <= MORSE_IDLE;
                                end else begin
                                    morse_timer <= morse_timer + 27'd1;
                                end
                            end
                            
                            default: begin
                                morse_state <= MORSE_IDLE;
                            end
                            
                        endcase
                    end
                end
                
                default: begin
                    activated     <= activated;
                    module_failed <= module_failed;
                    module_solved <= module_solved;
                end
                
            endcase
        end
    end
    
    //==================================================
    // 當字母索引改變時，更新當前字母的摩斯密碼
    // 使用組合邏輯讀取，在下一個 clock 由狀態機使用
    //==================================================
    // 注意：current_morse 和 current_morse_len 已在 MORSE_IDLE 和
    // MORSE_LETTER_GAP 狀態中更新

endmodule
