// ============================================================
// LCD2004A Driver (HD44780 compatible, 4-bit interface)
// - Display serial number (6 ASCII chars)
// - Example prints "SN:" + 6 chars
// - No busy-flag read; use send_wait_us post delay
//
// Wiring (4-bit):
//   LCD D4..D7 <-> lcd_data[0]..lcd_data[3]  (or mapping via assign, see note below)
//   RS -> lcd_rs, EN -> lcd_en, RW -> GND
// ============================================================

module LCD2004A #(
    parameter integer CLK_HZ = 50_000_000
)(
    input  wire        clk,
    input  wire        rst,            // active-low reset
    input  wire        tick_1us,
    input  wire [2:0]  current_state,
//==============================================================
// 顯示序號
//==============================================================
    input  wire [47:0] serial_number,
    input  wire        serial_done,
//==============================================================
// 顯示機會
//==============================================================
    input  wire [7:0] chance_left_ascii,

    input  wire [479:0] msg,   // 60 ASCII chars, msg[479:472] is char0

    output reg         lcd_rs,
    output reg         lcd_en,
    output reg  [3:0]  lcd_data,

    output reg         activated
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

    // ============================================================
    // Low-level 4-bit send engine
    // - Send 1 byte as 2 nibbles (HI then LO), each with EN pulse
    // - Post delay = send_wait_us (set by upper FSM)
    // ============================================================
    localparam S_IDLE       = 3'd0;
    localparam S_EN_HI      = 3'd1;
    localparam S_EN_LO      = 3'd2;
    localparam S_SEND_LN    = 4'd3;
    localparam S_EN2_HI     = 3'd4;
    localparam S_EN2_LO     = 3'd5;
    localparam S_POST_WAIT  = 3'd6;
    localparam S_WAIT_DONE  = 3'd7;

    reg [2:0]  send_state;
    reg [15:0] wait_us;

    reg [7:0]  send_byte;
    reg        send_is_data;
    reg        send_req;
    reg        send_busy;
    reg        send_done;

    // reg [15:0] send_wait_us;
    localparam integer PULSE_US = 2;
    localparam integer WAIT_US_NORMAL = 40;    // >=39us
    localparam integer WAIT_US_CLEAR  = 2000;  // >=1.53ms, 保守

    reg [15:0] post_wait_us;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            lcd_rs     <= 1'b0;
            lcd_en     <= 1'b0;
            lcd_data   <= 4'h0;

            send_state <= S_IDLE;
            send_busy  <= 1'b0;
            send_done  <= 1'b0;
            wait_us    <= 16'd0;
            post_wait_us <= 16'd0;
        end else begin
            send_done <= 1'b0;

            case (send_state)
                S_IDLE: begin
                    lcd_en <= 1'b0;
                    if (send_req) begin
                        send_busy  <= 1'b1;
                        lcd_rs     <= send_is_data;

                        // 先送 high nibble
                        lcd_data   <= send_byte[7:4];
                        wait_us    <= PULSE_US;
                        send_state <= S_EN_HI;
                    end else begin
                        send_busy <= 1'b0;
                    end
                end

                S_EN_HI: begin
                    if (tick_1us) begin
                        if (wait_us != 0) wait_us <= wait_us - 1'b1;
                        else begin
                            lcd_en     <= 1'b1;
                            wait_us    <= PULSE_US;
                            send_state <= S_EN_LO;
                        end
                    end
                end

                S_EN_LO: begin
                    if (tick_1us) begin
                        if (wait_us != 0) wait_us <= wait_us - 1'b1;
                        else begin
                            lcd_en     <= 1'b0;
                            // 這裡不用 lcd_data<=lcd_data; 保持即可
                            wait_us    <= PULSE_US;
                            send_state <= S_SEND_LN;
                        end
                    end
                end

                // EN 變低後稍等，再換 low nibble（避免hold time疑慮）
                S_SEND_LN: begin
                    if (tick_1us) begin
                        if (wait_us != 0) wait_us <= wait_us - 1'b1;
                        else begin
                            lcd_en     <= 1'b0;
                            lcd_data   <= send_byte[3:0];
                            wait_us    <= PULSE_US;
                            send_state <= S_EN2_HI;
                        end
                    end
                end

                S_EN2_HI: begin
                    if (tick_1us) begin
                        if (wait_us != 0) wait_us <= wait_us - 1'b1;
                        else begin
                            lcd_en     <= 1'b1;
                            wait_us    <= PULSE_US;
                            send_state <= S_EN2_LO;
                        end
                    end
                end

                S_EN2_LO: begin
                    if (tick_1us) begin
                        if (wait_us != 0) wait_us <= wait_us - 1'b1;
                        else begin
                            lcd_en <= 1'b0;
                            // post_wait_us <= send_wait_us;
                            // ★重點：送完一個byte後，依類型決定busy等待
                            if ((phase == P_33) || (phase == P_32) ||    (phase == P_CLEAR)) begin
                                post_wait_us <= WAIT_US_CLEAR;
                            end else begin
                                post_wait_us <= WAIT_US_NORMAL;
                            end
                            send_state <= S_POST_WAIT;
                        end
                    end
                end

                // ★新增：busy等待（不讀busy flag，用時間硬等）
                S_POST_WAIT: begin
                    if (tick_1us) begin
                        if (post_wait_us != 0) begin
                            post_wait_us <= post_wait_us - 1'b1;
                        end else begin
                            send_done  <= 1'b1;       // 等完才發done
                            send_state <= S_WAIT_DONE;
                        end
                    end
                end

                S_WAIT_DONE: begin
                    // 等上層把 send_req 放掉（避免重送）
                    if (!send_req) begin
                        send_state <= S_IDLE;
                    end
                end

                default: send_state <= S_IDLE;
            endcase
        end
    end

    // 取第 k 個字元 (0..59)，msg[479:472] 是第0個字
    function automatic [7:0] msg_char(input [5:0] k);
    begin
        msg_char = msg[479 - 8*k -: 8];
    end
    endfunction

    // 取 SN 要印的第 k 個字元 (0..9): "SN:" + " " + 6 chars
    function automatic [7:0] sn_char(input [3:0] k, input [47:0] sn);
    begin
        case (k)
            4'd0: sn_char = "S";
            4'd1: sn_char = "N";
            4'd2: sn_char = ":";
            4'd3: sn_char = " ";
            4'd4: sn_char = sn[47:40];
            4'd5: sn_char = sn[39:32];
            4'd6: sn_char = sn[31:24];
            4'd7: sn_char = sn[23:16];
            4'd8: sn_char = sn[15:8];
            4'd9: sn_char = sn[7:0];
            default: sn_char = " ";
        endcase
    end
    endfunction
    // line1: SN + right-aligned chance
    // col: 0..19
    function automatic [7:0] line1_char(input [4:0] col, input [47:0] sn, input [7:0] ch);
    begin
        if (col <= 5'd9) begin
            // col 0..9: SN:"SN: " + 6 chars
            line1_char = sn_char(col[3:0], sn);
        end else if (col >= 5'd11 && col <= 5'd17) begin
            // col 11..17: "chance:"
            case (col)
                5'd11: line1_char = "c";
                5'd12: line1_char = "h";
                5'd13: line1_char = "a";
                5'd14: line1_char = "n";
                5'd15: line1_char = "c";
                5'd16: line1_char = "e";
                5'd17: line1_char = ":";
                default: line1_char = " ";
            endcase
        end else if (col == 5'd18) begin
            // col 18: space
            line1_char = " ";
        end else if (col == 5'd19) begin
            // col 19 (rightmost): digit
            line1_char = ch;
        end else begin
            // other cols (10): spaces
            line1_char = " ";
        end
    end
    endfunction

    // ============================================================
    // High-level FSM: init once, then refresh loop
    // Line address (20x4 typical):
    // L1: 0x80, L2: 0xC0, L3: 0x94, L4: 0xD4
    // ============================================================
    localparam P_BOOT_WAIT   = 6'd0;
    localparam P_33          = 6'd1;
    localparam P_32          = 6'd2;
    localparam P_FUNC_SET_4  = 6'd3;
    localparam P_DISP_ON     = 6'd4;
    localparam P_ENTRY_MODE  = 6'd5;
    localparam P_CLEAR       = 6'd6;
    localparam P_READY       = 6'd7;

    // refresh loop phases
    localparam P_SET_L1      = 6'd8;
    localparam P_WRITE_SN    = 6'd9;
    localparam P_SET_L2      = 6'd10;
    localparam P_WRITE_MSG   = 6'd11;
    localparam P_DELAY       = 6'd12;

    reg [5:0] phase;
    reg [31:0] delay_us;

    // counters
    reg [4:0] sn_i;        // 0..9
    reg [5:0] msg_i;       // 0..59
    reg newline_pending; // 1=剛送完換行cmd，下一拍要印同一個msg_i的字

    // latch
    reg [47:0] serial_latched;

    localparam integer REFRESH_WAIT_US = 200_000; // 200ms (你可改 100ms=100_000)


    // control FSM
    always @(posedge clk or negedge rst) begin
    if (!rst) begin
        phase          <= P_BOOT_WAIT;
        delay_us       <= 32'd20000; // 20ms power-up wait

        send_req       <= 1'b0;
        send_is_data   <= 1'b0;
        send_byte      <= 8'h00;

        activated      <= 1'b0;

        sn_i           <= 5'd0;
        msg_i          <= 6'd0;
        newline_pending <= 1'b0;
        serial_latched <= 48'h303030303030; // "000000"
    end else begin
        // free-running delay counter
        if (tick_1us) begin
            if (delay_us != 0) delay_us <= delay_us - 1'b1;
        end

        // drop request after engine completes one send
        if (send_done) send_req <= 1'b0;

        // 只在 ACTIVATING/ACTIVATED 顯示更新（你想一直顯示也可以把條件拿掉）
        case (current_state)
            IDLE : begin
                case (phase)
                    P_BOOT_WAIT: begin
                        if (delay_us == 0) phase <= P_33;
                    end

                    P_33: begin
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'h33;
                        end
                        if (send_done) phase <= P_32;
                    end

                    P_32: begin
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'h32;
                        end
                        if (send_done) phase <= P_FUNC_SET_4;
                    end

                    P_FUNC_SET_4: begin
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'h28; // 4-bit, 2-line, 5x8
                        end
                        if (send_done) phase <= P_DISP_ON;
                    end

                    P_DISP_ON: begin
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'h0C;
                        end
                        if (send_done) phase <= P_ENTRY_MODE;
                    end

                    P_ENTRY_MODE: begin
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'h06;
                        end
                        if (send_done) phase <= P_CLEAR;
                    end

                    P_CLEAR: begin
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'h01;
                        end
                        if (send_done) phase <= P_SET_L2;
                    end 

                    // ---------------- refresh loop ----------------
                    P_SET_L2: begin
                        activated <= 1'b1;
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'hC0; // line2 col0
                        end
                        if (send_done) begin
                            msg_i <= 6'd0;
                            phase <= P_WRITE_MSG;
                        end
                    end

                    P_WRITE_MSG: begin
                        if (!send_busy && !send_req) begin
                            send_req <= 1'b1;

                            // 如果正要在第20/40字換行，且「還沒換行過」
                            if (!newline_pending && (msg_i == 6'd20)) begin
                                send_is_data <= 1'b0;
                                send_byte    <= 8'h94; // line3 col0
                            end else if (!newline_pending && (msg_i == 6'd40)) begin
                                send_is_data <= 1'b0;
                                send_byte    <= 8'hD4; // line4 col0
                            end else begin
                                // 否則就正常印字
                                send_is_data <= 1'b1;
                                send_byte    <= msg_char(msg_i);
                            end
                        end

                        if (send_done) begin
                            // 如果這拍剛送的是換行cmd：不要吃字，設 pending，下一拍印同一個 msg_i
                            if (!newline_pending && (msg_i == 6'd20 || msg_i == 6'd40)) begin
                                newline_pending <= 1'b1;
                            end else begin
                                // 這拍是真的印了字（或是剛印完字後），pending 清掉
                                newline_pending <= 1'b0;

                                if (msg_i == 6'd59) begin
                                    delay_us <= REFRESH_WAIT_US;
                                    phase    <= P_DELAY;
                                end else begin
                                    msg_i <= msg_i + 1'b1;
                                end
                            end
                        end
                    end

                    P_DELAY: begin
                        // 等完再回到第一行重刷（也順便重新 latch 序號）
                        if (delay_us == 0) begin
                            msg_i <= 6'd0;
                            phase <= P_SET_L2;
                        end
                    end

                    default: phase <= P_READY;

                endcase
                
            end
            ACTIVATING , ACTIVATED , DETONATING, MISSION_FAILED, MISSION_SUCCESSED: begin
                case (phase)

                    // ---------------- init sequence (run once) ----------------
                    P_CLEAR: begin
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'h01;
                        end
                        if (send_done) phase <= P_READY;
                    end

                    // ---------------- after init, wait serial_done then loop refresh ----------------
                    P_READY: begin
                        
                        if (serial_done) begin
                            serial_latched <= serial_number; // 每輪開始前先 latch 一次
                            sn_i <= 5'd0;
                            msg_i <= 6'd0;
                            phase <= P_SET_L1;
                        end
                    end

                    // ---------------- refresh loop ----------------
                    P_SET_L1: begin
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'h80; // line1 col0
                        end
                        if (send_done) begin
                            sn_i <= 5'd0;
                            phase <= P_WRITE_SN;
                        end
                    end
                    P_WRITE_SN: begin
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b1;
                            send_byte    <= line1_char(sn_i, serial_latched, chance_left_ascii);
                        end
                        if (send_done) begin
                            if (sn_i == 5'd19) begin
                                phase <= P_SET_L2;
                            end else begin
                                sn_i <= sn_i + 1'b1;
                            end
                        end
                    end
                    P_SET_L2: begin
                        activated <= 1'b1;
                        if (!send_busy && !send_req) begin
                            send_req     <= 1'b1;
                            send_is_data <= 1'b0;
                            send_byte    <= 8'hC0; // line2 col0
                        end
                        if (send_done) begin
                            msg_i <= 6'd0;
                            phase <= P_WRITE_MSG;
                        end
                    end

                    P_WRITE_MSG: begin
                        if (!send_busy && !send_req) begin
                            send_req <= 1'b1;

                            // 如果正要在第20/40字換行，且「還沒換行過」
                            if (!newline_pending && (msg_i == 6'd20)) begin
                                send_is_data <= 1'b0;
                                send_byte    <= 8'h94; // line3 col0
                            end else if (!newline_pending && (msg_i == 6'd40)) begin
                                send_is_data <= 1'b0;
                                send_byte    <= 8'hD4; // line4 col0
                            end else begin
                                // 否則就正常印字
                                send_is_data <= 1'b1;
                                send_byte    <= msg_char(msg_i);
                            end
                        end

                        if (send_done) begin
                            // 如果這拍剛送的是換行cmd：不要吃字，設 pending，下一拍印同一個 msg_i
                            if (!newline_pending && (msg_i == 6'd20 || msg_i == 6'd40)) begin
                                newline_pending <= 1'b1;
                            end else begin
                                // 這拍是真的印了字（或是剛印完字後），pending 清掉
                                newline_pending <= 1'b0;

                                if (msg_i == 6'd59) begin
                                    delay_us <= REFRESH_WAIT_US;
                                    phase    <= P_DELAY;
                                end else begin
                                    msg_i <= msg_i + 1'b1;
                                end
                            end
                        end
                    end

                    P_DELAY: begin
                        // 等完再回到第一行重刷（也順便重新 latch 序號）
                        if (delay_us == 0) begin
                            serial_latched <= serial_number; // 如果序號會變，這裡每輪更新
                            sn_i <= 4'd0;
                            msg_i <= 6'd0;
                            phase <= P_SET_L1;
                        end
                    end

                    default: phase <= P_READY;

            endcase
            end
        endcase
           
    end
end


    

endmodule
