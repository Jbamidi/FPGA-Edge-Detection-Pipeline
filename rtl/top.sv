module top(input logic clk,
           input logic [3:0] btn, 
           input logic [15:0] sw, 
           output logic hdmi_clk_p, 
           output logic hdmi_clk_n, 
           output logic [2:0] hdmi_tx_n, 
           output logic [2:0] hdmi_tx_p);
        
      logic pattern_sel;
      assign pattern_sel = sw[0];

      logic reset;
      assign reset = btn[0];

      logic pxl_clk;
      logic pxl_clkx5;
      logic locked;
      logic hsync;
      logic vsync;
      logic vde;
      logic [9:0] x;
      logic [9:0] y;
      
      logic start_of_frame; 
      logic end_of_frame;   
      logic end_of_line;

      logic [7:0] base_red;
      logic [7:0] base_green;
      logic [7:0] base_blue;
      logic [7:0] red;
      logic [7:0] green;
      logic [7:0] blue;

      logic tensor_we; 
      logic [9:0] tensor_waddr;
      logic signed [7:0] tensor_wdata; 
      logic tensor_valid; 
      logic [9:0] tensor_raddr; 
      logic signed [7:0] tensor_rdata; 
      logic [4:0] peak_u, peak_v; 
      logic peak_ready;

      clk_wiz_0 clock_wizard(.clk_in1(clk), 
                              .reset(reset), 
                              .pxl_clk(pxl_clk), 
                              .pxl_clkx5(pxl_clkx5), 
                              .locked(locked)
                              );
      
      video_timing VGA(.reset(reset),
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

      test_patterns test(.x(x), 
                        .y(y), 
                        .vde(vde), 
                        .pattern_sel(pattern_sel), 
                        .red(base_red), 
                        .green(base_green), 
                        .blue(base_blue)
                        );
      
      preprocess pre_inst(
        .clk(pxl_clk),
        .reset(reset),
        .x(x),
        .y(y),
        .vde(vde),
        .red(base_red),
        .green(base_green),
        .blue(base_blue),
        .end_of_frame(end_of_frame),
        .end_of_line(end_of_line),
        .tensor_we(tensor_we),
        .tensor_addr(tensor_waddr), 
        .tensor_data(tensor_wdata),
        .tensor_valid(tensor_valid)
    );

      tensor_ram ram_inst(
         .clk(pxl_clk),
         .we(tensor_we),
         .waddr(tensor_waddr),
         .wdata(tensor_wdata),
         .raddr(tensor_raddr),
         .rdata(tensor_rdata)
      );

      peak_detector peak_inst(
         .clk(pxl_clk),
         .reset(reset),
         .tensor_valid(tensor_valid),
         .rdata(tensor_rdata),
         .raddr(tensor_raddr),
         .peak_u(peak_u),
         .peak_v(peak_v),
         .peak_ready(peak_ready)
      );

      overlay overlay_layer(
         .x(x),
         .y(y),
         .vde(vde),
         .base_red(base_red),
         .base_green(base_green),
         .base_blue(base_blue),
         .peak_u(peak_u),
         .peak_v(peak_v),
         .red(red),
         .green(green),
         .blue(blue)
      );

      hdmi_tx_0 VGA_to_HDMI(.pix_clk(pxl_clk), 
                              .pix_clkx5(pxl_clkx5), 
                              .pix_clk_locked(locked), 
                              .rst(reset), 
                              .red(red), 
                              .green(green), 
                              .blue(blue), 
                              .hsync(hsync), 
                              .vsync(vsync), 
                              .vde(vde), 
                              .aux0_din(4'b0), 
                              .aux1_din(4'b0), 
                              .aux2_din(4'b0), 
                              .ade(1'b0), 
                              .TMDS_CLK_P(hdmi_clk_p), 
                              .TMDS_CLK_N(hdmi_clk_n), 
                              .TMDS_DATA_P(hdmi_tx_p), 
                              .TMDS_DATA_N(hdmi_tx_n)
                              );
endmodule
