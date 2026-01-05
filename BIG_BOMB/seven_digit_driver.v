module seven_digit_driver (
    input  [3:0] num,          // 輸入數字 0-15
    input [2:0] current_stage,
    input [2:0] current_state,
    output reg [7:0] seven_digit // 8-bit: [7]=DP, [6:0]=segments
);

    // --- 內部參數: 定義小數點狀態 ---
    // 因為是 Active Low: 1=滅, 0=亮
    localparam DP_OFF = 1'b1; 
    localparam DP_ON  = 1'b0;

    always @(*) begin
        if(current_state == 3'd3) begin
            seven_digit = {DP_ON, 7'b1010101};
        end
        else if(current_stage == 3'd6) begin
            seven_digit = {DP_ON, 7'b1010101};
        end
        else begin
            // 使用 {DP, 7-bit_Code} 的連接語法，方便閱讀
            if(current_stage % 2 == 0 ) begin
                case(num)
                    4'd0: seven_digit = {DP_OFF, 7'b1000000}; // 0xC0
                    4'd1: seven_digit = {DP_OFF, 7'b1111001}; // 0xF9
                    4'd2: seven_digit = {DP_OFF, 7'b0100100}; // 0xA4
                    4'd3: seven_digit = {DP_OFF, 7'b0110000}; // 0xB0
                    4'd4: seven_digit = {DP_OFF, 7'b0011001}; // 0x99
                    default: seven_digit = {DP_OFF, 7'b1111111}; // 全滅 (0xFF)
                endcase
            end 
            else begin
                case(num)
                    4'd0: seven_digit = {DP_ON, 7'b1000000}; // 0xC0
                    4'd1: seven_digit = {DP_ON, 7'b1111001}; // 0xF9
                    4'd2: seven_digit = {DP_ON, 7'b0100100}; // 0xA4
                    4'd3: seven_digit = {DP_ON, 7'b0110000}; // 0xB0
                    4'd4: seven_digit = {DP_ON, 7'b0011001}; // 0x99
                    default: seven_digit = {DP_ON, 7'b1111111}; // 全滅 (0xFF)
                endcase
            end
        end

        end
endmodule