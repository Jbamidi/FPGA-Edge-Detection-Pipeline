module xclk_gen (
    input  logic clk_125mhz,
    input  logic reset,
    output logic xclk_25mhz
);

    logic [1:0] cnt;

    always_ff @(posedge clk_125mhz) begin
        if (reset) begin
            cnt <= '0;
            xclk_25mhz <= '0;
        end else begin
            if (cnt == 2'd1) begin
                cnt <= '0;
                xclk_25mhz <= ~xclk_25mhz;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

endmodule
