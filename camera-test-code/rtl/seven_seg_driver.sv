module seven_seg_driver (
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0] value,
    output logic [3:0]  seg_an,
    output logic [7:0]  seg_cat
);

    logic [16:0] refresh_cnt;
    logic [1:0]  digit_sel;
    logic [3:0]  current_digit;

    logic [3:0] bcd_ones, bcd_tens, bcd_hundreds, bcd_thousands;

    always_comb begin
        logic [31:0] shift;
        shift = {16'd0, value};
        for (int i = 0; i < 16; i++) begin
            if (shift[19:16] >= 5) shift[19:16] = shift[19:16] + 3;
            if (shift[23:20] >= 5) shift[23:20] = shift[23:20] + 3;
            if (shift[27:24] >= 5) shift[27:24] = shift[27:24] + 3;
            if (shift[31:28] >= 5) shift[31:28] = shift[31:28] + 3;
            shift = shift << 1;
        end
        bcd_ones      = shift[19:16];
        bcd_tens       = shift[23:20];
        bcd_hundreds   = shift[27:24];
        bcd_thousands  = shift[31:28];
    end

    always_ff @(posedge clk) begin
        if (reset)
            refresh_cnt <= '0;
        else
            refresh_cnt <= refresh_cnt + 1;
    end

    assign digit_sel = refresh_cnt[16:15];

    always_comb begin
        case (digit_sel)
            2'd0: begin seg_an = 4'b1110; current_digit = bcd_ones; end
            2'd1: begin seg_an = 4'b1101; current_digit = bcd_tens; end
            2'd2: begin seg_an = 4'b1011; current_digit = bcd_hundreds; end
            2'd3: begin seg_an = 4'b0111; current_digit = bcd_thousands; end
            default: begin seg_an = 4'b1111; current_digit = 4'd0; end
        endcase
    end

    always_comb begin
        case (current_digit)
            4'd0: seg_cat = 8'b1100_0000;
            4'd1: seg_cat = 8'b1111_1001;
            4'd2: seg_cat = 8'b1010_0100;
            4'd3: seg_cat = 8'b1011_0000;
            4'd4: seg_cat = 8'b1001_1001;
            4'd5: seg_cat = 8'b1001_0010;
            4'd6: seg_cat = 8'b1000_0010;
            4'd7: seg_cat = 8'b1111_1000;
            4'd8: seg_cat = 8'b1000_0000;
            4'd9: seg_cat = 8'b1001_0000;
            default: seg_cat = 8'b1111_1111;
        endcase
    end

endmodule
