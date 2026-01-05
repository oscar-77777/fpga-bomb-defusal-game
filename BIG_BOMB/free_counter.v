module free_counter (
    input rst , 
    input clk ,
    output reg [31:0] free_cnt
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            free_cnt <= 32'd0;
        end else begin
            free_cnt <= free_cnt + 32'd1;
        end 
    end
endmodule