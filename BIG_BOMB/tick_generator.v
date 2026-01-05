module tick_generator#(
    parameter integer CLK_HZ = 50_000_000
)(
    input clk ,
    input rst ,
    output reg tick_1us ,
    output reg tick_10ms ,
    output reg tick_1sec
);
// ============================================================
// 1sec tick generator (from 1us tick)
// ============================================================
reg [19:0] sec_cnt;   // 需要數到 999_999

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        sec_cnt   <= 20'd0;
        tick_1sec <= 1'b0;
    end else begin
        tick_1sec <= 1'b0;  // default

        if (tick_1us) begin
            if (sec_cnt == 20'd999_999) begin
                sec_cnt   <= 20'd0;
                tick_1sec <= 1'b1;   // 只跳 1 個 clk
            end else begin
                sec_cnt <= sec_cnt + 1'b1;
            end
        end
    end
end


//==============================================================
//10ms tick generator
//==============================================================
    parameter  FLIP_TIME = 19'd499_999;
    reg [18:0] clk_counter;
    always @(posedge clk or negedge rst ) begin
        if (!rst) begin
            clk_counter <= 19'b0;
        end else if (clk_counter == FLIP_TIME) begin
            clk_counter <=  19'd0;
        end else begin
            clk_counter <= clk_counter + 19'd1;
        end
    end

    always @(posedge clk or negedge rst ) begin
        if (!rst) begin
            tick_10ms <= 1'b0;
        end else begin
            if (clk_counter == FLIP_TIME) begin
                tick_10ms <= 1'b1;
            end else begin
                tick_10ms <= 1'b0;
            end
        end
    end
// ============================================================
// 1us tick generator
// ============================================================
    localparam integer US_DIV = (CLK_HZ / 1_000_000);
    reg [$clog2(US_DIV)-1:0] us_div_cnt;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            us_div_cnt <= 0;
            tick_1us    <= 1'b0;
        end else begin
            if (us_div_cnt == US_DIV-1) begin
                us_div_cnt <= 0;
                tick_1us    <= 1'b1;
            end else begin
                us_div_cnt <= us_div_cnt + 1'b1;
                tick_1us    <= 1'b0;
            end
        end
    end
    
endmodule