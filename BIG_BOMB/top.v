//`include "free_counter.v"
//`include "FSM.v"
//`include "Center_Timmer.v"
module top ( 
    input clk , 
    input adc_clk,
    input rst ,
    input activate ,
// ===== timming input =====
    input time_limit_1,
    input time_limit_0,
// ===== chance input  =====
    input chance_limit_1,
    input chance_limit_0,
// ===== password bottom =====
    input pwd_btn_up_0,
    input pwd_btn_down_0,
    input pwd_btn_up_1,
    input pwd_btn_down_1,
    input pwd_btn_up_2,
    input pwd_btn_down_2,
    input pwd_btn_up_3,
    input pwd_btn_down_3,
    input pwd_btn_up_4,
    input pwd_btn_down_4,
    input pwd_btn_submit,
// ===== memory bottom =====
    input mem_btn_1,
    input mem_btn_2,
    input mem_btn_3,
    input mem_btn_4,
// ===== 7-seg output (active low) =====
    output [6:0] T_HEX0,   // micro_sec ones
    output [6:0] T_HEX1,   // micro_sec tens
    output [6:0] T_HEX2,   // sec ones
    output [6:0] T_HEX3,   // sec tens
    output [6:0] T_HEX4,   // minute ones
    output [6:0] T_HEX5,   // minute tens
    output [5:0] T_DP,
    output tm1367_clk,
    inout tm1367_dio,
    output [7:0] mem_seven_digit,
// ===== LCD_1602A output =====
    output       lcd_1602a_rs_w,
    output       lcd_1602a_en_w,
    output [3:0] lcd_1602a_data_w,
// ===== LCD_2004A output =====
    output       lcd_2004a_rs_w,
    output       lcd_2004a_en_w,
    output [3:0] lcd_2004a_data_w,
// =====       Maze       =====
    output maze_dout ,
    output btn1,
    output btn2,
    output btn3,
    output btn4,
    
// =============================
    output       buzzer_out,   
// =====       Wires      =====
    input [5:0] wires_num,
// =====   Finished LED   =====
    output mem_finished_LED,
    output wires_finished_LED,
    output morse_finished_LED,
    output pwd_finished_LED,
    output maze_finished_LED

); 

//==============================================================
//Controler
//==============================================================
    //==============================================================
    //FSM
    //==============================================================
    wire [2:0] current_state ;
    FSM FSM 
    (
        .clk(clk) , 
        .rst(rst) ,
        .activate(activate) ,
        .current_state(current_state) ,
        .explode(explode),
        .LCD_activated(LCD_2004a_activated) ,
        .Wires_activated(wires_activated),
        .Passwords_activated(pwd_activated) ,
        .Memorys_activated(mem_activated),
        .Maze_activated(maze_activated),
        .Mos_code_activated(mos_activated)
    );


//==============================================================
//Timming
//==============================================================
    //==============================================================
    //center_timmer
    //==============================================================
    wire [3:0] time_left_minute_tens;
    wire [3:0] time_left_minute_ones;

    wire [3:0] time_left_sec_tens;
    wire [3:0] time_left_sec_ones;

    wire [3:0] time_left_micro_sec_tens;
    wire [3:0] time_left_micro_sec_ones;

    wire time_out;
    wire one_min_left;
    wire ten_sec_left;

    Center_Timmer Center_Timmer_u (
        .clk(clk),
        .rst(rst),
        .tick_10ms(tick_10ms),
        .time_limit_1(time_limit_1),
        .time_limit_0(time_limit_0),

        .current_state(current_state),
        
        .time_left_minute_tens(time_left_minute_tens),
        .time_left_minute_ones(time_left_minute_ones),

        .time_left_sec_tens(time_left_sec_tens),
        .time_left_sec_ones(time_left_sec_ones),

        .time_left_micro_sec_tens(time_left_micro_sec_tens),
        .time_left_micro_sec_ones(time_left_micro_sec_ones),
        .one_min_left(one_min_left),
        .ten_sec_left(ten_sec_left),
        .time_out(time_out)
    );
    //==============================================================
    //Timmer_Seven_desplay
    //==============================================================
    Seven_Display_on_Board u_sevenseg (
        .time_left_minute_tens(time_left_minute_tens),
        .time_left_minute_ones(time_left_minute_ones),

        .time_left_sec_tens(time_left_sec_tens),
        .time_left_sec_ones(time_left_sec_ones),

        .time_left_micro_sec_tens(time_left_micro_sec_tens),
        .time_left_micro_sec_ones(time_left_micro_sec_ones),

        .HEX_0(T_HEX0),
        .HEX_1(T_HEX1),
        .HEX_2(T_HEX2),
        .HEX_3(T_HEX3),
        .HEX_4(T_HEX4),
        .HEX_5(T_HEX5),
        .DP(T_DP)
    );
    //==============================================================
    //tick generator
    //==============================================================
    wire tick_1us;
    wire tick_10ms;
    wire tick_1sec;
    tick_generator #(
        .CLK_HZ(50_000_000)
    )   tick_gen_u (
        .clk(clk),
        .rst(rst),
        .tick_1us(tick_1us),
        .tick_10ms(tick_10ms),
        .tick_1sec(tick_1sec)
    );


//==============================================================
//generate_Serial_Number
//==============================================================
    //==============================================================
    //free_counter
    //==============================================================
        wire [31:0] free_cnt ;
        free_counter fc_1 
        (
            .clk(clk) , 
            .rst(rst) ,
            .free_cnt(free_cnt)
        );
    //==============================================================
    //random_number
    //==============================================================    
        wire [31:0] rnd;
        random_number u_rng (
            .clk(clk),
            .rst(rst),
            // .activate(activate),
            .current_state(current_state),
            .free_cnt(free_cnt),
            .rnd(rnd)
        );
    //==============================================================
    // Serial_Number Generator
    //==============================================================
        wire [47:0] serial_number;
        wire        serial_done;
        wire        sn_last_pos_odd;

        Random_Serial_Number u_serial (
            .clk          (clk),
            .rst          (rst),
            .current_state(current_state),
            .rnd          (rnd),
            .serial_number(serial_number),
            .last_pos_odd(sn_last_pos_odd),
            .done         (serial_done) 
        );

//==============================================================
// LCD1602A instance (Password display)
//==============================================================
LCD1602A #(
    .CLK_HZ(50_000_000)
) u_lcd_1602a (
    .clk        (clk),
    .rst        (rst),
    .tick_1us   (tick_1us),

    // password inputs (ASCII)
    .password_0 (pwd_char_0),
    .password_1 (pwd_char_1),
    .password_2 (pwd_char_2),
    .password_3 (pwd_char_3),
    .password_4 (pwd_char_4),
    // mos_code
    .mos_char_0(mos_char_0),
    .mos_char_1(mos_char_1),
    .mos_char_2(mos_char_2),
    // LCD outputs (renamed in top)
    .lcd_rs     (lcd_1602a_rs_w),
    // .lcd_rw     (lcd_1602a_rw),
    .lcd_en     (lcd_1602a_en_w),
    .lcd_data   (lcd_1602a_data_w)
);

//==============================================================
// LCD2004A (4-bit) Display
//==============================================================
    wire LCD_activated;
    LCD2004A #(
        .CLK_HZ(50_000_000)
    ) u_lcd (
        .clk          (clk),
        .rst          (rst),
        .tick_1us     (tick_1us),
        .current_state(current_state),

        .serial_number(serial_number),
        .serial_done  (serial_done),
        .chance_left_ascii(chance_left_ascii),

        .msg          (msg),   

        .lcd_rs       (lcd_2004a_rs_w),
        .lcd_en       (lcd_2004a_en_w),
        .lcd_data     (lcd_2004a_data_w),

        .activated    (LCD_2004a_activated)
    );
//==============================================================
// Talking
//==============================================================
    wire [479:0] msg;
    talking talking_u(
        .rst(rst),
        .clk(clk),
        .tick_1sec(tick_1sec),
        .rnd(rnd),
        .current_state(current_state),
        .one_min_left(one_min_left),
        .ten_sec_left(ten_sec_left),
        .Wires_mistake(1'b0),
        .Memorys_mistake(mem_mistake),
        .Mos_Code_mistake(1'b0),
        .Maze_mistake(1'b0),
        .Passwords_mistake(pwd_mistake),
        // .text(text),
        .msg(msg)                // 60 ASCII chars (60*8=480)
    );
//==============================================================
// ADC
//==============================================================
    wire [11:0] A0 , A1 , A2 , A3 , A4 , A5; 
    AA adc_u(
		.CLOCK(adc_clk), //      clk.clk
		.CH0(A0),   // readings.CH0
		.CH1(A1),   //         .CH1
		.CH2(A2),   //         .CH2
		.CH3(A3),    //         .CH3
		.CH4(A4),     //         .CH4
		.CH5(A5),   //         .CH5
		.CH5(),    //         .CH6
		.CH5(),    //         .CH7
		.RESET(~rst)  //    reset.reset
	);
//==============================================================
// BEBE
//==============================================================
buzzer bebe_u(
    .clk(clk) ,
    .rst(rst) ,
    .tick_10ms(tick_10ms) ,
    .mos_code_signal(mos_code_signal) ,
    .current_state(current_state) ,
    .Mem_mistake(mem_mistake) ,
    // .Mem_mistake(1'b1) ,
    .Passwords_mistake(pwd_mistake) ,
    .Maze_mistake(maze_failed),
    .Morse_Code_mistake(mos_failed),
    .Wires_mistake(wires_failed),
    .time_out(time_out),
    .bebe_o(buzzer_out) 
    // .bebe_o(temp) 
);
    // assign buzzer_out = 1'b1;

//==============================================================
// BOOOOOM (mistake counter / chance left)
//==============================================================
    wire [3:0] total_mistake_cnt;
    wire [7:0] chance_left_ascii;   // '0'~'9'
    wire explore;
    BOOOOOM u_boooom (
        .clk              (clk),
        .rst              (rst),
        .current_state    (current_state),

        .mistake_chance   ({chance_limit_1, chance_limit_0}), // 用你現成的 2-bit 難度/容錯設定

        .Memorys_solved  (mem_solved),
        .Passwords_solved(pwd_solved),
        .Maze_solved     (maze_solved),      // 你 Maze 的錯誤訊號叫 maze_failed
        .Morse_Code_solved(mos_solved),      // 你 Morse 的錯誤訊號叫 mos_failed
        .Wires_solved    (wires_solved),

        .Memorys_mistake  (mem_mistake),
        .Passwords_mistake(pwd_mistake),
        .Maze_mistake     (maze_failed),      // 你 Maze 的錯誤訊號叫 maze_failed
        .Morse_Code_mistake(mos_failed),      // 你 Morse 的錯誤訊號叫 mos_failed
        .Wires_mistake    (wires_failed),
        .time_out         (time_out),

        .total_mistake_cnt(total_mistake_cnt),
        .chance_left_ascii(chance_left_ascii),
        .explode(explode)
    );

//==============================================================
// Memorys
//==============================================================
    wire mem_activated ;
    wire mem_mistake ;
    wire mem_solved ;
    Memorys memorys_u(
    .rst(rst),
    .clk(clk),
    .current_state(current_state), // 外部系統狀態
    .rnd(rnd),          // 隨機種子

    .btn1(mem_btn_1),
    .btn2(mem_btn_2),
    .btn3(mem_btn_3),
    .btn4(mem_btn_4),
    .activated(mem_activated),
    .module_failed(mem_mistake),      // 玩家操作錯誤後，升起一個clk再放下
    .module_solved(mem_solved),       // 模塊被解鎖成功後，保持在高位

    .tm_clk(tm1367_clk),
    .tm_dio(tm1367_dio) ,
    .seven_digit(mem_seven_digit)
);
//==============================================================
//mos
//==============================================================
    
    wire [6:0] freq_code;
    wire mos_code_signal;
    wire mos_activated, mos_failed, mos_solved, mos_btn_summit, mos_led;
    wire debounce_mos_btn_summit;
    wire [7:0] mos_char_0, mos_char_1, mos_char_2;
    deboucing u_db_mos_btn_summit (
        .clk(clk), .rst(rst),
        .btn_in(mos_btn_summit),
        .btn_out(debounce_mos_btn_summit)
    );

    dfc dfc_u(
        .adc_data(A0),
        .freq_code(freq_code)
    );

    adc_to_digital adc_to_digital_u_1(
        .adc_data(A1),
        .signal_out(mos_btn_summit)
    );

    Morse_Code Morse_Code_u(
        .rst(rst),
        .clk(clk),
        .current_state(current_state),
        .rnd(rnd),
        .activated(mos_activated),
        .module_failed(mos_failed),
        .module_solved(mos_solved),
        .freq_code(freq_code),
        .btn_submit(debounce_mos_btn_summit),
        .led_morse(mos_led),
        .buzzer(mos_code_signal),
        .display_char_0(mos_char_0),
        .display_char_1(mos_char_1),
        .display_char_2(mos_char_2)
    );
//==============================================================
// Maze
//==============================================================
wire maze_activated;
wire maze_failed;
wire maze_solved;
// wire maze_btn_u;
// wire maze_btn_d;
// wire maze_btn_r;
// wire maze_btn_l;

// wire maze_dout;


adc_to_digital adc_to_digital_u_2(
        .adc_data(A2),
        .signal_out(maze_btn_u)
    );

adc_to_digital adc_to_digital_u_3(
        .adc_data(A3),
        .signal_out(maze_btn_d)
    );

adc_to_digital adc_to_digital_u_4(
        .adc_data(A4),
        .signal_out(maze_btn_l)
    );

adc_to_digital adc_to_digital_u_5(
        .adc_data(A5),
        .signal_out(maze_btn_r)
    );

Mazes u_maze (
    .rst           (rst),
    .clk           (clk),
    .current_state (current_state),
    .rnd           (rnd),

    .btn_u         (maze_btn_u),
    .btn_d         (maze_btn_d),
    .btn_r         (maze_btn_r),
    .btn_l         (maze_btn_l),

    .activated     (maze_activated),
    .module_failed (maze_failed),
    .module_solved (maze_solved),
    .dout          (maze_dout),
    .btn1 (btn1),
    .btn2 (btn2),
    .btn3 (btn3),
    .btn4 (btn4)
);

//==============================================================
// PASSWORDS
//==============================================================
    // ===============================
    // Password module wires
    // ===============================
    wire        pwd_activated;
    wire        pwd_failed;
    wire        pwd_solved;

    wire [7:0]  pwd_char_0;
    wire [7:0]  pwd_char_1;
    wire [7:0]  pwd_char_2;
    wire [7:0]  pwd_char_3;
    wire [7:0]  pwd_char_4;
    //==============================================================
    // PASSWORD MODULE
    //==============================================================
    wire pwd_mistake;
    // ===============================
    // Debounce wires
    // ===============================
    // wire pwd_btn_submit;
    wire debounce_pwd_btn_up_0;
    wire debounce_pwd_btn_down_0;
    wire debounce_pwd_btn_up_1;
    wire debounce_pwd_btn_down_1;
    wire debounce_pwd_btn_up_2;
    wire debounce_pwd_btn_down_2;
    wire debounce_pwd_btn_up_3;
    wire debounce_pwd_btn_down_3;
    wire debounce_pwd_btn_up_4;
    wire debounce_pwd_btn_down_4;
    wire debounce_pwd_btn_submit;

    // ===============================
    // Debounce instances
    // ===============================
    deboucing u_db_pwd_btn_up_0 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_up_0),
        .btn_out(debounce_pwd_btn_up_0)
    );

    deboucing u_db_pwd_btn_down_0 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_down_0),
        .btn_out(debounce_pwd_btn_down_0)
    );

    deboucing u_db_pwd_btn_up_1 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_up_1),
        .btn_out(debounce_pwd_btn_up_1)
    );

    deboucing u_db_pwd_btn_down_1 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_down_1),
        .btn_out(debounce_pwd_btn_down_1)
    );

    deboucing u_db_pwd_btn_up_2 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_up_2),
        .btn_out(debounce_pwd_btn_up_2)
    );

    deboucing u_db_pwd_btn_down_2 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_down_2),
        .btn_out(debounce_pwd_btn_down_2)
    );

    deboucing u_db_pwd_btn_up_3 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_up_3),
        .btn_out(debounce_pwd_btn_up_3)
    );

    deboucing u_db_pwd_btn_down_3 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_down_3),
        .btn_out(debounce_pwd_btn_down_3)
    );

    deboucing u_db_pwd_btn_up_4 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_up_4),
        .btn_out(debounce_pwd_btn_up_4)
    );

    deboucing u_db_pwd_btn_down_4 (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_down_4),
        .btn_out(debounce_pwd_btn_down_4)
    );

    deboucing u_db_pwd_btn_submit (
        .clk(clk), .rst(rst),
        .btn_in(pwd_btn_submit),
        .btn_out(debounce_pwd_btn_submit)
    );

    // ===============================
    // Passwords module (use debounced signals)
    // ===============================

    Passwords u_password (
        .clk          (clk),
        .rst          (rst),
        .current_state(current_state),

        .rnd          (rnd),

        .activated    (pwd_activated),
        .module_failed(pwd_mistake),
        .module_solved(pwd_solved),

        // buttons -> debounced
        .btn_up_0     (debounce_pwd_btn_up_0),
        .btn_down_0   (debounce_pwd_btn_down_0),
        .btn_up_1     (debounce_pwd_btn_up_1),
        .btn_down_1   (debounce_pwd_btn_down_1),
        .btn_up_2     (debounce_pwd_btn_up_2),
        .btn_down_2   (debounce_pwd_btn_down_2),
        .btn_up_3     (debounce_pwd_btn_up_3),
        .btn_down_3   (debounce_pwd_btn_down_3),
        .btn_up_4     (debounce_pwd_btn_up_4),
        .btn_down_4   (debounce_pwd_btn_down_4),
        .btn_submit   (debounce_pwd_btn_submit),

        // display chars (ASCII)
        .display_char_0(pwd_char_0),
        .display_char_1(pwd_char_1),
        .display_char_2(pwd_char_2),
        .display_char_3(pwd_char_3),
        .display_char_4(pwd_char_4)
    );

//==============================================================
// Wires
//==============================================================

wire wires_solved, wires_failed, wires_activated;
wire [5:0] debounce_wires_num;

wire_debounce #(
    .CLK_HZ(50_000_000),
    .STABLE_MS(2)          // 你可以試 1~5ms
) u_wire_filter (
    .clk(clk),
    .rst(rst),
    .wire_in(wires_num),
    .wire_out(debounce_wires_num)
);
// wire [2:0] zzz;
Wires wires_u(
    .clk(clk),
    .rst(rst),
    .current_state(current_state),
    .sn_last_pos_odd(sn_last_pos_odd),
    .wire_in(debounce_wires_num),
    .activated(wires_activated),
    .module_failed(wires_failed),
    .module_solved(wires_solved)
);

//==============================================================
// Finished LED
//==============================================================
assign wires_finished_LED = wires_solved;
assign mem_finished_LED   = mem_solved;
assign morse_finished_LED = mos_solved;
assign pwd_finished_LED   = pwd_solved;
assign maze_finished_LED  = maze_solved;

endmodule