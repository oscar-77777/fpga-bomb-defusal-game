// ============================================================
// LCD1602A 4-bit Driver (HD44780 compatible)
// - Show: "password:" + password[0..4] on 2nd line, right aligned
// - Continuously refresh
// ============================================================

module LCD1602A #(
    parameter integer CLK_HZ = 50_000_000
)(
    input  wire        clk,
    input  wire        rst,          // active-low reset
    input  wire        tick_1us,

    // 顯示密碼 (ASCII bytes)
    input  [7:0] password_0,
    input  [7:0] password_1,
    input  [7:0] password_2,
    input  [7:0] password_3,
    input  [7:0] password_4,

    input  [7:0] mos_char_0,
    input  [7:0] mos_char_1,
    input  [7:0] mos_char_2,

    output reg         lcd_rs,
    output reg         lcd_en,
    output reg  [3:0]  lcd_data
);


    // ============================================================
    // LCD command/data sender (4-bit, no busy-flag read)
    // ============================================================
    localparam S_IDLE      = 4'd0;
    localparam S_EN_HI     = 4'd2;
    localparam S_EN_LO     = 4'd3;
    localparam S_SEND_LN   = 4'd4 ;
    localparam S_EN2_HI    = 4'd5;
    localparam S_EN2_LO    = 4'd6;
    localparam S_WAIT_DONE = 4'd7;
    localparam S_POST_WAIT = 4'd8;   // 新增：指令/資料送完後的busy等待

    reg [3:0]  send_state;
    reg [15:0] wait_us;
    reg [7:0]  send_byte;
    reg        send_is_data;    // 0=command, 1=data
    reg        send_req;
    reg        send_busy;
    reg        send_done;

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

                            // ★重點：送完一個byte後，依類型決定busy等待
                            if (!send_is_data && (send_byte == 8'h01 || send_byte == 8'h02))
                                post_wait_us <= WAIT_US_CLEAR;
                            else
                                post_wait_us <= WAIT_US_NORMAL;

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

    // ============================================================
    // Init + periodic update FSM
    // ============================================================
    localparam I_BOOT_WAIT    = 6'd0;
    localparam I_33           = 6'd1;
    localparam I_32           = 6'd2;
    localparam I_FUNC_SET     = 6'd3;
    localparam I_DISP_ON      = 6'd4;
    localparam I_ENTRY_MODE   = 6'd5;
    localparam I_CLEAR        = 6'd6;
    localparam I_READY        = 6'd7;

    localparam I_SET_ADDR_L2  = 6'd8;
    localparam I_W_pwd_0           = 6'd9;   // 'p'
    localparam I_W_pwd_1           = 6'd10;  // 'a'
    localparam I_W_pwd_2           = 6'd11;  // 's'
    localparam I_W_pwd_3           = 6'd12;  // 's'
    localparam I_W_pwd_4           = 6'd13;  // 'w'
    localparam I_W_pwd_5           = 6'd14;  // 'o'
    localparam I_W_pwd_6           = 6'd15;  // 'r'
    localparam I_W_pwd_7           = 6'd16;  // 'd'
    localparam I_W_pwd_8           = 6'd17;  // ':'
    localparam I_W_pwd_9           = 6'd18;  // pw[0]
    localparam I_W_pwd_10          = 6'd19;  // pw[1]
    localparam I_W_pwd_11          = 6'd20;  // pw[2]
    localparam I_W_pwd_12          = 6'd21;  // pw[3]
    localparam I_W_pwd_13          = 6'd22;  // pw[4]
    localparam I_WAIT_REFRESH      = 6'd23;
    localparam I_IDLE              = 6'd24;
    localparam I_SPACE_0           = 6'd25;
    localparam I_SPACE_1           = 6'd26;

    localparam I_W_mos_0           = 6'd27;   
    localparam I_W_mos_1           = 6'd28;    
    localparam I_W_mos_2           = 6'd29;    
    localparam I_W_mos_3           = 6'd30;    
    localparam I_W_mos_4           = 6'd31;    
    localparam I_W_mos_5           = 6'd32;    
    localparam I_W_mos_6           = 6'd33;    
    localparam I_W_mos_7           = 6'd34;    
    localparam I_W_mos_8           = 6'd35;    
    localparam I_W_mos_9           = 6'd36;    
    localparam I_W_mos_10          = 6'd37;    
    localparam I_W_mos_11          = 6'd38;   
    localparam I_W_mos_12          = 6'd39; 
    localparam I_W_mos_13          = 6'd41;    
    localparam I_W_mos_14          = 6'd42; 
    localparam I_W_mos_15          = 6'd43;   
    localparam I_SET_ADDR_L1       = 6'd40;   
        



    reg [5:0]  lcd_operate;
    reg [31:0] delay_us;

    // refresh period (us) : 50ms
    localparam integer REFRESH_US = 50_000;

    // Helper task-like: start sending one byte
    // (用 if 判斷，避免 task)
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            lcd_operate           <= I_BOOT_WAIT;
            delay_us     <= 32'd20000; // 20ms
            send_req     <= 1'b0;
            send_byte    <= 8'h00;
            send_is_data <= 1'b0;
        end else begin
            if (send_done) send_req <= 1'b0;

            case (lcd_operate)
                // ============================================================
                // 等待上電
                // ============================================================
                I_BOOT_WAIT: begin
                    if (tick_1us) begin
                        if (delay_us != 0) delay_us <= delay_us - 1'b1;
                        else lcd_operate <= I_FUNC_SET;
                    end
                end
                // ============================================================
                // 4_bits模式
                // ============================================================
                I_FUNC_SET: begin
                    if (!send_busy && !send_req) begin
                        send_is_data <= 1'b0; send_byte <= 8'h28; send_req <= 1'b1;
                    end
                    if (send_done) lcd_operate <= I_DISP_ON;
                end
                // ============================================================
                // 游標
                // ============================================================
                I_DISP_ON: begin
                    if (!send_busy && !send_req) begin
                        send_is_data <= 1'b0; 
                        send_byte <= 8'h0C; 
                        // send_byte <= 8'h0F; //debug
                        send_req <= 1'b1;
                    end
                    if (send_done) lcd_operate <= I_ENTRY_MODE;
                    // if (send_done) st <= I_IDLE;
                end
                // ============================================================
                // 位移
                // ============================================================
                I_ENTRY_MODE: begin
                    if (!send_busy && !send_req) begin
                        send_is_data <= 1'b0; send_byte <= 8'h06; send_req <= 1'b1;
                    end
                    if (send_done) lcd_operate <= I_CLEAR;
                end

                I_CLEAR: begin
                    if (!send_busy && !send_req) begin
                        send_is_data <= 1'b0; send_byte <= 8'h01; send_req <= 1'b1;
                    end
                    if (send_done) begin
                        delay_us <= 32'd2000;
                        lcd_operate <= I_READY;
                    end
                end

                I_READY: begin
                    if (tick_1us && delay_us!=0) delay_us <= delay_us - 1'b1;
                    if (delay_us==0) lcd_operate <= I_SET_ADDR_L1;
                end

                // !nd line, right-aligned start col=2 => cmd 0xC2
                I_SET_ADDR_L1: begin
                    if (!send_busy && !send_req) begin
                        send_is_data <= 1'b0;
                        send_byte    <= 8'h80;
                        send_req     <= 1'b1;
                    end
                    if (send_done) lcd_operate <= I_W_mos_0;
                end

                // write "Morse:" (9 chars)
                I_W_mos_0:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="f"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_1;  end
                I_W_mos_1:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="r"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_2;  end
                I_W_mos_2:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="e"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_3;  end
                I_W_mos_3:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="q"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_4;  end
                I_W_mos_4:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=":"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_5;  end
                I_W_mos_5:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=" "; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_6;  end
                I_W_mos_6:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=" "; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_7;  end
                I_W_mos_7:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=" "; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_8;  end
                I_W_mos_8:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="3"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_9;  end
                I_W_mos_9:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="."; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_10;  end
                
                I_W_mos_10:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=mos_char_0; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_11;  end
                I_W_mos_11:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=mos_char_1; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_12;  end
                I_W_mos_12: begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=mos_char_2; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_13;  end

                // write password[0..4] (low->high index, left->right)
                I_W_mos_13: begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="M"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_14; end
                I_W_mos_14: begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="H"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_mos_15; end
                I_W_mos_15: begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="z"; send_req<=1'b1; end if (send_done) lcd_operate<=I_SET_ADDR_L2; end
                

                // 2nd line, right-aligned start col=2 => cmd 0xC2
                I_SET_ADDR_L2: begin
                    if (!send_busy && !send_req) begin
                        send_is_data <= 1'b0;
                        send_byte    <= 8'hC0;
                        send_req     <= 1'b1;
                    end
                    if (send_done) lcd_operate <= I_W_pwd_0;
                end

                // write "password:" (9 chars)
                I_W_pwd_0:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="p"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_1;  end
                // I_W0:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="p"; send_req<=1'b1; end if (send_done) st<=I_IDLE;  end
                I_W_pwd_1:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="a"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_2;  end
                I_W_pwd_2:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="s"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_3;  end
                I_W_pwd_3:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="s"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_4;  end
                I_W_pwd_4:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="w"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_5;  end
                I_W_pwd_5:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="o"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_6;  end
                I_W_pwd_6:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="r"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_7;  end
                I_W_pwd_7:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<="d"; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_8;  end
                I_W_pwd_8:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=":"; send_req<=1'b1; end if (send_done) lcd_operate<=I_SPACE_0;  end
                
                I_SPACE_0:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=" "; send_req<=1'b1; end if (send_done) lcd_operate<=I_SPACE_1;  end
                I_SPACE_1:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=" "; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_9;  end

                // write password[0..4] (low->high index, left->right)
                I_W_pwd_9:  begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=password_0; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_10; end
                I_W_pwd_10: begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=password_1; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_11; end
                I_W_pwd_11: begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=password_2; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_12; end
                I_W_pwd_12: begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=password_3; send_req<=1'b1; end if (send_done) lcd_operate<=I_W_pwd_13; end
                I_W_pwd_13: begin if (!send_busy && !send_req) begin send_is_data<=1'b1; send_byte<=password_4; send_req<=1'b1; end if (send_done) begin
                            delay_us <= REFRESH_US;
                            lcd_operate <= I_WAIT_REFRESH;
                        end end

                // wait then refresh again (continuous update)
                I_WAIT_REFRESH: begin
                    if (tick_1us) begin
                        if (delay_us != 0) delay_us <= delay_us - 1'b1;
                        else lcd_operate <= I_SET_ADDR_L1;
                        // else st <= I_CLEAR;
                    end
                end

                I_IDLE: begin
                    lcd_operate <= I_IDLE;
                end

                default: lcd_operate <= I_BOOT_WAIT;
            endcase
        end
    end

endmodule
