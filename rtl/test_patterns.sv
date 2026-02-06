module test_patterns(input logic [9:0] x,
                     input logic [9:0] y, 
                     input logic vde, 
                     input logic pattern_sel, 
                     output logic [7:0] red, 
                     output logic [7:0] green, 
                     output logic [7:0] blue);

    logic XOR_bit;

    always_comb begin
        XOR_bit = 1'b0;
        red = 8'h00;
        green = 8'h00;
        blue = 8'h00;
        
        if (!vde) begin
            red = 8'h00;
            green = 8'h00;
            blue = 8'h00;
        end
        //Color Bar Pattern
        else if (!pattern_sel) begin
            //Red
            if (x<80) begin
                red = 8'hFF;
                green = 8'h00;
                blue = 8'h00;
            end
            //Green
            else if (x<160) begin
                red = 8'h00;
                green = 8'hFF;
                blue = 8'h00;
            end
            //Blue
            else if (x<240) begin
                red = 8'h00;
                green = 8'h00;
                blue = 8'hFF;
            end
            //White
            else if (x<320) begin
                red = 8'hFF;
                green = 8'hFF;
                blue = 8'hFF;
            end
            //Yellow
            else if (x<400) begin
                red = 8'hFF;
                green = 8'hFF;
                blue = 8'h00;
            end
            //Cyan
            else if (x<480) begin
                red = 8'h00;
                green = 8'hFF;
                blue = 8'hFF;
            end
            //Magenta
            else if (x<560) begin
                red = 8'hFF;
                green = 8'h00;
                blue = 8'hFF;
            end
            //Orange
            else begin
                red = 8'hFF;
                green = 8'h80;
                blue = 8'h00;
            end
        end
        //Checkerboard
        else if (pattern_sel) begin
            XOR_bit = x[5] ^ y[5];
            //White
            if (XOR_bit) begin
                red = 8'hFF;
                green = 8'hFF;
                blue = 8'hFF;
            end
            //Black
            else begin
                red = 8'h00;
                green = 8'h00;
                blue = 8'h00;
            end

        end
    end
endmodule
