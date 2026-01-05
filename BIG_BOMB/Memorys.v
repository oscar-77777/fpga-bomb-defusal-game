module Memorys (
    input rst,             // 假設外部按鈕是 Active Low (按下為0)
    input clk,
    input [2:0] current_state, // 沒用到，先註解掉以免 Warning
    input [31:0] rnd,      // 隨機種子
    input btn1,
    input btn2,
    input btn3,
    input btn4,
    output reg activated,
    output reg module_failed, // 錯誤時 High 一個 Clock
    output module_solved,     // 過關時 High
    
    output tm_clk,
    inout  tm_dio,           
    output [7:0] seven_digit
);

//==============================================================
// center_controller_state_define
//==============================================================
parameter IDLE              = 3'b000;
parameter ACTIVATING        = 3'b001;
parameter ACTIVATED         = 3'b010;
parameter DETONATING        = 3'b011;
parameter MISSION_FAILED    = 3'b100;
parameter MISSION_SUCCESSED = 3'b101;

// --- 暫存器與連線定義 ---
reg [2:0] history_pos [0:4]; 
reg [2:0] history_num [0:4];

reg [2:0] rand_b0, rand_b1, rand_b2, rand_b3; 

reg [2:0] btn1_nums, btn2_nums, btn3_nums, btn4_nums;
reg [2:0] LCD_nums;
wire b1, b2, b3, b4;
reg b1_last, b2_last, b3_last, b4_last; 

reg [31:0]rnd_reg;

reg [2:0] state;
reg [1:0] get_num_state;
reg is_correct;
reg is_correctreg;

// 取得當前按下的位置 (1-4) 與對應的數字 (Priority Encoder)
wire [2:0] current_pos = b1 ? 3'd1 : b2 ? 3'd2 : b3 ? 3'd3 : b4 ? 3'd4 : 3'd0;
wire [2:0] current_num = b1 ? btn1_nums : b2 ? btn2_nums : b3 ? btn3_nums : b4 ? btn4_nums : 3'd0;


// 偵測按鈕上升沿 (Rising Edge)
wire btn_trigger = (b1 && !b1_last) || (b2 && !b2_last) || (b3 && !b3_last) || (b4 && !b4_last);

// --- 參數定義 ---
localparam STAGE1 = 3'd1, STAGE2 = 3'd2, STAGE3 = 3'd3, STAGE4 = 3'd4, STAGE5 = 3'd5;
localparam GAME_WIN = 3'd6, GAME_FAIL = 3'd7;

localparam GET_NUM_IDLE    = 2'd0;
localparam GET_NUM_REQUEST = 2'd1;
localparam GET_NUM_STATE   = 2'd2;
localparam GET_NUM_WAIT_BOTTON    = 2'd3;

// --- 1. 隨機序列查找表 (修正為獨立變數賦值) ---
always @(*) begin
    // 預設值
    {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd1, 3'd2, 3'd3, 3'd4};
    
    case(rnd[4:0] % 24)
        5'd0:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd1,3'd2,3'd3,3'd4};
        5'd1:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd1,3'd2,3'd4,3'd3};
        5'd2:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd1,3'd3,3'd2,3'd4};
        5'd3:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd1,3'd3,3'd4,3'd2};
        5'd4:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd1,3'd4,3'd2,3'd3};
        5'd5:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd1,3'd4,3'd3,3'd2};
        5'd6:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd2,3'd1,3'd3,3'd4};
        5'd7:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd2,3'd1,3'd4,3'd3};
        5'd8:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd2,3'd3,3'd1,3'd4};
        5'd9:  {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd2,3'd3,3'd4,3'd1};
        5'd10: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd2,3'd4,3'd1,3'd3};
        5'd11: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd2,3'd4,3'd3,3'd1};
        5'd12: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd3,3'd1,3'd2,3'd4};
        5'd13: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd3,3'd1,3'd4,3'd2};
        5'd14: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd3,3'd2,3'd1,3'd4};
        5'd15: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd3,3'd2,3'd4,3'd1};
        5'd16: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd3,3'd4,3'd1,3'd2};
        5'd17: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd3,3'd4,3'd2,3'd1};
        5'd18: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd4,3'd1,3'd2,3'd3};
        5'd19: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd4,3'd1,3'd3,3'd2};
        5'd20: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd4,3'd2,3'd1,3'd3};
        5'd21: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd4,3'd2,3'd3,3'd1};
        5'd22: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd4,3'd3,3'd1,3'd2};
        5'd23: {rand_b0, rand_b1, rand_b2, rand_b3} = {3'd4,3'd3,3'd2,3'd1};
    endcase
end

// --- 2. 核心控制狀態機 ---
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        state <= STAGE1;
        get_num_state <= GET_NUM_IDLE; 
        activated <= 0;
        module_failed <= 0;
        b1_last <= 0; b2_last <= 0; b3_last <= 0; b4_last <= 0;
        rnd_reg <= 31'd0;
        // 歷史紀錄重設
        history_pos[0] <= 0; history_pos[1] <= 0; history_pos[2] <= 0; history_pos[3] <= 0; history_pos[4] <= 0;
        history_num[0] <= 0; history_num[1] <= 0; history_num[2] <= 0; history_num[3] <= 0; history_num[4] <= 0;
        
        // 初始值 (避免 latch)
        btn1_nums <= 0; btn2_nums <= 0; btn3_nums <= 0; btn4_nums <= 0; LCD_nums <= 0;
        is_correctreg <= 1'b0;

    end else begin
        b1_last <= b1; b2_last <= b2; b3_last <= b3; b4_last <= b4;
        module_failed <= 0; // 預設拉低，只有在失敗的那一瞬間拉高
        
        case (get_num_state)
            GET_NUM_IDLE: begin
                if(current_state == ACTIVATING) begin //如果還沒
                    get_num_state <= GET_NUM_REQUEST;
                end
                else get_num_state <= GET_NUM_IDLE;
            end
            GET_NUM_REQUEST: begin
                // 使用修正後的變數
                btn1_nums <= rand_b0;
                btn2_nums <= rand_b1;
                btn3_nums <= rand_b2;
                btn4_nums <= rand_b3;
                LCD_nums  <= (rnd[7:5] % 4) + 1;
                get_num_state <= GET_NUM_STATE;
                activated <= 1;
            end

            GET_NUM_STATE: begin
                
                if (state == GAME_FAIL) begin
                    state <= STAGE1; // 失敗後重置回第一關
                    // 歷史紀錄重設
                    history_pos[0] <= 0; history_pos[1] <= 0; history_pos[2] <= 0; history_pos[3] <= 0; history_pos[4] <= 0;
                    history_num[0] <= 0; history_num[1] <= 0; history_num[2] <= 0; history_num[3] <= 0; history_num[4] <= 0;
                end else if (is_correctreg) begin
                    case (state)
                        STAGE1: state <= STAGE2;
                        STAGE2: state <= STAGE3;
                        STAGE3: state <= STAGE4;
                        STAGE4: state <= STAGE5;
                        STAGE5: state <= GAME_WIN; 
                    endcase
                end else begin
                    state <= state;
                end
                get_num_state <= GET_NUM_WAIT_BOTTON;
            end

            GET_NUM_WAIT_BOTTON: begin
                is_correctreg <= is_correct;
                if (btn_trigger && !module_solved/*改*/) begin
                    if (is_correct) begin
                        // 記錄歷史
                        case (state)
                            STAGE1: begin history_pos[0] <= current_pos; history_num[0] <= current_num; end
                            STAGE2: begin history_pos[1] <= current_pos; history_num[1] <= current_num; end
                            STAGE3: begin history_pos[2] <= current_pos; history_num[2] <= current_num; end
                            STAGE4: begin history_pos[3] <= current_pos; history_num[3] <= current_num; end
                            STAGE5: begin history_pos[4] <= current_pos; history_num[4] <= current_num; end
                        endcase
                        get_num_state <= GET_NUM_REQUEST; 
                    end else begin
                        module_failed <= 1; // 觸發錯誤訊號
                        state <= GAME_FAIL; 
                        get_num_state <= GET_NUM_REQUEST; 
                    end
                end

            end
        endcase
    end
end

// --- 3. 核心解謎邏輯 (KTANE Memory Module) ---
always @(*) begin
    is_correct = 1'b0; // Default assignment/
    case (state)
        STAGE1: begin
            if (LCD_nums == 3'd1 || LCD_nums == 3'd2) is_correct = (current_pos == 2);
            else if (LCD_nums == 3'd3)                is_correct = (current_pos == 3);
            else                                      is_correct = (current_pos == 4);
        end
        STAGE2: begin
            if (LCD_nums == 3'd1)                     is_correct = (current_num == 4);
            else if (LCD_nums == 3'd2 || LCD_nums == 3'd4) is_correct = (current_pos == history_pos[0]);
            else                                      is_correct = (current_pos == 1);
        end
        STAGE3: begin
            if (LCD_nums == 3'd1)                     is_correct = (current_num == history_num[1]);
            else if (LCD_nums == 3'd2)                is_correct = (current_num == history_num[0]);
            else if (LCD_nums == 3'd3)                is_correct = (current_pos == 3);
            else                                      is_correct = (current_num == 4);
        end
        STAGE4: begin
            if (LCD_nums == 3'd1)                     is_correct = (current_pos == history_pos[0]);
            else if (LCD_nums == 3'd2)                is_correct = (current_pos == 1);
            else                                      is_correct = (current_pos == history_pos[1]);
        end
        STAGE5: begin
            if (LCD_nums == 3'd1)                     is_correct = (current_num == history_num[0]);
            else if (LCD_nums == 3'd2)                is_correct = (current_num == history_num[1]);
            else if (LCD_nums == 3'd3)                is_correct = (current_num == history_num[3]);
            else                                      is_correct = (current_num == history_num[2]);
        end
        default: is_correct = 1'b0;
    endcase
end


// --- 4. 輸出賦值 ---
assign module_solved = (state == GAME_WIN);

// --- 5. 子模組實例化 ---
// 請確認你的 debouncing 模組檔名是否正確 (拼字修正)
deboucing d1(clk, rst, btn1, b1); 
deboucing d2(clk, rst, btn2, b2);
deboucing d3(clk, rst, btn3, b3);
deboucing d4(clk, rst, btn4, b4);

// TM1637 驅動 (顯示按鈕上的數字)
tm1637_driver tm(
    .clk(clk),
    .rst_n(rst), // 這裡假設 rst 是 Active Low，如果 tm1637 內部是 negedge rst_n 就直接接
    .n1(btn1_nums),
    .n2(btn2_nums),
    .n3(btn3_nums),
    .n4(btn4_nums),
    .current_stage(state),
    .tm_clk(tm_clk),
    .tm_dio(tm_dio)
);

// 七段顯示器 (顯示 LCD 大數字)
seven_digit_driver sd(LCD_nums,state,seven_digit);

endmodule