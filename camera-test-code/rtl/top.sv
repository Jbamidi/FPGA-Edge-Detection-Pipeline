module ov7670_test_top (
    input  logic        clk,

    input  logic        JA1_P,
    input  logic        JA1_N,
    input  logic        JA2_P,
    input  logic        JA2_N,
    input  logic        JA3_P,
    input  logic        JA3_N,
    input  logic        JA4_P,
    input  logic        JA4_N,

    input  logic        JB1_P,
    input  logic        JB2_P,
    input  logic        JB3_P,
    output logic        JB4_P,
    inout  wire         JB1_N,
    inout  wire         JB2_N,
    output logic        JB3_N,
    output logic        JB4_N,

    output logic        hdmi_clk_p,
    output logic        hdmi_clk_n,
    output logic [2:0]  hdmi_tx_p,
    output logic [2:0]  hdmi_tx_n,

    output logic [9:0]  led,
    input  logic [11:0] sw,
    input  logic [3:0]  btn,
    output logic [3:0]  seg_an,
    output logic [7:0]  seg_cat
);

    logic reset;
    assign reset = sw[0];

    logic [7:0] cam_data;
    logic       cam_pclk;
    logic       cam_href;
    logic       cam_vsync;
    logic       xclk_out;

    assign cam_data = {JA4_N, JA3_N, JA2_N, JA1_N, JA4_P, JA3_P, JA2_P, JA1_P};
    assign cam_pclk  = JB1_P;
    assign cam_href  = JB2_P;
    assign cam_vsync = JB3_P;

    assign JB3_N = 1'b0;
    assign JB4_N = ~reset;

    logic sccb_scl_o, sccb_sda_o, sccb_sda_i;
    logic sccb_done, sccb_error;

    assign JB1_N = sccb_scl_o ? 1'bz : 1'b0;
    assign JB2_N = sccb_sda_o ? 1'bz : 1'b0;
    assign sccb_sda_i = JB2_N;

    logic clk_25, clk_125;
    logic clk_locked;

    clk_wiz_0 u_clk_wiz (
        .clk_out1  (clk_25),
        .clk_out2  (clk_125),
        .reset     (reset),
        .locked    (clk_locked),
        .clk_in1   (clk)
    );

    xclk_gen u_xclk (
        .clk_125mhz (clk),
        .reset       (reset),
        .xclk_25mhz (xclk_out)
    );
    assign JB4_P = xclk_out;

    sccb_controller u_sccb (
        .clk    (clk),
        .reset  (reset),
        .scl_o  (sccb_scl_o),
        .sda_o  (sccb_sda_o),
        .sda_i  (sccb_sda_i),
        .done   (sccb_done),
        .error  (sccb_error)
    );

    logic        fb_wr_en;
    logic [16:0] fb_wr_addr;
    logic [7:0]  fb_wr_data;
    logic [16:0] fb_rd_addr;
    logic [7:0]  fb_rd_data;

    camera_capture u_capture (
        .clk        (clk),
        .reset      (reset),
        .cam_pclk   (cam_pclk),
        .cam_href   (cam_href),
        .cam_vsync  (cam_vsync),
        .cam_data   (cam_data),
        .fb_wr_en   (fb_wr_en),
        .fb_wr_addr (fb_wr_addr),
        .fb_wr_data (fb_wr_data)
    );

    framebuffer u_fb (
        .clk_wr   (clk),
        .wr_en    (fb_wr_en),
        .wr_addr  (fb_wr_addr),
        .wr_data  (fb_wr_data),
        .clk_rd   (clk_25),
        .rd_addr  (fb_rd_addr),
        .rd_data  (fb_rd_data)
    );

    logic       hsync, vsync, vde;
    logic [9:0] px, py;

    vga_sync u_vga (
        .clk          (clk_25),
        .reset        (reset),
        .hsync        (hsync),
        .vsync        (vsync),
        .video_active (vde),
        .px           (px),
        .py           (py)
    );

    logic [8:0] fb_x;
    logic [7:0] fb_y;
    assign fb_x = px[9:1];
    assign fb_y = py[9:1];

    always_comb begin
        if (fb_x < 320 && fb_y < 240)
            fb_rd_addr = fb_y * 320 + fb_x;
        else
            fb_rd_addr = '0;
    end

    logic [7:0] red, green, blue;

    always_comb begin
        if (vde && px < 640 && py < 480) begin
            red   = fb_rd_data;
            green = fb_rd_data;
            blue  = fb_rd_data;
        end else begin
            red   = 8'd0;
            green = 8'd0;
            blue  = 8'd0;
        end
    end

    hdmi_tx_0 u_hdmi (
        .pix_clk        (clk_25),
        .pix_clkx5      (clk_125),
        .pix_clk_locked (clk_locked),
        .rst             (reset),
        .red             (red),
        .green           (green),
        .blue            (blue),
        .hsync           (hsync),
        .vsync           (vsync),
        .vde             (vde),
        .aux0_din        (4'b0),
        .aux1_din        (4'b0),
        .aux2_din        (4'b0),
        .ade             (1'b0),
        .TMDS_CLK_P      (hdmi_clk_p),
        .TMDS_CLK_N      (hdmi_clk_n),
        .TMDS_DATA_P     (hdmi_tx_p),
        .TMDS_DATA_N     (hdmi_tx_n)
    );

    logic [15:0] frame_count;
    logic        frame_received;
    logic        pixel_nonzero;
    logic        vsync_prev_frame;
    logic [23:0] pclk_act_cnt, href_act_cnt, vsync_act_cnt;
    logic        pclk_prev, href_prev, vsync_prev_det;
    logic        pclk_active, href_active, vsync_active;
    logic [26:0] heartbeat_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            frame_count     <= '0;
            frame_received  <= '0;
            vsync_prev_frame <= '0;
            pixel_nonzero   <= '0;
            pclk_act_cnt    <= '0;
            href_act_cnt    <= '0;
            vsync_act_cnt   <= '0;
            pclk_prev       <= '0;
            href_prev       <= '0;
            vsync_prev_det  <= '0;
            pclk_active     <= '0;
            href_active     <= '0;
            vsync_active    <= '0;
            heartbeat_cnt   <= '0;
        end else begin
            heartbeat_cnt <= heartbeat_cnt + 1;

            vsync_prev_frame <= cam_vsync;
            if (vsync_prev_frame && !cam_vsync) begin
                frame_count <= frame_count + 1;
                frame_received <= 1'b1;
            end

            pclk_prev <= cam_pclk;
            if (cam_pclk != pclk_prev) begin
                pclk_act_cnt <= 24'hFFFFFF;
                pclk_active <= 1'b1;
            end else if (pclk_act_cnt > 0)
                pclk_act_cnt <= pclk_act_cnt - 1;
            else
                pclk_active <= 1'b0;

            href_prev <= cam_href;
            if (cam_href != href_prev) begin
                href_act_cnt <= 24'hFFFFFF;
                href_active <= 1'b1;
            end else if (href_act_cnt > 0)
                href_act_cnt <= href_act_cnt - 1;
            else
                href_active <= 1'b0;

            vsync_prev_det <= cam_vsync;
            if (cam_vsync != vsync_prev_det) begin
                vsync_act_cnt <= 24'hFFFFFF;
                vsync_active <= 1'b1;
            end else if (vsync_act_cnt > 0)
                vsync_act_cnt <= vsync_act_cnt - 1;
            else
                vsync_active <= 1'b0;

            if (cam_data != 8'h00 && cam_href)
                pixel_nonzero <= 1'b1;
        end
    end

    assign led[0] = pclk_active;
    assign led[1] = href_active;
    assign led[2] = vsync_active;
    assign led[3] = frame_received;
    assign led[4] = sccb_done;
    assign led[5] = sccb_error;
    assign led[6] = pixel_nonzero;
    assign led[7] = heartbeat_cnt[26];
    assign led[8] = clk_locked;
    assign led[9] = 1'b0;

    seven_seg_driver u_seg (
        .clk     (clk),
        .reset   (reset),
        .value   (frame_count),
        .seg_an  (seg_an),
        .seg_cat (seg_cat)
    );

endmodule
