module top(
    input  logic        clk,
    input  logic [3:0]  btn,
    input  logic [11:0] sw,
    output logic        hdmi_clk_p,
    output logic        hdmi_clk_n,
    output logic [2:0]  hdmi_tx_n,
    output logic [2:0]  hdmi_tx_p,
    input  logic        cam_pclk,
    input  logic        cam_vsync,
    input  logic        cam_href,
    input  logic [7:0]  cam_d,
    output logic        cam_xclk,
    output logic        cam_scl,
    inout  wire         cam_sda,
    output logic        cam_pwdn,
    output logic        cam_reset_n
);
    assign cam_pwdn    = 1'b0;
    assign cam_reset_n = 1'b1;

    logic reset;
    assign reset = btn[0];

    logic use_camera;
    assign use_camera = sw[2];

    logic overlay_on;
    assign overlay_on = sw[1];

    logic [7:0] thresh;
    assign thresh = sw[11:4];

    logic pattern_sel;
    assign pattern_sel = sw[0];

    logic pxl_clk;
    logic pxl_clkx5;
    logic locked;

    clk_wiz_0 u_clk_wiz(
        .clk_in1(clk),
        .reset(reset),
        .pxl_clk(pxl_clk),
        .pxl_clkx5(pxl_clkx5),
        .locked(locked)
    );

    ov7670_xclk #(.HALF_PERIOD_TICKS(2)) u_xclk(
        .clk_in(clk),
        .reset(reset),
        .xclk(cam_xclk)
    );

    logic sccb_done, sccb_busy, sccb_err;
    logic cam_sda_i;
    logic cam_sda_t;

    IOBUF u_cam_sda_iobuf(
        .I(1'b0),
        .O(cam_sda_i),
        .T(cam_sda_t),
        .IO(cam_sda)
    );

    ov7670_sccb_init #(
        .CLK_HZ(100_000_000),
        .I2C_HZ(100_000)
    ) u_sccb(
        .clk(clk),
        .reset(reset),
        .scl(cam_scl),
        .sda_in(cam_sda_i),
        .sda_t(cam_sda_t),
        .done(sccb_done),
        .busy(sccb_busy),
        .error(sccb_err)
    );

    logic hsync, vsync, vde;
    logic [9:0] x, y;
    logic start_of_frame, end_of_frame, end_of_line;

    video_timing u_vga(
        .reset(reset),
        .clk(pxl_clk),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        .x(x),
        .y(y),
        .start_of_frame(start_of_frame),
        .end_of_frame(end_of_frame),
        .end_of_line(end_of_line)
    );

    logic [7:0] pat_r, pat_g, pat_b;
    test_patterns u_test(
        .x(x),
        .y(y),
        .vde(vde),
        .pattern_sel(pattern_sel),
        .red(pat_r),
        .green(pat_g),
        .blue(pat_b)
    );

    logic cam_pix_valid;
    logic [7:0] cam_r, cam_g, cam_b;

    ov7670_capture u_cap(
        .clk(pxl_clk),
        .pclk(cam_pclk),
        .reset(reset),
        .vsync(cam_vsync),
        .href(cam_href),
        .d(cam_d),
        .pix_valid(cam_pix_valid),
        .red(cam_r),
        .green(cam_g),
        .blue(cam_b)
    );

    logic [7:0] cam_r_hold, cam_g_hold, cam_b_hold;

    always_ff @(posedge pxl_clk or posedge reset) begin
        if (reset) begin
            cam_r_hold <= 8'd0;
            cam_g_hold <= 8'd0;
            cam_b_hold <= 8'd0;
        end else begin
            if (cam_pix_valid) begin
                cam_r_hold <= cam_r;
                cam_g_hold <= cam_g;
                cam_b_hold <= cam_b;
            end
        end
    end

    logic [7:0] src_r, src_g, src_b;
    always_comb begin
        if (use_camera) begin
            if (vde) begin
                src_r = cam_r_hold;
                src_g = cam_g_hold;
                src_b = cam_b_hold;
            end else begin
                src_r = 8'd0;
                src_g = 8'd0;
                src_b = 8'd0;
            end
        end else begin
            src_r = pat_r;
            src_g = pat_g;
            src_b = pat_b;
        end
    end

    logic [7:0] sobel_r, sobel_g, sobel_b;
    logic       sobel_vde, sobel_hsync, sobel_vsync;

    sobel_edge u_sobel(
        .clk(pxl_clk),
        .reset(reset),
        .x(x),
        .y(y),
        .vde(vde),
        .hsync(hsync),
        .vsync(vsync),
        .end_of_line(end_of_line),
        .red(src_r),
        .green(src_g),
        .blue(src_b),
        .thresh(thresh),
        .overlay_on(overlay_on),
        .out_red(sobel_r),
        .out_green(sobel_g),
        .out_blue(sobel_b),
        .out_vde(sobel_vde),
        .out_hsync(sobel_hsync),
        .out_vsync(sobel_vsync)
    );

    hdmi_tx_0 u_hdmi(
        .pix_clk(pxl_clk),
        .pix_clkx5(pxl_clkx5),
        .pix_clk_locked(locked),
        .rst(reset),
        .red(sobel_r),
        .green(sobel_g),
        .blue(sobel_b),
        .hsync(sobel_hsync),
        .vsync(sobel_vsync),
        .vde(sobel_vde),
        .TMDS_CLK_P(hdmi_clk_p),
        .TMDS_CLK_N(hdmi_clk_n),
        .TMDS_DATA_P(hdmi_tx_p),
        .TMDS_DATA_N(hdmi_tx_n)
    );

endmodule
