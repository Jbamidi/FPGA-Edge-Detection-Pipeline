module test_patterns(
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic       vde,
    input  logic       pattern_sel,
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    logic xor_bit;

    always_comb begin
        xor_bit = 1'b0;
        red     = 8'h00;
        green   = 8'h00;
        blue    = 8'h00;

        if (!vde) begin
            red   = 8'h00;
            green = 8'h00;
            blue  = 8'h00;
        end else if (!pattern_sel) begin
            if (x < 80) begin
                red = 8'hFF;
            end else if (x < 160) begin
                green = 8'hFF;
            end else if (x < 240) begin
                blue = 8'hFF;
            end else if (x < 320) begin
                red   = 8'hFF;
                green = 8'hFF;
                blue  = 8'hFF;
            end else if (x < 400) begin
                red   = 8'hFF;
                green = 8'hFF;
            end else if (x < 480) begin
                green = 8'hFF;
                blue  = 8'hFF;
            end else if (x < 560) begin
                red  = 8'hFF;
                blue = 8'hFF;
            end else begin
                red   = 8'hFF;
                green = 8'h80;
            end
        end else begin
            xor_bit = x[5] ^ y[5];
            if (xor_bit) begin
                red   = 8'hFF;
                green = 8'hFF;
                blue  = 8'hFF;
            end else begin
                red   = 8'h00;
                green = 8'h00;
                blue  = 8'h00;
            end
        end
    end

endmodule
