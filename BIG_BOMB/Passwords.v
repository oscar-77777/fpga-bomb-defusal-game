module Passwords (
    //==================================================
    // Top level inputs
    //==================================================
    input rst ,
    input clk ,
    input [2:0] current_state,

    input [31:0] rnd,
    output reg activated, // latch signal
    output reg module_failed, // pulse signal
    output reg module_solved, // latch signal

    //==================================================
    // 按鈕輸入 (active high, 經過除彈跳)
    //==================================================
    input btn_up_0,    // 第0位字母向上
    input btn_down_0,  // 第0位字母向下
    input btn_up_1,    // 第1位字母向上
    input btn_down_1,
    input btn_up_2,
    input btn_down_2,
    input btn_up_3,
    input btn_down_3,
    input btn_up_4,
    input btn_down_4,
    input btn_submit,  // 提交按鈕
    
    //==================================================
    // 顯示輸出 (當前選中的字母, ASCII 編碼 97-122 = a-z)
    //==================================================
    output [7:0] display_char_0,
    output [7:0] display_char_1,
    output [7:0] display_char_2,
    output [7:0] display_char_3,
    output [7:0] display_char_4
);

    //==================================================
    // Top level states
    //==================================================
    localparam IDLE = 3'b000;
    localparam ACTIVATING = 3'b001;
    localparam ACTIVATED = 3'b010;

    // Parameters
    localparam NUM_WORDS = 35;
    localparam LETTERS_PER_POS = 6;

    //==================================================
    // 目標單詞索引 (由 rnd 決定)
    //==================================================
    reg [5:0] target_word_idx;
    
    //==================================================
    // 單詞表 - 共用查表邏輯
    // 每個字母用 5 bits 表示 (0-25 = a-z)
    // 單詞格式: {char4, char3, char2, char1, char0}
    // 
    // word_lookup_idx: 查表索引
    //   - 在 ATIV_CHECK 狀態使用 check_word_idx
    //   - 其他狀態使用 target_word_idx
    //==================================================
    reg [5:0] check_word_idx;  // 檢查單詞索引 (0-34)
    wire [5:0] word_lookup_idx;
    reg [24:0] word_data;      // 5 letters * 5 bits = 25 bits
    
    // 前向宣告 ativating_state (實際宣告在後面)
    reg [3:0] ativating_state;
    
    // 索引選擇：在檢查狀態用 check_word_idx，其他用 target_word_idx
    assign word_lookup_idx = (ativating_state == ATIV_CHECK) ? check_word_idx : target_word_idx;
    
    always @(*) begin
        case (word_lookup_idx)
            6'd0:  word_data = {5'd19, 5'd20, 5'd14, 5'd1,  5'd0};  // about
            6'd1:  word_data = {5'd17, 5'd4,  5'd19, 5'd5,  5'd0};  // after
            6'd2:  word_data = {5'd13, 5'd8,  5'd0,  5'd6,  5'd0};  // again
            6'd3:  word_data = {5'd22, 5'd14, 5'd11, 5'd4,  5'd1};  // below
            6'd4:  word_data = {5'd3,  5'd11, 5'd20, 5'd14, 5'd2};  // could
            6'd5:  word_data = {5'd24, 5'd17, 5'd4,  5'd21, 5'd4};  // every
            6'd6:  word_data = {5'd19, 5'd18, 5'd17, 5'd8,  5'd5};  // first
            6'd7:  word_data = {5'd3,  5'd13, 5'd20, 5'd14, 5'd5};  // found
            6'd8:  word_data = {5'd19, 5'd0,  5'd4,  5'd17, 5'd6};  // great
            6'd9:  word_data = {5'd4,  5'd18, 5'd20, 5'd14, 5'd7};  // house
            6'd10: word_data = {5'd4,  5'd6,  5'd17, 5'd0,  5'd11}; // large
            6'd11: word_data = {5'd13, 5'd17, 5'd0,  5'd4,  5'd11}; // learn
            6'd12: word_data = {5'd17, 5'd4,  5'd21, 5'd4,  5'd13}; // never
            6'd13: word_data = {5'd17, 5'd4,  5'd7,  5'd19, 5'd14}; // other
            6'd14: word_data = {5'd4,  5'd2,  5'd0,  5'd11, 5'd15}; // place
            6'd15: word_data = {5'd19, 5'd13, 5'd0,  5'd11, 5'd15}; // plant
            6'd16: word_data = {5'd19, 5'd13, 5'd8,  5'd14, 5'd15}; // point
            6'd17: word_data = {5'd19, 5'd7,  5'd6,  5'd8,  5'd17}; // right
            6'd18: word_data = {5'd11, 5'd11, 5'd0,  5'd12, 5'd18}; // small
            6'd19: word_data = {5'd3,  5'd13, 5'd20, 5'd14, 5'd18}; // sound
            6'd20: word_data = {5'd11, 5'd11, 5'd4,  5'd15, 5'd18}; // spell
            6'd21: word_data = {5'd11, 5'd11, 5'd8,  5'd19, 5'd18}; // still
            6'd22: word_data = {5'd24, 5'd3,  5'd20, 5'd19, 5'd18}; // study
            6'd23: word_data = {5'd17, 5'd8,  5'd4,  5'd7,  5'd19}; // their
            6'd24: word_data = {5'd4,  5'd17, 5'd4,  5'd7,  5'd19}; // there
            6'd25: word_data = {5'd4,  5'd18, 5'd4,  5'd7,  5'd19}; // these
            6'd26: word_data = {5'd6,  5'd13, 5'd8,  5'd7,  5'd19}; // thing
            6'd27: word_data = {5'd10, 5'd13, 5'd8,  5'd7,  5'd19}; // think
            6'd28: word_data = {5'd4,  5'd4,  5'd17, 5'd7,  5'd19}; // three
            6'd29: word_data = {5'd17, 5'd4,  5'd19, 5'd0,  5'd22}; // water
            6'd30: word_data = {5'd4,  5'd17, 5'd4,  5'd7,  5'd22}; // where
            6'd31: word_data = {5'd7,  5'd2,  5'd8,  5'd7,  5'd22}; // which
            6'd32: word_data = {5'd3,  5'd11, 5'd17, 5'd14, 5'd22}; // world
            6'd33: word_data = {5'd3,  5'd11, 5'd20, 5'd14, 5'd22}; // would
            6'd34: word_data = {5'd4,  5'd19, 5'd8,  5'd17, 5'd22}; // write
            default: word_data = {5'd19, 5'd20, 5'd14, 5'd1,  5'd0}; // about
        endcase
    end
    
    // 從 word_data 提取各字母 (共用於 target 和 check)
    wire [4:0] word_char_0 = word_data[4:0];
    wire [4:0] word_char_1 = word_data[9:5];
    wire [4:0] word_char_2 = word_data[14:10];
    wire [4:0] word_char_3 = word_data[19:15];
    wire [4:0] word_char_4 = word_data[24:20];
    
    // 目標單詞字母暫存器 (在生成干擾字母前鎖存)
    // 這樣在檢查階段仍可使用正確的目標字母
    reg [4:0] target_char_0_reg;
    reg [4:0] target_char_1_reg;
    reg [4:0] target_char_2_reg;
    reg [4:0] target_char_3_reg;
    reg [4:0] target_char_4_reg;
    
    // target_char_X: 用於生成干擾字母和最終比對
    // 在非檢查狀態時直接使用 word_char，在檢查狀態時使用暫存值
    wire [4:0] target_char_0 = target_char_0_reg;
    wire [4:0] target_char_1 = target_char_1_reg;
    wire [4:0] target_char_2 = target_char_2_reg;
    wire [4:0] target_char_3 = target_char_3_reg;
    wire [4:0] target_char_4 = target_char_4_reg;
    
    // check_char_X: 用於檢查衝突時的當前單詞字母
    wire [4:0] check_char_0 = word_char_0;
    wire [4:0] check_char_1 = word_char_1;
    wire [4:0] check_char_2 = word_char_2;
    wire [4:0] check_char_3 = word_char_3;
    wire [4:0] check_char_4 = word_char_4;
    
    //==================================================
    // 每個位置的可選字母 (6個字母 x 5個位置)
    //==================================================
    reg [4:0] letter_options_0 [0:5];
    reg [4:0] letter_options_1 [0:5];
    reg [4:0] letter_options_2 [0:5];
    reg [4:0] letter_options_3 [0:5];
    reg [4:0] letter_options_4 [0:5];
    
    //==================================================
    // 當前選中的字母索引 (0-5)
    // 用button來控制索引
    //==================================================
    reg [2:0] current_idx_0;
    reg [2:0] current_idx_1;
    reg [2:0] current_idx_2;
    reg [2:0] current_idx_3;
    reg [2:0] current_idx_4;
    
    //==================================================
    // 按鈕邊緣偵測
    //==================================================
    reg btn_up_0_prev, btn_down_0_prev;
    reg btn_up_1_prev, btn_down_1_prev;
    reg btn_up_2_prev, btn_down_2_prev;
    reg btn_up_3_prev, btn_down_3_prev;
    reg btn_up_4_prev, btn_down_4_prev;
    reg btn_submit_prev;
    
    wire btn_up_0_edge    = btn_up_0    & ~btn_up_0_prev;
    wire btn_down_0_edge  = btn_down_0  & ~btn_down_0_prev;
    wire btn_up_1_edge    = btn_up_1    & ~btn_up_1_prev;
    wire btn_down_1_edge  = btn_down_1  & ~btn_down_1_prev;
    wire btn_up_2_edge    = btn_up_2    & ~btn_up_2_prev;
    wire btn_down_2_edge  = btn_down_2  & ~btn_down_2_prev;
    wire btn_up_3_edge    = btn_up_3    & ~btn_up_3_prev;
    wire btn_down_3_edge  = btn_down_3  & ~btn_down_3_prev;
    wire btn_up_4_edge    = btn_up_4    & ~btn_up_4_prev;
    wire btn_down_4_edge  = btn_down_4  & ~btn_down_4_prev;
    wire btn_submit_edge  = btn_submit  & ~btn_submit_prev;
    
    //==================================================
    // 邊緣偵測暫存器
    //==================================================
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            btn_up_0_prev   <= 1'b0;
            btn_down_0_prev <= 1'b0;
            btn_up_1_prev   <= 1'b0;
            btn_down_1_prev <= 1'b0;
            btn_up_2_prev   <= 1'b0;
            btn_down_2_prev <= 1'b0;
            btn_up_3_prev   <= 1'b0;
            btn_down_3_prev <= 1'b0;
            btn_up_4_prev   <= 1'b0;
            btn_down_4_prev <= 1'b0;
            btn_submit_prev <= 1'b0;
        end else begin
            btn_up_0_prev   <= btn_up_0;
            btn_down_0_prev <= btn_down_0;
            btn_up_1_prev   <= btn_up_1;
            btn_down_1_prev <= btn_down_1;
            btn_up_2_prev   <= btn_up_2;
            btn_down_2_prev <= btn_down_2;
            btn_up_3_prev   <= btn_up_3;
            btn_down_3_prev <= btn_down_3;
            btn_up_4_prev   <= btn_up_4;
            btn_down_4_prev <= btn_down_4;
            btn_submit_prev <= btn_submit;
        end
    end

    //==================================================
    // 當前顯示的字母 (ASCII 編碼: 'a'=97, 'z'=122)
    //==================================================
    wire [4:0] current_letter_0 = letter_options_0[current_idx_0];
    wire [4:0] current_letter_1 = letter_options_1[current_idx_1];
    wire [4:0] current_letter_2 = letter_options_2[current_idx_2];
    wire [4:0] current_letter_3 = letter_options_3[current_idx_3];
    wire [4:0] current_letter_4 = letter_options_4[current_idx_4];
    
    // 轉換為 ASCII: 0->97('a'), 1->98('b'), ..., 25->122('z')
    assign display_char_0 = 8'd97 + {3'b000, current_letter_0};
    assign display_char_1 = 8'd97 + {3'b000, current_letter_1};
    assign display_char_2 = 8'd97 + {3'b000, current_letter_2};
    assign display_char_3 = 8'd97 + {3'b000, current_letter_3};
    assign display_char_4 = 8'd97 + {3'b000, current_letter_4};
    
    //==================================================
    // 比對當前選擇與目標單詞 (使用內部 0-25 值比對)
    //==================================================
    wire match = (current_letter_0 == target_char_0) &&
                 (current_letter_1 == target_char_1) &&
                 (current_letter_2 == target_char_2) &&
                 (current_letter_3 == target_char_3) &&
                 (current_letter_4 == target_char_4);


    //==================================================
    // 生成干擾字母的輔助函數
    // 使用固定偏移量確保：
    // 1. 不與正確答案重複
    // 2. 6 個選項彼此不同
    // 偏移量選擇互質數：4, 7, 11, 15, 19 (都與 26 互質且彼此不同)
    // 
    // 干擾字母 = correct_letter
    //     + 固定偏移(base_offset)
    //     + 小亂數(rnd_val)
    //     mod 26
    //==================================================
    function [4:0] gen_distractor;
        input [4:0] correct_letter;
        input [2:0] slot;      // 1-5，表示是第幾個干擾選項
        input [1:0] rnd_val;   // 0-3，用於微調增加變化
        reg [4:0] base_offset;
        begin
            // 每個 slot 使用不同的基礎偏移量
            case (slot)
                3'd1: base_offset = 5'd4;   // 第1個干擾字母偏移 4-7
                3'd2: base_offset = 5'd8;   // 第2個干擾字母偏移 8-11
                3'd3: base_offset = 5'd12;  // 第3個干擾字母偏移 12-15
                3'd4: base_offset = 5'd16;  // 第4個干擾字母偏移 16-19
                3'd5: base_offset = 5'd20;  // 第5個干擾字母偏移 20-23
                default: base_offset = 5'd4;
            endcase
            // 加上亂數微調 (0-3)，確保每次遊戲有變化
            gen_distractor = (correct_letter + base_offset + {3'b0, rnd_val}) % 5'd26;
        end
    endfunction

    //==================================================
    // ATIVATING 內部狀態機
    //==================================================
    localparam ATIV_INIT       = 4'd0;  // 選擇目標單詞
    localparam ATIV_GEN_POS0   = 4'd1;  // 生成位置 0 干擾字母
    localparam ATIV_GEN_POS1   = 4'd2;  // 生成位置 1 干擾字母
    localparam ATIV_GEN_POS2   = 4'd3;  // 生成位置 2 干擾字母
    localparam ATIV_GEN_POS3   = 4'd4;  // 生成位置 3 干擾字母
    localparam ATIV_GEN_POS4   = 4'd5;  // 生成位置 4 干擾字母
    localparam ATIV_CHECK      = 4'd6;  // 檢查是否有衝突單詞
    localparam ATIV_DONE       = 4'd7;  // 完成，等待切換到 ATIVATED
    
    // 注意：ativating_state 和 check_word_idx 已在前面宣告（共用查表需要）
    reg conflict_found;            // 是否發現衝突
    reg [2:0] regen_position;      // 需要重新生成的位置
    //==================================================
    // 生成隨機 index
    //==================================================
    wire [5:0] random_index_0 = rnd[4:0] % 5'd6;
    wire [5:0] random_index_1 = (random_index_0 + 5'd1) % 6;
    wire [5:0] random_index_2 = (random_index_1 + 5'd1) % 6;
    wire [5:0] random_index_3 = (random_index_2 + 5'd1) % 6;
    wire [5:0] random_index_4 = (random_index_3 + 5'd1) % 6;
    wire [5:0] random_index_5 = (random_index_4 + 5'd1) % 6;

    //==================================================
    // 檢查某字母是否在某位置的選項中
    //==================================================
    wire char0_in_opts = (check_char_0 == letter_options_0[0]) ||
                         (check_char_0 == letter_options_0[1]) ||
                         (check_char_0 == letter_options_0[2]) ||
                         (check_char_0 == letter_options_0[3]) ||
                         (check_char_0 == letter_options_0[4]) ||
                         (check_char_0 == letter_options_0[5]);
                         
    wire char1_in_opts = (check_char_1 == letter_options_1[0]) ||
                         (check_char_1 == letter_options_1[1]) ||
                         (check_char_1 == letter_options_1[2]) ||
                         (check_char_1 == letter_options_1[3]) ||
                         (check_char_1 == letter_options_1[4]) ||
                         (check_char_1 == letter_options_1[5]);
                         
    wire char2_in_opts = (check_char_2 == letter_options_2[0]) ||
                         (check_char_2 == letter_options_2[1]) ||
                         (check_char_2 == letter_options_2[2]) ||
                         (check_char_2 == letter_options_2[3]) ||
                         (check_char_2 == letter_options_2[4]) ||
                         (check_char_2 == letter_options_2[5]);
                         
    wire char3_in_opts = (check_char_3 == letter_options_3[0]) ||
                         (check_char_3 == letter_options_3[1]) ||
                         (check_char_3 == letter_options_3[2]) ||
                         (check_char_3 == letter_options_3[3]) ||
                         (check_char_3 == letter_options_3[4]) ||
                         (check_char_3 == letter_options_3[5]);
                         
    wire char4_in_opts = (check_char_4 == letter_options_4[0]) ||
                         (check_char_4 == letter_options_4[1]) ||
                         (check_char_4 == letter_options_4[2]) ||
                         (check_char_4 == letter_options_4[3]) ||
                         (check_char_4 == letter_options_4[4]) ||
                         (check_char_4 == letter_options_4[5]);
    
    // 當前檢查的單詞是否可被組成（且不是目標單詞）
    wire word_can_be_formed = char0_in_opts && char1_in_opts && 
                              char2_in_opts && char3_in_opts && char4_in_opts;
    wire is_not_target = (check_word_idx != target_word_idx);
    wire current_word_conflict = word_can_be_formed && is_not_target;
    
    // 找出是哪個位置的干擾字母造成衝突（用於重新生成）
    // 優先選擇位置 0，其次 1, 2, 3, 4
    wire [2:0] conflict_position = (check_char_0 != target_char_0) ? 3'd0 :
                                   (check_char_1 != target_char_1) ? 3'd1 :
                                   (check_char_2 != target_char_2) ? 3'd2 :
                                   (check_char_3 != target_char_3) ? 3'd3 : 3'd4;

    //==================================================
    // 主要邏輯
    //==================================================
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // 非同步負緣 reset
            activated <= 1'b0;
            module_failed <= 1'b0;
            module_solved <= 1'b0;
            
            target_word_idx <= 6'd0;
            
            current_idx_0 <= 3'd0;
            current_idx_1 <= 3'd0;
            current_idx_2 <= 3'd0;
            current_idx_3 <= 3'd0;
            current_idx_4 <= 3'd0;
            
            // 初始化字母選項
            letter_options_0[0] <= 5'd0;
            letter_options_0[1] <= 5'd1;
            letter_options_0[2] <= 5'd2;
            letter_options_0[3] <= 5'd3;
            letter_options_0[4] <= 5'd4;
            letter_options_0[5] <= 5'd5;
            
            letter_options_1[0] <= 5'd0;
            letter_options_1[1] <= 5'd1;
            letter_options_1[2] <= 5'd2;
            letter_options_1[3] <= 5'd3;
            letter_options_1[4] <= 5'd4;
            letter_options_1[5] <= 5'd5;
            
            letter_options_2[0] <= 5'd0;
            letter_options_2[1] <= 5'd1;
            letter_options_2[2] <= 5'd2;
            letter_options_2[3] <= 5'd3;
            letter_options_2[4] <= 5'd4;
            letter_options_2[5] <= 5'd5;
            
            letter_options_3[0] <= 5'd0;
            letter_options_3[1] <= 5'd1;
            letter_options_3[2] <= 5'd2;
            letter_options_3[3] <= 5'd3;
            letter_options_3[4] <= 5'd4;
            letter_options_3[5] <= 5'd5;
            
            letter_options_4[0] <= 5'd0;
            letter_options_4[1] <= 5'd1;
            letter_options_4[2] <= 5'd2;
            letter_options_4[3] <= 5'd3;
            letter_options_4[4] <= 5'd4;
            letter_options_4[5] <= 5'd5;

            ativating_state <= ATIV_INIT;
            check_word_idx <= 6'd0;
            conflict_found <= 1'b0;
            regen_position <= 3'd0;
            
            // 目標字母暫存器初始化
            target_char_0_reg <= 5'd0;
            target_char_1_reg <= 5'd0;
            target_char_2_reg <= 5'd0;
            target_char_3_reg <= 5'd0;
            target_char_4_reg <= 5'd0;
            
        end else begin
            
            case (current_state)
                
                IDLE: begin
                    activated <= 1'b0;
                    module_failed <= 1'b0;
                    module_solved <= 1'b0;
                    current_idx_0 <= 3'd0;
                    current_idx_1 <= 3'd0;
                    current_idx_2 <= 3'd0;
                    current_idx_3 <= 3'd0;
                    current_idx_4 <= 3'd0;
                    ativating_state <= ATIV_INIT;
                    check_word_idx <= 6'd0;
                    conflict_found <= 1'b0;
                end
                
                ACTIVATING: begin
                    
                    module_solved <= 1'b0;
                    module_failed <= 1'b0;

                    // 重置選擇索引
                    current_idx_0 <= 3'd0;
                    current_idx_1 <= 3'd0;
                    current_idx_2 <= 3'd0;
                    current_idx_3 <= 3'd0;
                    current_idx_4 <= 3'd0;

                    case (ativating_state)
                        //----------------------------------------------
                        // 階段 0: 選擇目標單詞
                        //----------------------------------------------
                        ATIV_INIT: begin
                            activated <= 1'b0;
                            target_word_idx <= rnd[5:0] % NUM_WORDS;
                            conflict_found <= 1'b0;
                            ativating_state <= ATIV_GEN_POS0;
                        end
                        
                        //----------------------------------------------
                        // 階段 1-5: 逐一生成每個位置的干擾字母
                        //----------------------------------------------
                        ATIV_GEN_POS0: begin
                            activated <= 1'b0;
                            
                            // 鎖存目標字母 (此時 word_lookup_idx = target_word_idx)
                            target_char_0_reg <= word_char_0;
                            target_char_1_reg <= word_char_1;
                            target_char_2_reg <= word_char_2;
                            target_char_3_reg <= word_char_3;
                            target_char_4_reg <= word_char_4;
                            
                            // 生成位置 0 的干擾字母 (使用 word_char_0 因為此時還是目標單詞)
                            letter_options_0[random_index_0] <= word_char_0;
                            letter_options_0[random_index_1] <= gen_distractor(word_char_0, 3'd1, rnd[1:0]);
                            letter_options_0[random_index_2] <= gen_distractor(word_char_0, 3'd2, rnd[3:2]);
                            letter_options_0[random_index_3] <= gen_distractor(word_char_0, 3'd3, rnd[5:4]);
                            letter_options_0[random_index_4] <= gen_distractor(word_char_0, 3'd4, rnd[7:6]);
                            letter_options_0[random_index_5] <= gen_distractor(word_char_0, 3'd5, rnd[9:8]);
                            ativating_state <= ATIV_GEN_POS1;
                        end
                        
                        ATIV_GEN_POS1: begin
                            activated <= 1'b0;
                            letter_options_1[random_index_0] <= target_char_1;
                            letter_options_1[random_index_1] <= gen_distractor(target_char_1, 3'd1, rnd[11:10]);
                            letter_options_1[random_index_2] <= gen_distractor(target_char_1, 3'd2, rnd[13:12]);
                            letter_options_1[random_index_3] <= gen_distractor(target_char_1, 3'd3, rnd[15:14]);
                            letter_options_1[random_index_4] <= gen_distractor(target_char_1, 3'd4, rnd[17:16]);
                            letter_options_1[random_index_5] <= gen_distractor(target_char_1, 3'd5, rnd[19:18]);
                            ativating_state <= ATIV_GEN_POS2;
                        end
                        
                        ATIV_GEN_POS2: begin
                            activated <= 1'b0;
                            letter_options_2[random_index_0] <= target_char_2;
                            letter_options_2[random_index_1] <= gen_distractor(target_char_2, 3'd1, rnd[21:20]);
                            letter_options_2[random_index_2] <= gen_distractor(target_char_2, 3'd2, rnd[23:22]);
                            letter_options_2[random_index_3] <= gen_distractor(target_char_2, 3'd3, rnd[25:24]);
                            letter_options_2[random_index_4] <= gen_distractor(target_char_2, 3'd4, rnd[27:26]);
                            letter_options_2[random_index_5] <= gen_distractor(target_char_2, 3'd5, rnd[29:28]);
                            ativating_state <= ATIV_GEN_POS3;
                        end
                        
                        ATIV_GEN_POS3: begin
                            activated <= 1'b0;
                            letter_options_3[random_index_0] <= target_char_3;
                            letter_options_3[random_index_1] <= gen_distractor(target_char_3, 3'd1, rnd[31:30]);
                            letter_options_3[random_index_2] <= gen_distractor(target_char_3, 3'd2, rnd[1:0]);
                            letter_options_3[random_index_3] <= gen_distractor(target_char_3, 3'd3, rnd[3:2]);
                            letter_options_3[random_index_4] <= gen_distractor(target_char_3, 3'd4, rnd[5:4]);
                            letter_options_3[random_index_5] <= gen_distractor(target_char_3, 3'd5, rnd[7:6]);
                            ativating_state <= ATIV_GEN_POS4;
                        end
                        
                        ATIV_GEN_POS4: begin
                            activated <= 1'b0;
                            letter_options_4[random_index_0] <= target_char_4;
                            letter_options_4[random_index_1] <= gen_distractor(target_char_4, 3'd1, rnd[9:8]);
                            letter_options_4[random_index_2] <= gen_distractor(target_char_4, 3'd2, rnd[11:10]);
                            letter_options_4[random_index_3] <= gen_distractor(target_char_4, 3'd3, rnd[13:12]);
                            letter_options_4[random_index_4] <= gen_distractor(target_char_4, 3'd4, rnd[15:14]);
                            letter_options_4[random_index_5] <= gen_distractor(target_char_4, 3'd5, rnd[17:16]);
                            // 開始檢查衝突
                            check_word_idx <= 6'd0;
                            ativating_state <= ATIV_CHECK;
                        end
                        
                        //----------------------------------------------
                        // 階段 6: 檢查是否有衝突（每個 clk 檢查一個單詞）
                        //----------------------------------------------
                        ATIV_CHECK: begin
                            activated <= 1'b0;
                            
                            if (current_word_conflict) begin
                                // 發現衝突！記錄衝突位置並重新生成該位置
                                conflict_found <= 1'b1;
                                regen_position <= conflict_position;
                                
                                // 根據衝突位置，用新的亂數重新生成干擾字母
                                case (conflict_position)
                                    3'd0: begin
                                        // 用不同的偏移重新生成位置 0 的干擾字母
                                        letter_options_0[random_index_0] <= word_char_0;
                                        letter_options_0[random_index_1] <= gen_distractor(target_char_0, 3'd1, rnd[3:2]);
                                        letter_options_0[random_index_2] <= gen_distractor(target_char_0, 3'd2, rnd[5:4]);
                                        letter_options_0[random_index_3] <= gen_distractor(target_char_0, 3'd3, rnd[7:6]);
                                        letter_options_0[random_index_4] <= gen_distractor(target_char_0, 3'd4, rnd[9:8]);
                                        letter_options_0[random_index_5] <= gen_distractor(target_char_0, 3'd5, rnd[11:10]);
                                    end
                                    3'd1: begin
                                        letter_options_1[random_index_0] <= target_char_1;
                                        letter_options_1[random_index_1] <= gen_distractor(target_char_1, 3'd1, rnd[13:12]);
                                        letter_options_1[random_index_2] <= gen_distractor(target_char_1, 3'd2, rnd[15:14]);
                                        letter_options_1[random_index_3] <= gen_distractor(target_char_1, 3'd3, rnd[17:16]);
                                        letter_options_1[random_index_4] <= gen_distractor(target_char_1, 3'd4, rnd[19:18]);
                                        letter_options_1[random_index_5] <= gen_distractor(target_char_1, 3'd5, rnd[21:20]);
                                    end
                                    3'd2: begin
                                        letter_options_2[random_index_0] <= target_char_2;
                                        letter_options_2[random_index_1] <= gen_distractor(target_char_2, 3'd1, rnd[23:22]);
                                        letter_options_2[random_index_2] <= gen_distractor(target_char_2, 3'd2, rnd[25:24]);
                                        letter_options_2[random_index_3] <= gen_distractor(target_char_2, 3'd3, rnd[27:26]);
                                        letter_options_2[random_index_4] <= gen_distractor(target_char_2, 3'd4, rnd[29:28]);
                                        letter_options_2[random_index_5] <= gen_distractor(target_char_2, 3'd5, rnd[31:30]);
                                    end
                                    3'd3: begin
                                        letter_options_3[random_index_0] <= target_char_3;
                                        letter_options_3[random_index_1] <= gen_distractor(target_char_3, 3'd1, rnd[1:0]);
                                        letter_options_3[random_index_2] <= gen_distractor(target_char_3, 3'd2, rnd[3:2]);
                                        letter_options_3[random_index_3] <= gen_distractor(target_char_3, 3'd3, rnd[5:4]);
                                        letter_options_3[random_index_4] <= gen_distractor(target_char_3, 3'd4, rnd[7:6]);
                                        letter_options_3[random_index_5] <= gen_distractor(target_char_3, 3'd5, rnd[9:8]);
                                    end
                                    default: begin // 3'd4
                                        letter_options_4[random_index_0] <= target_char_4;
                                        letter_options_4[random_index_1] <= gen_distractor(target_char_4, 3'd1, rnd[11:10]);
                                        letter_options_4[random_index_2] <= gen_distractor(target_char_4, 3'd2, rnd[13:12]);
                                        letter_options_4[random_index_3] <= gen_distractor(target_char_4, 3'd3, rnd[15:14]);
                                        letter_options_4[random_index_4] <= gen_distractor(target_char_4, 3'd4, rnd[17:16]);
                                        letter_options_4[random_index_5] <= gen_distractor(target_char_4, 3'd5, rnd[19:18]);
                                    end
                                endcase
                                
                                // 重新從頭檢查
                                check_word_idx <= 6'd0;
                            end
                            else if (check_word_idx == NUM_WORDS - 1) begin
                                // 檢查完所有單詞，沒有衝突
                                ativating_state <= ATIV_DONE;
                            end
                            else begin
                                // 繼續檢查下一個單詞
                                check_word_idx <= check_word_idx + 6'd1;
                            end
                        end
                        
                        //----------------------------------------------
                        // 階段 7: 完成，等待 master 切換到 ATIVATED
                        //----------------------------------------------
                        ATIV_DONE: begin
                            activated <= 1'b1;
                            // 保持在此狀態直到 current_state 變為 ATIVATED
                        end
                        
                        default: begin
                            activated <= 1'b0;
                            ativating_state <= ATIV_INIT;
                        end
                    endcase       
                    
                end
                
                ACTIVATED: begin
                    // 重置 ativating_state 以便下次可重新初始化
                    ativating_state <= ATIV_INIT;
                    
                    // 放下 activated (只需維持一個 clk)
                    activated <= 1'b0; 
                    
                    // 如果已解鎖，保持狀態
                    if (module_solved) begin
                        module_solved <= 1'b1;
                        module_failed <= 1'b0;
                    end else begin
                        // 放下 module_failed (只維持一個 clk)
                        module_failed <= 1'b0;
                        
                        // 處理按鈕輸入 - 位置 0
                        if (btn_up_0_edge) begin
                            current_idx_0 <= (current_idx_0 == 3'd5) ? 3'd0 : current_idx_0 + 3'd1;
                        end else if (btn_down_0_edge) begin
                            current_idx_0 <= (current_idx_0 == 3'd0) ? 3'd5 : current_idx_0 - 3'd1;
                        end
                        
                        // 處理按鈕輸入 - 位置 1
                        if (btn_up_1_edge) begin
                            current_idx_1 <= (current_idx_1 == 3'd5) ? 3'd0 : current_idx_1 + 3'd1;
                        end else if (btn_down_1_edge) begin
                            current_idx_1 <= (current_idx_1 == 3'd0) ? 3'd5 : current_idx_1 - 3'd1;
                        end
                        
                        // 處理按鈕輸入 - 位置 2
                        if (btn_up_2_edge) begin
                            current_idx_2 <= (current_idx_2 == 3'd5) ? 3'd0 : current_idx_2 + 3'd1;
                        end else if (btn_down_2_edge) begin
                            current_idx_2 <= (current_idx_2 == 3'd0) ? 3'd5 : current_idx_2 - 3'd1;
                        end
                        
                        // 處理按鈕輸入 - 位置 3
                        if (btn_up_3_edge) begin
                            current_idx_3 <= (current_idx_3 == 3'd5) ? 3'd0 : current_idx_3 + 3'd1;
                        end else if (btn_down_3_edge) begin
                            current_idx_3 <= (current_idx_3 == 3'd0) ? 3'd5 : current_idx_3 - 3'd1;
                        end
                        
                        // 處理按鈕輸入 - 位置 4
                        if (btn_up_4_edge) begin
                            current_idx_4 <= (current_idx_4 == 3'd5) ? 3'd0 : current_idx_4 + 3'd1;
                        end else if (btn_down_4_edge) begin
                            current_idx_4 <= (current_idx_4 == 3'd0) ? 3'd5 : current_idx_4 - 3'd1;
                        end
                        
                        // 處理提交按鈕
                        if (btn_submit_edge) begin
                            if (match) begin
                                module_solved <= 1'b1;
                                module_failed <= 1'b0;
                            end else begin
                                module_solved <= 1'b0;
                                module_failed <= 1'b1;
                            end
                        end
                    end
                end
                
                default: begin
                    activated <= activated;
                    module_failed <= module_failed;
                    module_solved <= module_solved;
                end
                
            endcase
        end
    end

endmodule
