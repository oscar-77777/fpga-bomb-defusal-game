module Center_Timmer(
    input rst ,
    input clk ,
    input tick_10ms ,
    input [2:0] current_state ,

//==============================================================
// 調整難度_時間
//==============================================================
    input wire time_limit_0 ,
    input wire time_limit_1 ,

    output reg [3:0] time_left_minute_tens, 
    output reg [3:0] time_left_minute_ones, 

    output reg [3:0] time_left_sec_tens, 
    output reg [3:0] time_left_sec_ones, 

    output reg [3:0] time_left_micro_sec_tens,
    output reg [3:0] time_left_micro_sec_ones,

    output wire one_min_left,
    output wire ten_sec_left,
    output wire time_out
);
//==============================================================
//state_define
//==============================================================
    parameter IDLE = 3'b000;
    parameter ATIVATING = 3'b001;
    parameter ATIVATED = 3'b010;
    parameter DETONATING = 3'b011;
    parameter MISSION_FAILED = 3'b100;
    parameter MISSION_SUCCESSED = 3'b101 ;

    parameter LONG_TIME = 4'd10 ;
    parameter MEDIUM_TIME = 4'd5 ;
    parameter SHORT_TIME = 4'd3 ;

//==============================================================
//Timmer
//==============================================================

    reg [3:0] select_time ; // 這裡你之後可改成依難度/輸入選擇

    always @(*) begin
        case ({time_limit_1 , time_limit_0})
            2'b00: begin
                select_time = LONG_TIME;
            end
            2'b01: begin
                select_time = MEDIUM_TIME;
            end
            2'b10: begin
                select_time = SHORT_TIME;
            end
            default: begin
                select_time = LONG_TIME;
            end
        endcase
    end

    // 零旗標
    wire micro_sec_zero = ((time_left_micro_sec_tens == 4'd0) && (time_left_micro_sec_ones == 4'd0)) ? 1'd1 : 1'd0;
    wire sec_zero = ((time_left_sec_tens == 4'd0) && (time_left_sec_ones == 4'd0)) ? 1'd1 : 1'd0;
    wire min_zero = ((time_left_minute_tens == 4'd0) && (time_left_minute_ones == 4'd0)) ? 1'd1 : 1'd0;
    // 時間節點
    assign one_min_left = (min_zero);
    assign ten_sec_left = ((time_left_micro_sec_tens == 4'd0) && (min_zero))  ; 
    assign time_out = ((micro_sec_zero) && (sec_zero) && (min_zero)) ? 1'b1 : 1'b0 ; 
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            time_left_micro_sec_tens <= 4'd0;
            time_left_micro_sec_ones <= 4'd0;
            time_left_sec_tens       <= 4'd0;
            time_left_sec_ones       <= 4'd0;
            time_left_minute_tens    <= 4'd0;
            time_left_minute_ones    <= 4'd0;
        end else begin

            case (current_state)

                // 載入初始時間：mm:00:00 (mm 由 select_time 決定)
                ATIVATING: begin
                    time_left_micro_sec_tens <= 4'd0;
                    time_left_micro_sec_ones <= 4'd0;
                    time_left_sec_tens       <= 4'd0;
                    time_left_sec_ones       <= 4'd0;

                    // select_time (0~15) -> BCD tens/ones
                    time_left_minute_tens    <= (select_time >= 4'd10) ? 4'd1 : 4'd0;
                    time_left_minute_ones    <= (select_time >= 4'd10) ? (select_time - 4'd10) : select_time;
                end

                // 倒數：每個 100Hz tick 減 1 個 centisecond (00~99)
                ATIVATED: begin
                    if (tick_10ms) begin
                        // 如果已經到 00:00:00 就停住
                        if ( time_out ) begin
                            // hold
                            time_left_micro_sec_tens <= time_left_micro_sec_tens;
                            time_left_micro_sec_ones <= time_left_micro_sec_ones;
                            time_left_sec_tens       <= time_left_sec_tens;
                            time_left_sec_ones       <= time_left_sec_ones;
                            time_left_minute_tens    <= time_left_minute_tens;
                            time_left_minute_ones    <= time_left_minute_ones;
                        end else begin

                            // -------- micro_sec (00~99) --------
                            if (time_left_micro_sec_ones != 4'd0) begin
                                time_left_micro_sec_ones <= time_left_micro_sec_ones - 4'd1;
                            end else begin
                                if (time_left_micro_sec_tens != 4'd0) begin
                                    time_left_micro_sec_ones <= 4'd9;
                                    time_left_micro_sec_tens <= time_left_micro_sec_tens - 4'd1;
                                end else if ((!min_zero) || (!sec_zero)) begin
                                    // 00 -> 99 並向 sec 借位
                                    time_left_micro_sec_ones <= 4'd9;
                                    time_left_micro_sec_tens <= 4'd9;
                                end else begin
                                    time_left_micro_sec_ones <= time_left_micro_sec_ones;
                                    time_left_micro_sec_tens <= time_left_micro_sec_tens;
                                end
                            end

                            // -------- sec (00~59) --------
                            if (micro_sec_zero) begin
                                if (time_left_sec_ones != 4'd0) begin
                                    time_left_sec_ones <= time_left_sec_ones - 4'd1;
                                end else begin
                                    if (time_left_sec_tens != 4'd0) begin
                                        time_left_sec_ones <= 4'd9;
                                        time_left_sec_tens <= time_left_sec_tens - 4'd1;
                                    end else if (!min_zero )begin
                                        // 00 -> 59 並向 min 借位
                                        time_left_sec_ones <= 4'd9;
                                        time_left_sec_tens <= 4'd5;
                                    end else begin
                                        time_left_sec_ones <= time_left_sec_ones;
                                        time_left_sec_tens <= time_left_sec_tens;
                                    end
                                end
                            end

                            // -------- minute (00~99) --------
                            if (sec_zero && micro_sec_zero) begin
                                if (time_left_minute_ones != 4'd0) begin
                                    time_left_minute_ones <= time_left_minute_ones - 4'd1;
                                    time_left_minute_tens <= time_left_minute_tens;
                                end else begin
                                    if (time_left_minute_tens != 4'd0) begin
                                        time_left_minute_ones <= 4'd9;
                                        time_left_minute_tens <= time_left_minute_tens - 4'd1;
                                    end else begin
                                        // 理論上不會進來（因為全 0 已被擋），保險 hold
                                        time_left_minute_ones <= time_left_minute_ones;
                                        time_left_minute_tens <= time_left_minute_tens;
                                    end
                                end
                            end
                        end
                    end else begin
                        time_left_micro_sec_tens <= time_left_micro_sec_tens;
                        time_left_micro_sec_ones <= time_left_micro_sec_ones;
                        time_left_sec_tens       <= time_left_sec_tens;
                        time_left_sec_ones       <= time_left_sec_ones;
                        time_left_minute_tens    <= time_left_minute_tens;
                        time_left_minute_ones    <= time_left_minute_ones;
                    end
                end

                DETONATING , MISSION_FAILED , MISSION_SUCCESSED : begin
                        time_left_micro_sec_tens <= time_left_micro_sec_tens;
                        time_left_micro_sec_ones <= time_left_micro_sec_ones;
                        time_left_sec_tens       <= time_left_sec_tens;
                        time_left_sec_ones       <= time_left_sec_ones;
                        time_left_minute_tens    <= time_left_minute_tens;
                        time_left_minute_ones    <= time_left_minute_ones;
                end

                default: begin
                    // 其他狀態：保持不變
                    //time_left_micro_sec_tens <= time_left_micro_sec_tens;
                    time_left_micro_sec_tens <= time_left_micro_sec_tens;
                    time_left_micro_sec_ones <= time_left_micro_sec_ones;
                    time_left_sec_tens       <= time_left_sec_tens;
                    time_left_sec_ones       <= time_left_sec_ones;
                    time_left_minute_tens    <= time_left_minute_tens;
                    time_left_minute_ones    <= time_left_minute_ones;
                end

            endcase
        end
    end
    
endmodule 