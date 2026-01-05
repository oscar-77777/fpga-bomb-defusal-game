module ws2812_driver(
    input clk,
    input rst,
    input [23:0] color,
    output [5:0] pixel,
    output reg dout
);

reg [5:0] pixel_count;      // 目前第幾個 pixel (0-63)
reg [4:0] bit_count;        // 目前 pixel 的第幾個 bit (0-23)
reg [7:0] counter;          // 一個 bit 的時間計數
reg [15:0] reser_counter;   // reset 時間計數
reg state;

reg [23:0] color_lat;       // ★ 新增：latch 後的 color（每顆 pixel 固定）

parameter ONE_HIGH   = 8'd35;
parameter ZERO_HIGH  = 8'd17;
parameter TOTAL_TIME = 8'd62;

parameter SET_DATA  = 1'b0;
parameter SET_RESET = 1'b1;

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        pixel_count   <= 6'd0;
        bit_count     <= 5'd0;
        counter       <= 8'd0;
        reser_counter <= 16'd0;
        state         <= SET_DATA;
        dout          <= 1'b0;
        color_lat     <= 24'd0;
    end
    else begin
        case (state)
            SET_DATA: begin
                if(counter == 0 && bit_count == 0) begin
                    color_lat <= color;
                end
                if(color_lat[23 - bit_count]) begin
                    dout <= (counter < ONE_HIGH) ? 1'b1 : 1'b0;
                end
                else begin
                    dout <= (counter < ZERO_HIGH) ? 1'b1 : 1'b0;
                end

                if(counter < TOTAL_TIME - 1) begin
                    counter <= counter + 1'b1;
                end
                else begin
                    counter <= 8'd0;
                    if(bit_count < 5'd23) begin
                        bit_count <= bit_count + 1'b1;
                    end
                    else begin
                        bit_count <= 5'd0;
                        if(pixel_count < 6'd63) begin
                            pixel_count <= pixel_count + 1'b1;
                        end
                        else begin
                            pixel_count   <= 6'd0;
                            bit_count     <= 5'd0;
                            counter       <= 8'd0;
                            dout          <= 1'b0;
                            reser_counter <= 16'd0;
                            state         <= SET_RESET;
                        end
                    end
                end
            end

            SET_RESET: begin
                dout <= 1'b0;
                if(reser_counter < 16'd15000) begin
                    reser_counter <= reser_counter + 1'b1;
                end
                else begin
                    reser_counter <= 16'd0;
                    state         <= SET_DATA;
                end
            end
        endcase
    end
end

assign pixel = pixel_count;

endmodule
