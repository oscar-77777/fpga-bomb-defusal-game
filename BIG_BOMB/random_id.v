module random_id (
    input clk,
    input rst,
    output[3:0] id
);
reg [3:0]rand_id;
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        rand_id <= 4'd0;
    end
    else begin
        if(rand_id < 4'd8)begin
            rand_id <= rand_id + 1'd1;
        end
        else begin
            rand_id <= 4'd0;
        end
    end
end
assign id = rand_id;
endmodule