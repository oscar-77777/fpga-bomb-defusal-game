module Mazes(
    input rst ,
    input clk ,
    input [2:0] current_state,
    input [31:0] rnd,
    input btn_u, //btn上下左右
    input btn_d,
    input btn_r,
    input btn_l,
    output reg activated ,
    output module_failed , //玩家操作錯誤後，升起一個clk再放下
    output module_solved ,  //模塊被解鎖成功後，保持在高位
    output wire dout,
    output wire btn1,
    output wire btn2,
    output wire btn3,
    output wire btn4
);
//write your design here
//九張地圖的迷宮跟初始位置跟終點位置
reg [3:0]all_mazes[0:575];
reg [5:0]all_ini[0:8];
reg [5:0]all_final[0:8];

initial begin 
    $readmemh("map.mem",all_mazes);
    $readmemh("initial_pos.mem",all_ini);
    $readmemh("final_pos.mem",all_final);
end

wire u,d,r,l; 
reg test_latch;
reg [2:0]cur_x,cur_y;
reg [2:0]final_x,final_y;
reg [2:0]state,next_state;
reg [3:0]id;
reg win; 
reg fail;
reg btn_test;
wire [9:0]maze_addr = (id*10'd64)+(cur_y*10'd8)+{7'd0,cur_x}; 
wire [3:0]wall_info = all_mazes[maze_addr]; 

parameter LOAD_ID = 3'd0;
parameter LOAD_MAP = 3'd1;
parameter PLAY = 3'd2;
parameter GAME_WIN = 3'd3;
parameter GAME_FAIL = 3'd4;

parameter IDLE = 3'b000;
parameter ACTIVATING = 3'b001;
parameter ACTIVATED = 3'b010;



always @(posedge clk or negedge rst) begin
    if(!rst) begin
        state <= LOAD_ID;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    next_state = state;
    case (state)
        LOAD_ID: begin
            if(current_state == ACTIVATED)next_state = LOAD_MAP;
        end
        LOAD_MAP: next_state = PLAY;
        PLAY: begin
            if(win) next_state = GAME_WIN;
            else if(fail) next_state = GAME_FAIL;
            else next_state = PLAY;
        end
        GAME_WIN : next_state = GAME_WIN;
        GAME_FAIL : next_state = LOAD_MAP; 
        default: next_state = LOAD_ID;
    endcase
end

always @(posedge clk or negedge rst) begin
    if(!rst)begin
        cur_x <= 3'd0;
        cur_y <= 3'd0;
        final_x <= 3'd0;
        final_y <= 3'd0;
        id <= 4'd0;
        win <= 1'd0;
        fail <= 1'd0;
        activated <= 1'b0;
    end
    else begin
        case (state)
            LOAD_ID:begin
                if(current_state == ACTIVATING) begin
                    if (rnd[3:0] > 4'd8) 
                        id <= rnd[3:0] - 4'd9;
                    else 
                        id <= rnd[3:0];
                    activated <= 1'd1;
                end
                else activated <= activated;

            end 
            LOAD_MAP: begin
                cur_y <= all_ini[id][5:3];
                cur_x <= all_ini[id][2:0];
                final_y <= all_final[id][5:3];
                final_x <= all_final[id][2:0];
                win <= 1'd0;
                fail <= 1'd0;
            end
            PLAY: begin
                if(cur_x == final_x && cur_y == final_y) win <= 1'b1;
                else begin
                    win <= 1'b0;
                    fail <= 1'b0;
                    // debouncing 已經輸出 one-shot，直接用 u, d, l, r 判斷
                    if(u) begin
                        if(wall_info[3] == 1'b1) fail <= 1'b1;
                        else cur_y <= cur_y - 1'b1;
                    end
                    else if(d) begin
                        if(wall_info[2] == 1'b1) fail <= 1'b1;
                        else cur_y <= cur_y + 1'b1;
                    end
                    else if(l) begin
                        if(wall_info[1] == 1'b1) fail <= 1'b1;
                        else cur_x <= cur_x - 1'b1;
                    end
                    else if(r) begin
                        if(wall_info[0] == 1'b1) fail <= 1'b1;
                        else cur_x <= cur_x + 1'b1;
                    end
                end
            end
            GAME_FAIL: fail <= 1'b0; 
            GAME_WIN: win <= 1'b1; 
            default: begin
              cur_x <= cur_x;
              cur_y <= cur_y;
            end
        endcase
    end
end
assign module_failed = fail;
assign module_solved = win;
assign now = state;
assign btn1 = btn_u;
assign btn2 = btn_l;
assign btn3 = btn_r;
assign btn4 = btn_d;

// 這裡記得改回正常參數，燒錄時才不會太靈敏
deboucing d1(clk,rst,~btn_u,u);
deboucing d2(clk,rst,~btn_d,d);
deboucing d3(clk,rst,~btn_r,r);
deboucing d4(clk,rst,~btn_l,l);

display_mazes dis1(clk,rst,current_state,cur_x,cur_y,final_x,final_y,win,fail,dout);

endmodule