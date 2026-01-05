module FSM(
    input rst ,
    input clk ,
    input activate ,
    input LCD_activated ,
    input Wires_activated,
    input Memorys_activated ,
    input Passwords_activated ,
    input Mos_code_activated ,
    input Maze_activated ,
    input explode ,
    input all_solved ,
    output reg [2:0] current_state
    
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
//==============================================================
// ALL_module_activated
//==============================================================
    wire all_module_activated = LCD_activated && Wires_activated && Passwords_activated && Memorys_activated &&  Maze_activated;
        // wire all_module_activated = LCD_activated && Passwords_activated  ;

    reg [2:0] next_state ;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (!activate) begin
                    next_state = ACTIVATING;
                end else begin
                    next_state = current_state;
                end
            end
            ACTIVATING: begin
                if (all_module_activated) begin
                    next_state = ACTIVATED;
                end else begin
                    next_state = current_state;
                end

            end
            ACTIVATED: begin
                if (explode) begin
                    next_state = DETONATING;
                end else if (all_solved) begin
                    next_state = MISSION_SUCCESSED;
                end else begin
                    next_state = current_state;                    
                end
            end

            default: begin
                next_state = current_state;
            end
        endcase
    end

endmodule