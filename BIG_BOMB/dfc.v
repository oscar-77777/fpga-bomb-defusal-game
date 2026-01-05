// ADC 轉換模組
// 將 12-bit ADC 輸出 (0-4095) 轉換為 freq_code (0-100)
// 4096 個段平均分配給 101 個 freq_code 值

module dfc (
    input  [11:0] adc_data,     // 12-bit ADC 輸出 (0-4095)
    output [6:0]  freq_code     // 頻率編碼 (0-100)
);

    // 轉換公式: freq_code = adc_data * 101 / 4096
    // 使用位移運算代替除法: freq_code = (adc_data * 101) >> 12
    // 
    // 每個 freq_code 對應約 40.55 個 ADC 值
    // adc_data = 0    -> freq_code = 0
    // adc_data = 40   -> freq_code = 0
    // adc_data = 41   -> freq_code = 1
    // adc_data = 4095 -> freq_code = 100

    //實測飽和4.97


    wire [19:0] scaled_value;   // 12-bit * 101 需要 20-bit 儲存
    
    assign scaled_value = adc_data * 8'd101;
    assign freq_code = scaled_value[18:12];  // 右移 12 位 (除以 4096)

endmodule

