module overlay(
    input logic [9:0] x, 
    input logic [9:0] y, 
    input logic vde,
    input logic [7:0] base_red,
    input logic [7:0] base_green,
    input logic [7:0] base_blue,
    input logic [4:0] peak_u,
    input logic [4:0] peak_v,
    output logic [7:0] red, 
    output logic [7:0] green, 
    output logic [7:0] blue
);

    logic [9:0] peak_x_start;
    logic [9:0] peak_y_start;
    logic [9:0] peak_x_end;
    logic [9:0] peak_y_end;
    logic is_peak_region;

    always_comb begin
        peak_x_start = peak_u * 10'd20;
        peak_y_start = peak_v * 10'd15;
        peak_x_end = peak_x_start + 10'd20;
        peak_y_end = peak_y_start + 10'd15;

        if ((x >= peak_x_start) && (x < peak_x_end) && 
            (y >= peak_y_start) && (y < peak_y_end)) begin
            is_peak_region = 1'b1;
        end else begin
            is_peak_region = 1'b0;
        end

        red = base_red;
        green = base_green;
        blue = base_blue;

        if (!vde) begin
            red = 8'h00;
            green = 8'h00;
            blue = 8'h00;
        end
        else if (is_peak_region) begin
            red = 8'hFF;
            green = 8'h00;
            blue = 8'hFF;
        end
    end

endmodule
