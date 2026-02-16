module sobel_edge (
    input  logic        clk,
    input  logic        reset,

    input  logic [9:0]  x,
    input  logic [9:0]  y,
    input  logic        vde,
    input  logic        hsync,
    input  logic        vsync,
    input  logic        end_of_line,

    input  logic [7:0]  red,
    input  logic [7:0]  green,
    input  logic [7:0]  blue,


    input  logic [7:0]  thresh,
    input  logic        overlay_on,

  
    output logic [7:0]  out_red,
    output logic [7:0]  out_green,
    output logic [7:0]  out_blue,
    output logic        out_vde,
    output logic        out_hsync,
    output logic        out_vsync
);


    logic [9:0] lum_sum;
    logic [7:0] gray;
   
    assign lum_sum = {2'b00, red} + {1'b0, green, 1'b0} + {2'b00, blue};
    assign gray = lum_sum[9:2];

    logic [1:0] w_sel, r1_sel, r2_sel;

    logic [7:0] lb0_r, lb1_r, lb2_r;
    logic lb0_we, lb1_we, lb2_we;

    logic [9:0] x_addr;
    
    assign x_addr = (x < 10'd640) ? x : 10'd0;

    row_ram #(.DEPTH(640), .ADDR_BITS(10)) LB0(.clk(clk), .we(lb0_we), .waddr(x_addr), .wdata(gray), .raddr(x_addr), .rdata(lb0_r));
    row_ram #(.DEPTH(640), .ADDR_BITS(10)) LB1(.clk(clk), .we(lb1_we), .waddr(x_addr), .wdata(gray), .raddr(x_addr), .rdata(lb1_r));
    row_ram #(.DEPTH(640), .ADDR_BITS(10)) LB2(.clk(clk), .we(lb2_we), .waddr(x_addr), .wdata(gray), .raddr(x_addr), .rdata(lb2_r));

    logic [7:0] row1_buff, row2_buff;
    always_comb begin
        row1_buff = 8'd0;
        row2_buff = 8'd0;

        unique case (r1_sel)
            2'd0: row1_buff = lb0_r;
            2'd1: row1_buff = lb1_r;
            2'd2: row1_buff = lb2_r;
            default: row1_buff = 8'd0;
        endcase

        unique case (r2_sel)
            2'd0: row2_buff = lb0_r;
            2'd1: row2_buff = lb1_r;
            2'd2: row2_buff = lb2_r;
            default: row2_buff = 8'd0;
        endcase
    end

    always_comb begin
        lb0_we = 1'b0;
        lb1_we = 1'b0;
        lb2_we = 1'b0;

        if (vde && (x < 10'd640) && (y < 10'd480)) begin
            unique case (w_sel)
                2'd0: lb0_we = 1'b1;
                2'd1: lb1_we = 1'b1;
                2'd2: lb2_we = 1'b1;
                default: ;
            endcase
        end
    end

    logic [9:0] x_d1, x_d2;
    logic [9:0] y_d1, y_d2;
    logic vde_d1, vde_d2;
    logic hsync_d1, hsync_d2;
    logic vsync_d1, vsync_d2;
    logic [7:0] gray_d1, gray_d2;
    logic [7:0] r_d1, r_d2;
    logic [7:0] g_d1, g_d2;
    logic [7:0] b_d1, b_d2;
    logic [7:0] p00,p01,p02;
    logic [7:0] p10,p11,p12;
    logic [7:0] p20,p21,p22;
    logic signed [11:0] gx, gy;   
    logic [11:0] ax, ay;   
    logic [12:0] mag;     
    logic [7:0] mag8;
    logic edge_bit;

    function automatic [11:0] abs12(input logic signed [11:0] v);
        abs12 = v[11] ? (~v + 12'd1) : v;
    endfunction

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            w_sel  <= 2'd0;
            r1_sel <= 2'd1;
            r2_sel <= 2'd2;

  
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;


            x_d1 <= 0; x_d2 <= 0;
            y_d1 <= 0; y_d2 <= 0;
            vde_d1 <= 0; vde_d2 <= 0;
            hsync_d1 <= 1; hsync_d2 <= 1;
            vsync_d1 <= 1; vsync_d2 <= 1;

            gray_d1 <= 0; gray_d2 <= 0;
            r_d1 <= 0; r_d2 <= 0;
            g_d1 <= 0; g_d2 <= 0;
            b_d1 <= 0; b_d2 <= 0;

            out_red <= 0; out_green <= 0; out_blue <= 0;
            out_vde <= 0; out_hsync <= 1; out_vsync <= 1;
        end else begin
      
            x_d1 <= x;       x_d2 <= x_d1;
            y_d1 <= y;       y_d2 <= y_d1;
            vde_d1 <= vde;   vde_d2 <= vde_d1;
            hsync_d1 <= hsync; hsync_d2 <= hsync_d1;
            vsync_d1 <= vsync; vsync_d2 <= vsync_d1;

            gray_d1 <= gray;  gray_d2 <= gray_d1;
            r_d1 <= red;      r_d2 <= r_d1;
            g_d1 <= green;    g_d2 <= g_d1;
            b_d1 <= blue;     b_d2 <= b_d1;


            if (end_of_line) begin
                w_sel  <= r2_sel;
                r2_sel <= r1_sel;
                r1_sel <= w_sel;
                p00 <= 0; p01 <= 0; p02 <= 0;
                p10 <= 0; p11 <= 0; p12 <= 0;
                p20 <= 0; p21 <= 0; p22 <= 0;
            end
            else if (vde_d2 && (x_d2 < 10'd640) && (y_d2 < 10'd480)) begin
                p00 <= p01;  p01 <= p02;  p02 <= row2_buff;
                p10 <= p11;  p11 <= p12;  p12 <= row1_buff;
                p20 <= p21;  p21 <= p22;  p22 <= gray_d2;
            end

            if (vde_d2 && (x_d2 >= 10'd2) && (y_d2 >= 10'd2) &&
                (x_d2 < 10'd640) && (y_d2 < 10'd480)) begin

                gx = $signed({1'b0,p02}) + ($signed({1'b0,p12}) <<< 1) + $signed({1'b0,p22})
                   - $signed({1'b0,p00}) - ($signed({1'b0,p10}) <<< 1) - $signed({1'b0,p20});

                gy = $signed({1'b0,p20}) + ($signed({1'b0,p21}) <<< 1) + $signed({1'b0,p22})
                   - $signed({1'b0,p00}) - ($signed({1'b0,p01}) <<< 1) - $signed({1'b0,p02});

                ax  = abs12(gx);
                ay  = abs12(gy);
                mag = ax + ay; 

                mag8 = mag[12:3];  

                edge_bit = (mag8 >= thresh);
            end else begin
                mag8     = 8'd0;
                edge_bit = 1'b0;
            end

            out_vde   <= vde_d2;
            out_hsync <= hsync_d2;
            out_vsync <= vsync_d2;

            if (!vde_d2) begin
                out_red   <= 8'd0;
                out_green <= 8'd0;
                out_blue  <= 8'd0;
            end else begin
                if (overlay_on) begin
                    if (edge_bit) begin
                        out_red   <= 8'hFF;
                        out_green <= 8'hFF;
                        out_blue  <= 8'hFF;
                    end else begin
                        out_red   <= r_d2;
                        out_green <= g_d2;
                        out_blue  <= b_d2;
                    end
                end else begin
                    if (edge_bit) begin
                        out_red   <= 8'hFF;
                        out_green <= 8'hFF;
                        out_blue  <= 8'hFF;
                    end else begin
                        out_red   <= 8'h00;
                        out_green <= 8'h00;
                        out_blue  <= 8'h00;
                    end
                end
            end
        end
    end

endmodule
