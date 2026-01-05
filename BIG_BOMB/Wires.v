module Wires (
    input rst,
    input clk,
    input [2:0] current_state,
    //==================================================
    // 序號
    //==================================================
    input sn_last_pos_odd,
    //==================================================
    // 實體接線輸入 (1表示未剪/有接，0表示剪斷/未接)
    // 我們假設從 wire_in[0] 開始依序往上接
    //==================================================
    input [5:0] wire_in, 
    //==================================================
    // 隨機關卡 (此模組根據實體線數判斷，故 rnd 僅供 activated 觸發)
    //==================================================
    output reg activated,
    //==================================================
    // 通關判定
    //==================================================
    output reg module_failed,
    output reg module_solved


    
);

    parameter IDLE = 3'b000;
    parameter ATIVATING = 3'b001; 
    parameter ATIVATED = 3'b010;

    reg [2:0] initial_wire_count; // 偵測到的線路數量
    reg [2:0] correct_wire;       // 根據線數決定剪哪一條
    reg [5:0] last_wire_in;
    reg solved_reg;
    reg [5:0] reg_wire_in;


    function [2:0] count_ones;
        input [5:0] data;
        begin
            count_ones = {2'd0, data[0]} +
                         {2'd0, data[1]} +
                         {2'd0, data[2]} +
                         {2'd0, data[3]} +
                         {2'd0, data[4]} +
                         {2'd0, data[5]};
        end
    endfunction


    always @(*) begin
        correct_wire = 3'd0;
        case (initial_wire_count)
            3'd3: begin // 〔3條線〕：藍、藍、紅
                correct_wire = 3'd2;
            end
            3'd4: begin // 〔4條線〕：紅、黃、藍、紅
                if (sn_last_pos_odd) correct_wire = 3'd4;
                else correct_wire = 3'd1;
            end
            3'd5: begin // 〔5條線〕紅、黃、黃、白、黑
                if (sn_last_pos_odd) correct_wire = 3'd4;
                else correct_wire = 3'd1;
            end
            3'd6: begin // 〔6條線〕紅、白、白、藍、藍、藍
                if (sn_last_pos_odd) correct_wire = 3'd3;
                else correct_wire = 3'd4;
            end
            default: correct_wire = 3'd0;
        endcase
    end

    

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            initial_wire_count <= 3'd0;
            activated <= 1'b0;
            module_failed <= 1'b0;
            module_solved <= 1'b0;
            last_wire_in <= 6'b0;
            solved_reg <= 1'b0;
        end else begin
            case (current_state)
                ATIVATING: begin
                    // 插了幾根線
                    initial_wire_count <= count_ones(wire_in);
                    last_wire_in <= wire_in;
                    activated <= 1'b1;
                    module_solved <= 1'b0;
                    module_failed <= 1'b0;
                    solved_reg <= 1'b0;
                end

                ATIVATED: begin
                    activated <= 1'b0;
                    // 偵測剪線動作
                    if ((wire_in != last_wire_in) && !solved_reg) begin
                        if ((last_wire_in[correct_wire-3'd1] == 1'b1) && (wire_in[correct_wire-3'd1] == 1'b0)) begin
                            module_solved <= 1'b1;
                            solved_reg <= 1'b1;
                            module_failed <= 1'b0;
                        end else if (count_ones(wire_in) < count_ones(last_wire_in)) begin
                            module_failed <= 1'b1;
                        end else begin
                            module_failed <= 1'b0;
                        end
                    end else begin
                        module_failed <= 1'b0;
                    end
                    
                    last_wire_in <= wire_in;
                end

                default: begin
                    activated <= 1'b0;
                    module_failed <= 1'b0;
                end
            endcase
        end
    end

endmodule