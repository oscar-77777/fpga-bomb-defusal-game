module deboucing (
    input clk,
    input rst,
    input btn_in,
    output btn_out
);
parameter DEBOUCE = 1000000; //20ms
reg [20:0]count;
reg in1;
reg in2;
reg stable;
reg stable_delay;
//處理亞穩態
always @(posedge clk or negedge rst) begin
    if(!rst) begin
      in1 <= 1'b0;
      in2 <= 1'b0;  
    end
    else begin
      in1 <= btn_in;
      in2 <= in1;
    end
end
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        count <= 21'b0;
        stable <= 1'b0;
    end
    else begin
      //用counter的方式確定輸入是穩定，不是雜訊
      //如果是穩定的話就會保持一定輸出
      if(in2 != stable) begin //如果目前輸入跟stable不一樣
        if(count < DEBOUCE) begin //如果小於DEBOUCE
            count <= count + 1'b1; //持續count
        end
        else begin
            stable <= in2; //如果達到DEBOUCE代表不是雜訊，並更新穩定值
            count <= 21'b0;
        end
      end
      else begin
        count <= 21'b0; //途中如果切換in2導致相同代表雜訊
      end
    end
end
//處理長按之下也是算一個訊號
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        stable_delay <= 1'b0;
    end
    else begin
        stable_delay <= stable;
    end
end
//當按下瞬間(前一個瞬間是0下一個瞬間是1)才算是一個事件
assign btn_out = (stable == 1'b1) && (stable_delay == 1'b0);
endmodule