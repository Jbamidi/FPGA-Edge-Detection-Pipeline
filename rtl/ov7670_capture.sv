module ov7670_capture(
    input  logic        clk,
    input  logic        pclk,
    input  logic        reset,
    input  logic        vsync,
    input  logic        href,
    input  logic [7:0]  d,
    output logic        pix_valid,
    output logic [7:0]  red,
    output logic [7:0]  green,
    output logic [7:0]  blue
);

    logic pclk_s0, pclk_s1, pclk_s2;
    logic vs_s0, vs_s1;
    logic hr_s0, hr_s1;
    logic [7:0] d_s0, d_s1;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pclk_s0 <= 1'b0;
            pclk_s1 <= 1'b0;
            pclk_s2 <= 1'b0;
            vs_s0   <= 1'b0;
            vs_s1   <= 1'b0;
            hr_s0   <= 1'b0;
            hr_s1   <= 1'b0;
            d_s0    <= 8'd0;
            d_s1    <= 8'd0;
        end else begin
            pclk_s0 <= pclk;
            pclk_s1 <= pclk_s0;
            pclk_s2 <= pclk_s1;
            vs_s0   <= vsync;
            vs_s1   <= vs_s0;
            hr_s0   <= href;
            hr_s1   <= hr_s0;
            d_s0    <= d;
            d_s1    <= d_s0;
        end
    end

    wire pclk_rise = pclk_s1 & ~pclk_s2;

    logic byte_phase;
    logic [7:0] byte0;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_phase <= 1'b0;
            byte0      <= 8'd0;
            pix_valid  <= 1'b0;
            red        <= 8'd0;
            green      <= 8'd0;
            blue       <= 8'd0;
        end else begin
            pix_valid <= 1'b0;

            if (pclk_rise) begin
                if (vs_s1) begin
                    byte_phase <= 1'b0;
                end else if (hr_s1) begin
                    if (!byte_phase) begin
                        byte0 <= d_s1;
                        byte_phase <= 1'b1;
                    end else begin
                        logic [15:0] pix565;
                        pix565 = {byte0, d_s1};

                        red   <= {pix565[15:11], pix565[15:13]};
                        green <= {pix565[10:5],  pix565[10:9]};
                        blue  <= {pix565[4:0],   pix565[4:2]};

                        pix_valid <= 1'b1;
                        byte_phase <= 1'b0;
                    end
                end else begin
                    byte_phase <= 1'b0;
                end
            end
        end
    end
endmodule
