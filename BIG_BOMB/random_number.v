module random_number (
    input clk ,
    input rst ,
    // input activate ,
    input [2:0] current_state,
    input [31:0] free_cnt,
    output reg  [31:0] rnd

);
//==============================================================
//state_define
//==============================================================
    parameter IDLE = 3'b000;
    parameter ATIVATING = 3'b001;
    parameter ATIVATED = 3'b010;
    parameter DETONATING = 3'b011;
    parameter MISSION_FAILED = 3'b100;
    parameter MISSION_SUCCESSED = 3'b101 ;

//==========================================================
//lfsr32
//==========================================================t

    // reg seed_in_flag;
    // always @(posedge clk or negedge rst) begin
    //     if (!rst) begin
    //         seed_in_flag <= 1'b0;
    //     end else if (activate) begin
    //         seed_in_flag <= 1'b1;
    //     end else begin
    //         seed_in_flag <= seed_in_flag;
    //     end
    // end

    wire [31:0] seed_in = free_cnt;
    wire fb = rnd[31] ^ rnd[21] ^ rnd[1] ^ rnd[0];
    

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rnd <= 32'h1;
        end else if (current_state == IDLE) begin
            rnd <= (seed_in == 32'h0) ? 32'h1 : seed_in;
        end else begin
            rnd <= {rnd[30:0], fb};
        end
    end

endmodule