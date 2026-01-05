module buzzer (
    input clk ,
    input rst ,
    input tick_10ms ,
    input mos_code_signal ,
    input [2:0] current_state ,
    input Wires_mistake ,
    input Mem_mistake ,
    input Passwords_mistake,
    input Maze_mistake ,
    input Morse_Code_mistake ,
    input time_out ,
    output bebe_o 
);
//==============================================================
// center_state_define
//==============================================================
    parameter IDLE = 3'b000;
    parameter ACTIVATING = 3'b001;
    parameter ACTIVATED = 3'b010;
    parameter DETONATING = 3'b011;
    parameter MISSION_FAILED = 3'b100;
    parameter MISSION_SUCCESSED = 3'b101 ;

//==============================================================
// bee_state_define
//==============================================================
    parameter BEBE_IDLE = 2'b00;
    parameter BEBE_MOS = 2'b01;
    parameter BEBE_MISTAKE = 2'b10 ;
    parameter BEBE_EXPLORE = 2'b11 ;
    reg [1:0] bebe_state;

    wire any_mistake;
    assign any_mistake = Wires_mistake |
                    Mem_mistake |
                    Passwords_mistake|
                    Maze_mistake |
                    Morse_Code_mistake;
    // assign any_mistake = 1'b1;
    
    parameter MISTAKE_BEBE_PERIOD = 10'd150;
    parameter BEEE_PERIOD         = 3'd2;
    parameter EXPLORE_BEBE_PERIOD = 10'd999;

    reg beee;

    always @(posedge clk or negedge rst) begin

        if (!rst) begin
                bebe_state <= BEBE_IDLE;
        end else begin
            case (current_state)
                ACTIVATED: begin
                    case (bebe_state)
                        BEBE_IDLE : begin
                            bebe_state <= BEBE_MOS;
                        end
                        BEBE_MOS : begin
                            if (any_mistake) begin
                                bebe_state <= BEBE_MISTAKE;
                            end else begin
                                bebe_state <= BEBE_MOS;
                            end
                        end
                        BEBE_MISTAKE : begin
                            if (bebe_counter == MISTAKE_BEBE_PERIOD) begin
                                bebe_state <= BEBE_MOS;
                            end else begin
                                if (beee_coutner == BEEE_PERIOD) begin
                                    beee <= ~beee;
                                end
                            end
                        end
                    endcase
                end

                default : begin
                    bebe_state <= BEBE_IDLE;
                end

            endcase
            
        end
    end


    reg [9:0] bebe_counter ;
    reg [2:0] beee_coutner ;
    always @(posedge clk or negedge rst) begin

        if (!rst) begin
            bebe_counter <= 10'b0;
            beee_coutner <= 3'd0;
        end else begin
            case (bebe_state)
                BEBE_IDLE : begin
                    bebe_counter <= 10'b0; 
                    beee_coutner <= 3'd0;           
                end

                BEBE_MOS : begin
                    bebe_counter <= 10'b0;
                    beee_coutner <= 3'd0;
                end

                BEBE_MISTAKE : begin
                    if (any_mistake) begin
                        bebe_counter <= 10'b0;
                    end else if (tick_10ms) begin
                        bebe_counter <= bebe_counter + 10'b1;
                    end else begin
                        bebe_counter <= bebe_counter ;
                    end

                    if (any_mistake) begin
                        beee_coutner <= 3'b0;
                    end else if (tick_10ms) begin
                        beee_coutner <= beee_coutner + 3'b1;
                    end else if (beee_coutner == BEEE_PERIOD)begin
                        beee_coutner <= 3'd0 ;
                    end else begin
                        beee_coutner <= beee_coutner;
                    end

                end
                default: begin
                    bebe_counter <= 10'b0;
                    beee_coutner <=3'd0;
                end
            endcase

        end
    end

    // bebe_out
    assign bebe_o = (current_state == DETONATING) ? 1'b1 : ((bebe_state == BEBE_MISTAKE) && (beee == 1'b1)) ? 1'b1 : (bebe_state == BEBE_MOS) ? mos_code_signal : 1'b0;
    // assign bebe_o = (bebe_state == BEBE_MISTAKE) ? 1'b1 : 1'b0;
// 
endmodule