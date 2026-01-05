module BOOOOOM (
    input  clk,
    input  rst,
    input  [2:0] current_state,
    input  [1:0] mistake_chance,

    input Wires_solved ,
    input Memorys_solved ,
    input Passwords_solved ,
    input Maze_solved ,
    input Morse_Code_solved ,

    input  Wires_mistake,
    input  Memorys_mistake,
    input  Passwords_mistake,
    input  Maze_mistake,
    input  Morse_Code_mistake,
    input  time_out,

    output reg [3:0] total_mistake_cnt ,
    output reg [7:0] chance_left_ascii ,
    output all_solved ,
    output explode 
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

    wire any_mistake;
    assign any_mistake = Wires_mistake |
                    Memorys_mistake |
                    Passwords_mistake|
                    Maze_mistake |
                    Morse_Code_mistake;
    

    assign all_solved = Wires_solved |
                    Memorys_solved |
                    Passwords_solved|
                    Maze_solved |
                    Morse_Code_solved;

    reg [3:0] total_chance;
    assign explode = ((total_mistake_cnt > total_chance) || time_out) ;
    wire [3:0] chance_left_val;
    assign chance_left_val = (total_mistake_cnt >= total_chance) ? 4'd0 :(total_chance - total_mistake_cnt);
    always @(*) begin
    if (chance_left_val <= 4'd9)
        chance_left_ascii = 8'd48 + chance_left_val; // '0' + n
    else
        chance_left_ascii = "9"; // 保底（理論上不會到）
    end


    always @(posedge clk or negedge rst) begin

        if (!rst) begin
            total_mistake_cnt <= 4'd0;
            total_chance <= 4'd0;
        end else begin
            case (current_state)
                ACTIVATING: begin
                    case (mistake_chance)
                        2'b00: begin
                            total_chance <= 4'd5;
                        end 
                        2'b01: begin
                            total_chance <= 4'd3;
                        end
                        2'b10: begin
                            total_chance <= 4'd1;
                        end
                        2'b11: begin
                            total_chance <= 4'd0;
                        end
                    endcase
                end
                ACTIVATED: begin
                    if (any_mistake) begin
                        total_mistake_cnt <= total_mistake_cnt + 1'b1;
                    end
                end
            endcase
            
        end
    end
endmodule