// ADC 判斷數位訊號模組 (5V ADC Range / 3.3V Logic Target)
module adc_to_digital (
    // input             clk,          // 系統時脈
    // input             rst,        // 非同步低電位復位
    input      [11:0] adc_data,     // 12-bit ADC 輸出 (0-4095 = 0V-5V)
    output            signal_out    // 輸出的數位訊號 (1: High, 0: Low)
);

    // 根據 5.0V 量程計算的門檻值 (參數化方便調整)
    // 判斷 3.3V 訊號：High 門檻 2.3V, Low 門檻 1.0V
    parameter TH_HIGH = 12'd1884; 
    parameter TH_LOW  = 12'd819;

    assign signal_out = (adc_data > 12'd1350) ? 1'd1 : 1'd0; 

    // always @(posedge clk or negedge rst) begin
    //     if (!rst) begin
    //         signal_out <= 1'b0;
    //     end else begin
    //         if (adc_data > TH_HIGH) begin
    //             signal_out <= 1'b1;     // 電壓超過 2.3V，判定為高電位
    //         end else if (adc_data < TH_LOW) begin
    //             signal_out <= 1'b0;     // 電壓低於 1.0V，判定為低電位
    //         end
    //         // 介於 1.0V ~ 2.3V 之間時，保持原狀態 (防止雜訊抖動)
    //     end
    // end

endmodule