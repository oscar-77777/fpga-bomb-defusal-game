## This file is a pin assignment tcl file for the DE10-Lite board 
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after "to") according to the top level signal names in the project

## Set clock (50Mhz)
set_location_assignment PIN_P11 -to clk;
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk

## Set reset
# set_location_assignment PIN_F15 -to rst;





## Set buttons
set_location_assignment PIN_B8 -to rst;
set_location_assignment PIN_A7 -to activate;

## Set switches
set_location_assignment PIN_C10 -to time_limit_0;
set_location_assignment PIN_C11 -to time_limit_1;
set_location_assignment PIN_D12 -to chance_limit_0;
set_location_assignment PIN_C12 -to chance_limit_1;
# set_location_assignment PIN_A12 -to enable[4];
# set_location_assignment PIN_B12 -to enable[5];
#set_location_assignment PIN_A13 -to sw[6];
#set_location_assignment PIN_A14 -to sw[7];
#set_location_assignment PIN_B14 -to sw[8];
#set_location_assignment PIN_F15 -to sw[9];

## Set LEDs
# set_location_assignment PIN_A8 -to lcd_data_w[0];
# set_location_assignment PIN_A9 -to lcd_data_w[1];
# set_location_assignment PIN_A10 -to lcd_data_w[2];
# set_location_assignment PIN_B10 -to lcd_data_w[3];
# set_location_assignment PIN_D13 -to lcd_data_w[4];
# set_location_assignment PIN_C13 -to lcd_data_w[5];
# set_location_assignment PIN_E14 -to lcd_data_w[6];
# set_location_assignment PIN_D14 -to lcd_data_w[7];

set_location_assignment PIN_A8 -to btn1;
set_location_assignment PIN_A9 -to btn2; 
set_location_assignment PIN_A10 -to btn3;
set_location_assignment PIN_B10 -to btn4;

# set_location_assignment PIN_D13 -to zzz[0];
# set_location_assignment PIN_C13 -to zzz[1];
# set_location_assignment PIN_E14 -to zzz[2];
# set_location_assignment PIN_D13 -to aa[0];
# set_location_assignment PIN_C13 -to aa[1];
# set_location_assignment PIN_E14 -to aa[2];
# set_location_assignment PIN_D14 -to aa[3];
# set_location_assignment PIN_A11 -to aa[4];
# set_location_assignment PIN_B11 -to aa[5];

##set Password bottom
# set_location_assignment PIN_AA2 -to pwd_btn_up_0;
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_up_0

# ============================================================
# Timer_display
# ============================================================
## Set seven segment display_0
set_location_assignment PIN_C14 -to T_HEX0[0];
set_location_assignment PIN_E15 -to T_HEX0[1];
set_location_assignment PIN_C15 -to T_HEX0[2];
set_location_assignment PIN_C16 -to T_HEX0[3];
set_location_assignment PIN_E16 -to T_HEX0[4];
set_location_assignment PIN_D17 -to T_HEX0[5];
set_location_assignment PIN_C17 -to T_HEX0[6];
set_location_assignment PIN_D15 -to T_DP[0];

## Set seven segment display_1
set_location_assignment PIN_C18 -to T_HEX1[0];
set_location_assignment PIN_D18 -to T_HEX1[1];
set_location_assignment PIN_E18 -to T_HEX1[2];
set_location_assignment PIN_B16 -to T_HEX1[3];
set_location_assignment PIN_A17 -to T_HEX1[4];
set_location_assignment PIN_A18 -to T_HEX1[5];
set_location_assignment PIN_B17 -to T_HEX1[6];
set_location_assignment PIN_A16 -to T_DP[1];

## Set seven segment display_2
set_location_assignment PIN_B20 -to T_HEX2[0];
set_location_assignment PIN_A20 -to T_HEX2[1];
set_location_assignment PIN_B19 -to T_HEX2[2];
set_location_assignment PIN_A21 -to T_HEX2[3];
set_location_assignment PIN_B21 -to T_HEX2[4];
set_location_assignment PIN_C22 -to T_HEX2[5];
set_location_assignment PIN_B22 -to T_HEX2[6];
set_location_assignment PIN_A19 -to T_DP[2];

## Set seven segment display_3
set_location_assignment PIN_F21 -to T_HEX3[0];
set_location_assignment PIN_E22 -to T_HEX3[1];
set_location_assignment PIN_E21 -to T_HEX3[2];
set_location_assignment PIN_C19 -to T_HEX3[3];
set_location_assignment PIN_C20 -to T_HEX3[4];
set_location_assignment PIN_D19 -to T_HEX3[5];
set_location_assignment PIN_E17 -to T_HEX3[6];
set_location_assignment PIN_D22 -to T_DP[3];

## Set seven segment display_4
set_location_assignment PIN_F18 -to T_HEX4[0];
set_location_assignment PIN_E20 -to T_HEX4[1];
set_location_assignment PIN_E19 -to T_HEX4[2];
set_location_assignment PIN_J18 -to T_HEX4[3];
set_location_assignment PIN_H19 -to T_HEX4[4];
set_location_assignment PIN_F19 -to T_HEX4[5];
set_location_assignment PIN_F20 -to T_HEX4[6];
set_location_assignment PIN_F17 -to T_DP[4];

## Set seven segment display_5
set_location_assignment PIN_J20 -to T_HEX5[0];
set_location_assignment PIN_K20 -to T_HEX5[1];
set_location_assignment PIN_L18 -to T_HEX5[2];
set_location_assignment PIN_N18 -to T_HEX5[3];
set_location_assignment PIN_M20 -to T_HEX5[4];
set_location_assignment PIN_N19 -to T_HEX5[5];
set_location_assignment PIN_N20 -to T_HEX5[6];
set_location_assignment PIN_L19 -to T_DP[5];

# ============================================================
# LCD1602A - Data Bus (8-bit)
# ============================================================
set_location_assignment PIN_AA8 -to lcd_1602a_rs_w
set_location_assignment PIN_AA7 -to lcd_1602a_en_w
set_location_assignment PIN_AA6  -to lcd_1602a_data_w[0]
set_location_assignment PIN_AA5  -to lcd_1602a_data_w[1]
set_location_assignment PIN_AB3  -to lcd_1602a_data_w[2]
set_location_assignment PIN_AB2  -to lcd_1602a_data_w[3]

# ==============================
# IO Standard (3.3V LVTTL)
# ==============================
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_1602a_rs_w
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_1602a_en_w

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_1602a_data_w[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_1602a_data_w[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_1602a_data_w[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_1602a_data_w[3]

# ============================================================
# LCD2004A - Data Bus (8-bit)
# ============================================================
set_location_assignment PIN_AA2  -to lcd_2004a_data_w[3]
set_location_assignment PIN_Y3  -to lcd_2004a_data_w[2]
set_location_assignment PIN_Y4  -to lcd_2004a_data_w[1]
set_location_assignment PIN_Y5  -to lcd_2004a_data_w[0]
# ============================================================
# LCD2004A - Control Signals
# ============================================================

set_location_assignment PIN_Y6 -to lcd_2004a_en_w
set_location_assignment PIN_Y7 -to lcd_2004a_rs_w

# ==============================
# IO Standard (3.3V LVTTL)
# ==============================
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_2004a_en_w
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_2004a_rs_w
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_2004a_data_w[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_2004a_data_w[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_2004a_data_w[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to lcd_2004a_data_w[0]
# ============================================================
# bebe
# ============================================================
set_location_assignment PIN_AA15  -to buzzer_out
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to buzzer_out
# ============================================================
# ADC
# ============================================================
set_location_assignment PIN_N5  -to adc_clk
# ============================================================
# WIRES
# ============================================================
set_location_assignment PIN_Y8    -to wires_num[5]
set_location_assignment PIN_AA10  -to wires_num[4]
set_location_assignment PIN_W11   -to wires_num[3]
set_location_assignment PIN_Y11  -to wires_num[2]
set_location_assignment PIN_AB13  -to wires_num[1]
set_location_assignment PIN_W13  -to wires_num[0]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to wires_num[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to wires_num[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to wires_num[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to wires_num[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to wires_num[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to wires_num[0]


# ============================================================
# Memorys
# ============================================================
## Set bottom
set_location_assignment PIN_AA9 -to mem_btn_1;
set_location_assignment PIN_AB10 -to mem_btn_2;
set_location_assignment PIN_AB11 -to mem_btn_3;
set_location_assignment PIN_AB12 -to mem_btn_4;

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_btn_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_btn_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_btn_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_btn_4
## Set seven segment display_5
set_location_assignment PIN_W7 -to mem_seven_digit[7];
set_location_assignment PIN_V7 -to mem_seven_digit[6];
set_location_assignment PIN_V8 -to mem_seven_digit[5];
set_location_assignment PIN_W10 -to mem_seven_digit[4];
set_location_assignment PIN_W9 -to mem_seven_digit[3];
set_location_assignment PIN_W8 -to mem_seven_digit[2];
set_location_assignment PIN_V10 -to mem_seven_digit[1];
set_location_assignment PIN_V9 -to mem_seven_digit[0];

# ============================================================
# mem_seven_digit I/O standard
# ============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_seven_digit[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_seven_digit[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_seven_digit[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_seven_digit[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_seven_digit[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_seven_digit[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_seven_digit[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_seven_digit[7]

## Set seven segment 
set_location_assignment PIN_W6 -to tm1367_clk;
set_location_assignment PIN_V5 -to tm1367_dio;
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tm1367_clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tm1367_dio
# ============================================================
# Maze
# ============================================================
# Arduino IO11 (MOSI)
set_location_assignment PIN_AB19 -to maze_dout;
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to maze_dout

set_location_assignment PIN_AA19 -to pwd_btn_submit;
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_submit
# set_location_assignment PIN_Y19 -to maze_btn_d;
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to maze_btn_d
# set_location_assignment PIN_AB20 -to maze_btn_l;
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to maze_btn_l
# set_location_assignment PIN_AB21 -to maze_btn_r;
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to maze_btn_r

# ============================================================
# PASSWORDS
# ============================================================
# Arduino IO0
set_location_assignment PIN_AB5  -to pwd_btn_up_4
# Arduino IO1
set_location_assignment PIN_AB6  -to pwd_btn_up_3
# Arduino IO2
set_location_assignment PIN_AB7  -to pwd_btn_up_2
# Arduino IO3
set_location_assignment PIN_AB8  -to pwd_btn_up_1
# Arduino IO4
set_location_assignment PIN_AB9  -to pwd_btn_up_0
# Arduino IO5
set_location_assignment PIN_Y10  -to pwd_btn_down_0
# Arduino IO6
set_location_assignment PIN_AA11 -to pwd_btn_down_1
# Arduino IO7
set_location_assignment PIN_AA12 -to pwd_btn_down_2
# Arduino IO8
set_location_assignment PIN_AB17 -to pwd_btn_down_3
# Arduino IO9
set_location_assignment PIN_AA17 -to pwd_btn_down_4

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_up_4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_up_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_up_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_up_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_up_0

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_down_0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_down_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_down_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_down_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_btn_down_4

# ============================================================
# Finished_LED
# ============================================================
set_location_assignment PIN_AB20 -to pwd_finished_LED;
set_location_assignment PIN_Y19  -to morse_finished_LED;
set_location_assignment PIN_W5   -to wires_finished_LED;
set_location_assignment PIN_AA14 -to mem_finished_LED;
set_location_assignment PIN_W12  -to maze_finished_LED;

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pwd_finished_LED
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to morse_finished_LED
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to wires_finished_LED
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mem_finished_LED
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to maze_finished_LED

# Arduino IO11 (MOSI)
# set_location_assignment PIN_AA19 -to <SIGNAL_NAME>
# Arduino IO12 (MISO)
# set_location_assignment PIN_Y19  -to <SIGNAL_NAME>
# Arduino IO13 (SCK)
# set_location_assignment PIN_AB20 -to <SIGNAL_NAME>
# Arduino IO14 (SDA)
# set_location_assignment PIN_AB21 -to <SIGNAL_NAME>
# Arduino IO15 (SCL)
# set_location_assignment PIN_AA20 -to <SIGNAL_NAME>

## Set VGA
#set_location_assignment PIN_N3 -to vga_hs;
#set_location_assignment PIN_N1 -to vga_vs;
#set_location_assignment PIN_AA1 -to vga_r[0];
#set_location_assignment PIN_V1 -to vga_r[1];
#set_location_assignment PIN_Y2 -to vga_r[2];
#set_location_assignment PIN_Y1 -to vga_r[3];
#set_location_assignment PIN_W1 -to vga_g[0];
#set_location_assignment PIN_T2 -to vga_g[1];
#set_location_assignment PIN_R2 -to vga_g[2];
#set_location_assignment PIN_R1 -to vga_g[3];
#set_location_assignment PIN_P1 -to vga_b[0];
#set_location_assignment PIN_T1 -to vga_b[1];
#set_location_assignment PIN_P4 -to vga_b[2];
#set_location_assignment PIN_N2 -to vga_b[3];