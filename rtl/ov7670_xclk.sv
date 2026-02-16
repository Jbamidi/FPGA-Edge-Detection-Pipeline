module ov7670_xclk #(
    parameter int HALF_PERIOD_TICKS = 2
)(
    input  logic clk_in,
    input  logic reset,
    output logic xclk
);

    int cnt;

    always_ff @(posedge clk_in or posedge reset) begin
        if (reset) begin
            cnt  <= 0;
            xclk <= 1'b0;
        end else begin
            if (cnt == HALF_PERIOD_TICKS-1) begin
                cnt  <= 0;
                xclk <= ~xclk;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
endmodule
