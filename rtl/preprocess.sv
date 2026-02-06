module preprocess (
    input  logic              clk,
    input  logic              reset,
    input  logic [9:0]        x,
    input  logic [9:0]        y,
    input  logic              vde,
    input  logic [7:0]        red,
    input  logic [7:0]        green,
    input  logic [7:0]        blue,
    input  logic              end_of_frame,
    input  logic              end_of_line,
    output logic              tensor_we,
    output logic [9:0]        tensor_addr,
    output logic signed [7:0] tensor_data,
    output logic              tensor_valid
);

    logic [4:0] u;
    logic [4:0] v;
    logic [4:0] x_20;
    logic [3:0] y_15;

    logic in_active;
    logic sample;
    logic row_start_sample;

    logic [4:0] u_addr;
    logic [4:0] v_addr;

    logic [9:0] lum_sum;
    logic [7:0] gray8;
    logic signed [8:0] centered;

    always_comb begin
        in_active = vde && (x < 10'd640) && (y < 10'd480);
        sample = in_active && (x_20 == 5'd0) && (y_15 == 4'd0);
        row_start_sample = sample && (x == 10'd0);

        u_addr = row_start_sample ? 5'd0 : u;
        v_addr = (row_start_sample && (y != 10'd0)) ? ((v == 5'd31) ? 5'd31 : (v + 5'd1)) : v;

        lum_sum = {2'b00, red} + {1'b0, green, 1'b0} + {2'b00, blue};
        gray8 = lum_sum[9:2];
        centered = $signed({1'b0, gray8}) - 9'sd128;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x_20        <= 5'd0;
            y_15        <= 4'd0;
            u           <= 5'd0;
            v           <= 5'd0;
            tensor_we   <= 1'b0;
            tensor_addr <= 10'd0;
            tensor_data <= '0;
            tensor_valid<= 1'b0;
        end else begin
            tensor_we    <= 1'b0;
            tensor_valid <= 1'b0;

            if ((x == 10'd0) && (y == 10'd0)) begin
                x_20 <= 5'd0;
                y_15 <= 4'd0;
                u    <= 5'd0;
                v    <= 5'd0;
            end

            if (x == 10'd0) begin
                x_20 <= 5'd0;
            end else if (in_active) begin
                if (x_20 == 5'd19) x_20 <= 5'd0;
                else               x_20 <= x_20 + 5'd1;
            end

            if (end_of_line && (y < 10'd480)) begin
                if (y_15 == 4'd14) y_15 <= 4'd0;
                else               y_15 <= y_15 + 4'd1;
            end

            if (row_start_sample) begin
                u <= 5'd0;
                v <= v_addr;
            end

            if (sample) begin
                tensor_we   <= 1'b1;
                tensor_addr <= {v_addr, 5'b0} + u_addr;
                tensor_data <= centered[7:0];
                if (u_addr != 5'd31) u <= u_addr + 5'd1;
            end

            if (end_of_frame) begin
                tensor_valid <= 1'b1;
            end
        end
    end

endmodule
