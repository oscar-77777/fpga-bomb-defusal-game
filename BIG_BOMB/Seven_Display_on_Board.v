module Seven_Display_on_Board(
    // ===== Time input (BCD format) =====
    input [3:0] time_left_minute_tens,
    input [3:0] time_left_minute_ones,

    input [3:0] time_left_sec_tens,
    input [3:0] time_left_sec_ones,

    input [3:0] time_left_micro_sec_tens,
    input [3:0] time_left_micro_sec_ones,

    // ===== 7-seg output (active low) =====
    output [6:0] HEX_0,   // micro_sec ones
    output [6:0] HEX_1,   // micro_sec tens
    output [6:0] HEX_2,   // sec ones
    output [6:0] HEX_3,   // sec tens
    output [6:0] HEX_4,   // minute ones
    output [6:0] HEX_5,    // minute tens
    output [5:0] DP
);
    // ==========================================================
    // BCD to 7-segment decoder (active low)
    // segment order: {a, b, c, d, e, f, g}
    // ==========================================================
    function [6:0] bcd_to_7seg;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0: bcd_to_7seg = 7'b100_0000;
                4'd1: bcd_to_7seg = 7'b111_1001;
                4'd2: bcd_to_7seg = 7'b010_0100;
                4'd3: bcd_to_7seg = 7'b011_0000;
                4'd4: bcd_to_7seg = 7'b001_1001;
                4'd5: bcd_to_7seg = 7'b001_0010;
                4'd6: bcd_to_7seg = 7'b000_0010;
                4'd7: bcd_to_7seg = 7'b111_1000;
                4'd8: bcd_to_7seg = 7'b000_0000;
                4'd9: bcd_to_7seg = 7'b001_0000;
                default: bcd_to_7seg = 7'b111_1111; // blank
            endcase
        end
    endfunction

    // ==========================================================
    // Output mapping (LOW -> HIGH : HEX_0 -> HEX_5)
    // ==========================================================
    assign HEX_0 = bcd_to_7seg(time_left_micro_sec_ones);
    assign HEX_1 = bcd_to_7seg(time_left_micro_sec_tens);

    assign HEX_2 = bcd_to_7seg(time_left_sec_ones);
    assign HEX_3 = bcd_to_7seg(time_left_sec_tens);

    assign HEX_4 = bcd_to_7seg(time_left_minute_ones);
    assign HEX_5 = bcd_to_7seg(time_left_minute_tens);

    assign DP = 6'b101011;
    
endmodule

