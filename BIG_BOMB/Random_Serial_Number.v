module Random_Serial_Number (
    input         clk,
    input         rst,             // active-low reset (因為你用 negedge rst / if(!rst))
    input  [2:0]  current_state,
    input  [31:0] rnd,             // 外部LFSR每拍在變（或至少在 running 時變）
    output reg [47:0] serial_number,
    output reg last_pos_odd,
    output reg        done
);

//==============================================================
// state_define
//==============================================================
    parameter IDLE = 3'b000;
    parameter ACTIVATING = 3'b001;
    parameter ACTIVATED = 3'b010;
    parameter DETONATING = 3'b011;
    parameter MISSION_FAILED = 3'b100;
    parameter MISSION_SUCCESSED = 3'b101 ;

    //==========================================================
    // helpers
    //==========================================================
    function automatic [7:0] map_digit(input [3:0] v);
        begin
            map_digit = 8'd48 + v; // '0' + v
        end
    endfunction

    // 24 letters: A..Z excluding O and Y (KTANE-style)
    function automatic [7:0] map_letter_no_OY(input [4:0] idx); // 0..23
        begin
            case (idx)
              5'd0:  map_letter_no_OY = "A";
              5'd1:  map_letter_no_OY = "B";
              5'd2:  map_letter_no_OY = "C";
              5'd3:  map_letter_no_OY = "D";
              5'd4:  map_letter_no_OY = "E";
              5'd5:  map_letter_no_OY = "F";
              5'd6:  map_letter_no_OY = "G";
              5'd7:  map_letter_no_OY = "H";
              5'd8:  map_letter_no_OY = "I";
              5'd9:  map_letter_no_OY = "J";
              5'd10: map_letter_no_OY = "K";
              5'd11: map_letter_no_OY = "L";
              5'd12: map_letter_no_OY = "M";
              5'd13: map_letter_no_OY = "N";
              5'd14: map_letter_no_OY = "P"; // skip O
              5'd15: map_letter_no_OY = "Q";
              5'd16: map_letter_no_OY = "R";
              5'd17: map_letter_no_OY = "S";
              5'd18: map_letter_no_OY = "T";
              5'd19: map_letter_no_OY = "U";
              5'd20: map_letter_no_OY = "V";
              5'd21: map_letter_no_OY = "W";
              5'd22: map_letter_no_OY = "X";
              5'd23: map_letter_no_OY = "Z"; // skip Y
              default: map_letter_no_OY = "A";
            endcase
        end
    endfunction

    //==========================================================
    // generator regs/wires
    //==========================================================

    reg [2:0]  pos;          // 0..5
    reg        has_letter;   // ensure at least 1 letter in first 5 chars
    reg [47:0] buff;

    // random decode + rejection
    wire       want_letter = rnd[8];
    wire [4:0] letter_idx  = rnd[4:0];   // 0..31
    wire [3:0] digit_val   = rnd[3:0];   // 0..15
    wire       letter_ok   = (letter_idx < 5'd24);
    wire       digit_ok    = (digit_val  < 4'd10);

    wire       pick_letter = want_letter & letter_ok;
    wire       pick_digit  = (~want_letter) & digit_ok;

    wire [7:0] ch_letter = map_letter_no_OY(letter_idx);
    wire [7:0] ch_digit  = map_digit(digit_val);

    wire [3:0] last_digit_val = rnd[15:12];
    wire       last_digit_ok  = (last_digit_val < 4'd10);
    wire [7:0] ch_last_digit  = map_digit(last_digit_val);

    //==========================================================
    // main sequential
    //==========================================================
    always @(posedge clk or negedge rst) begin
        if (!rst) begin

            done          <= 1'b0;
            pos           <= 3'd0;
            has_letter    <= 1'b0;

            buff          <= 48'h000000000000; // "000000"
            serial_number <= 48'h303030303030; // "000000"
        end else begin

            case (current_state)

                ACTIVATING: begin
                    if (!done) begin
                        if (pos < 3'd5) begin
                            if (pick_letter) begin
                                buff[47-8*pos -: 8] <= ch_letter;
                                has_letter <= 1'b1;
                                pos <= pos + 1'b1;
                            end else if (pick_digit) begin
                                buff[47-8*pos -: 8] <= ch_digit;
                                pos <= pos + 1'b1;
                            end
                            // else: reject this cycle (等待下一拍 rnd)
                        end else begin
                            // pos == 5: last char must be digit
                            if (last_digit_ok) begin
                                buff[7:0] <= ch_last_digit;
                                last_pos_odd <= ch_last_digit[0]; // 加48[0]不變
                                // ensure at least one letter in first 5 chars
                                if (!has_letter) begin
                                    if (letter_ok) begin
                                        serial_number <= {ch_letter, buff[39:8], ch_last_digit};
                                    end else begin
                                        serial_number <= {"A", buff[39:8], ch_last_digit};
                                    end
                                    // buff[47:40] <= letter_ok ? ch_letter : "A";
                                end else begin
                                    serial_number <= {buff[47:8], ch_last_digit};
                                end

                                done <= 1'b1;       //完成後就不動
                            end
                        end                        
                    end
                end
                default: begin
                    done          <= done;
                    pos           <= pos;
                    has_letter    <= has_letter;
                    buff          <= buff;
                    serial_number <= serial_number;
                end
            endcase
        end
    end

endmodule
