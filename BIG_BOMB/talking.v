

////////////////////////////////////////
module talking(
    input               rst,
    input               clk,
    input               tick_1sec,
    input  [31:0]       rnd,
    input  [2:0]        current_state ,
    input               ten_sec_left ,
    input               one_min_left ,
    input               Wires_mistake ,
    input               Memorys_mistake ,
    input               Mos_Code_mistake ,
    input               Maze_mistake ,
    input               Passwords_mistake ,
    output reg [479:0]  msg          // 60 ASCII chars (60*8=480)
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
//==============================================================
// msg
//==============================================================
//It's okay, you'll be more skilled next time.
//BOOOOOM
//Hmm... you really succeeded.
//good luck!
//need help
//Better luck next explosion, noob.
//It's a trap! Classic mistake.
//這是陷阱！經典失誤。
//Tick tock, doc... psych! 💣
//滴答滴答，醫生……騙你的！💣
//Take your time. There's still time.
//Not the red one, rookie!
//Hold my detonator...
//幫我拿一下雷管……

//狀態觸發
    //按啟動前
    localparam [479:0] MSG_ST_IDLE_A =                  "I want to play a game.                                      ";
    //啟動後其他事件出發之前
    localparam [479:0] MSG_ST_ACTIVATING_A =            "Welcome. Relax. Nothing bad ever happens at the beginning.  ";
    localparam [479:0] MSG_ST_ACTIVATING_B =            "Take a deep breath. This will be perfectly safe. Probably.  ";
    localparam [479:0] MSG_ST_ACTIVATING_C =            "All systems ready. Time is now officially your enemy.       ";
    localparam [479:0] MSG_ST_ACTIVATING_D =            "Initialization complete. User skill not detected yet.       ";
    localparam [479:0] MSG_ST_ACTIVATING_E =            "This is the part where you think you know what to do.       ";

//狀態DETONATING
    localparam [479:0] MSG_ST_DETONATING_A =            "FUCK YOU !!!        COCK SUCKER !!!                         ";

//狀態MISSION_FAILED
    localparam [479:0] MSG_ST_MISSION_FAILED_A =        "MISSION FAILED                                              ";
//狀態MISSION_SOLVED
    localparam [479:0] MSG_ST_MISSION_SUCCESSED_A =     "MISSION SUCCESSED                                           ";
//事件觸發
    //剪線剪錯
    localparam [479:0] MSG_EV_WIRES_MISTAKE_A =         "Ouch! Gentle, please. I'm not made of steel...              ";

    //過了一點時間
    localparam [479:0] MSG_TIME_PASS_A =                "OK... take it easy. I have all day.                         ";
    localparam [479:0] MSG_TIME_PASS_B =                "Relax. You still have time... probably.                     ";
    //要炸了
    localparam [479:0] MSG_GOING_TO_DIE_A =             "I will miss you, really.                                    ";
    //全對解開一個模組
    localparam [479:0] MSG_NT_A =                       "Nice try. That was almost intelligent.                      ";
    //無錯通關


    localparam [479:0] MSG6 =                           "If you mess this up, I'll haunt your HDL forever.           ";

    //Moscode_錯
    localparam [479:0] MSG7 =                           "Beep. Beep. That's the sound of your confidence dying.      ";
//條件隨機
    //線還沒過
    localparam [479:0] MSG_RED_WIRE_A =                 "Cut the red wire. Movies never lie, right?                  ";
    localparam [479:0] MSG_RED_WIRE_B =                 "Red wire. What could go wrong?                              ";
    localparam [479:0] MSG_RED_WIRE_C =                 "Cut the red wire. That's how movies do it.                  ";
//隨機


    // 60 個空白（padding 用）
    localparam [479:0] PAD60 = {60{" "}};  // 60 bytes of space

    // 把「短字串」放到 60 bytes 裡，右邊補空白
    // 注意：Verilog 字串常數是 packed bytes，左邊是第一個字元
    function automatic [479:0] pad60;
        input [479:0] s;  // 直接餵「已經放在左側」的字串常數即可
        begin
            // s 會把沒用到的高位補 0，我們用 OR 把空白填上去
            // 最簡單作法：預設全空白，再用 s 覆蓋左邊（高位）那段
            pad60 = PAD60;
            // 用 bitwise OR 不安全（因為空白不是 0），所以直接用 concatenation 寫法：
            // 但 Verilog 無法直接知道 s 的有效長度，因此這個 function 實務上用不到「自動長度」
            // => 我們改用「每句都手動補齊到 60」的方式最穩。
            pad60 = s;
        end
    endfunction

    parameter MSG_LAST_TIME = 8'd5;
    reg [7:0] msg_time_counter;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            msg_time_counter <= MSG_LAST_TIME;
        end else  begin
            if (new_msg) begin
                msg_time_counter <= 8'b0;
            end else if (tick_1sec) begin
                if (msg_time_counter == MSG_LAST_TIME) begin
                    msg_time_counter <= msg_time_counter ;
                end else begin
                    msg_time_counter <= msg_time_counter + 8'd1;
                end
            end    
        end
    end
    reg new_msg;
    wire [2:0] msg_selet = (rnd[7:0]) % (8'd5);
    // 同步輸出（你也可以改成組合 always @(*)）
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            msg <= MSG_ST_IDLE_A;
            new_msg <= 1'b0;
        end else begin
            new_msg <= 1'b0;
            if (current_state == IDLE) begin
                msg <= MSG_ST_IDLE_A;
            end else if (current_state == ACTIVATING) begin
                if (msg_time_counter == MSG_LAST_TIME) begin
                    new_msg <= 1'b1;
                    case (msg_selet)
                        3'd0 : begin
                            msg <= MSG_ST_ACTIVATING_A;
                        end
                        3'd1 : begin
                            msg <= MSG_ST_ACTIVATING_B;
                        end
                        3'd2 : begin
                            msg <= MSG_ST_ACTIVATING_C;
                        end
                        3'd3 : begin
                            msg <= MSG_ST_ACTIVATING_D;
                        end
                        3'd4 : begin
                            msg <= MSG_ST_ACTIVATING_E;
                        end
                    endcase
                end
            end else if (current_state == DETONATING) begin
                msg <= MSG_ST_DETONATING_A;
            end else if (current_state == MISSION_SUCCESSED) begin
                msg <= MSG_ST_MISSION_SUCCESSED_A;
                

            end else if (Wires_mistake) begin
                
            end else if (Memorys_mistake) begin
                
            end else if (Mos_Code_mistake) begin
                
            end else if (Maze_mistake) begin
                
            end else if (Passwords_mistake) begin
            end
        end
    end



endmodule
