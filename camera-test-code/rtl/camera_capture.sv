module camera_capture (
    input  logic        clk,
    input  logic        reset,
    input  logic        cam_pclk,
    input  logic        cam_href,
    input  logic        cam_vsync,
    input  logic [7:0]  cam_data,
    output logic        fb_wr_en,
    output logic [16:0] fb_wr_addr,
    output logic [7:0]  fb_wr_data
);

    logic pclk_sync1, pclk_sync2, pclk_sync3;
    logic href_sync1, href_sync2;
    logic vsync_sync1, vsync_sync2;

    always_ff @(posedge clk) begin
        pclk_sync1  <= cam_pclk;
        pclk_sync2  <= pclk_sync1;
        pclk_sync3  <= pclk_sync2;
        href_sync1  <= cam_href;
        href_sync2  <= href_sync1;
        vsync_sync1 <= cam_vsync;
        vsync_sync2 <= vsync_sync1;
    end

    logic pclk_rise;
    assign pclk_rise = pclk_sync2 && !pclk_sync3;

    logic        byte_toggle;
    logic [7:0]  byte_first;
    logic [16:0] pixel_addr;
    logic        vsync_prev;
    logic        frame_active;

    logic [4:0] red5;
    logic [5:0] green6;
    logic [4:0] blue5;
    logic [7:0] gray;

    always_ff @(posedge clk) begin
        if (reset) begin
            byte_toggle  <= 1'b0;
            byte_first   <= '0;
            pixel_addr   <= '0;
            vsync_prev   <= 1'b0;
            frame_active <= 1'b0;
            fb_wr_en     <= 1'b0;
            fb_wr_addr   <= '0;
            fb_wr_data   <= '0;
        end else begin
            fb_wr_en <= 1'b0;
            vsync_prev <= vsync_sync2;

            if (vsync_prev && !vsync_sync2) begin
                pixel_addr   <= '0;
                frame_active <= 1'b1;
                byte_toggle  <= 1'b0;
            end

            if (!vsync_prev && vsync_sync2)
                frame_active <= 1'b0;

            if (pclk_rise && href_sync2 && frame_active) begin
                if (!byte_toggle) begin
                    byte_first  <= cam_data;
                    byte_toggle <= 1'b1;
                end else begin
                    byte_toggle <= 1'b0;

                    red5   = byte_first[7:3];
                    green6 = {byte_first[2:0], cam_data[7:5]};
                    blue5  = cam_data[4:0];

                    gray = ({3'b0, red5} + {2'b0, green6} + {3'b0, blue5}) >> 1;

                    if (pixel_addr < 76800) begin
                        fb_wr_en   <= 1'b1;
                        fb_wr_addr <= pixel_addr;
                        fb_wr_data <= gray;
                        pixel_addr <= pixel_addr + 1;
                    end
                end
            end

            if (!href_sync2)
                byte_toggle <= 1'b0;
        end
    end

endmodule
