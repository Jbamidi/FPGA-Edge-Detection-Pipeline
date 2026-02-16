module video_timing(
    input  logic clk,
    input  logic reset,
    output logic hsync,
    output logic vsync,
    output logic vde,
    output logic [9:0] x,
    output logic [9:0] y,
    output logic start_of_frame,
    output logic end_of_frame,
    output logic end_of_line
);

    localparam int H_PIX  = 640;
    localparam int V_PIX  = 480;
    localparam int H_TOT  = 800;
    localparam int V_TOT  = 525;

    logic [9:0] h_curr;
    logic [9:0] v_curr;

    assign x = h_curr;
    assign y = v_curr;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            h_curr <= 10'd0;
        end else if (h_curr == H_TOT-1) begin
            h_curr <= 10'd0;
        end else begin
            h_curr <= h_curr + 10'd1;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            v_curr <= 10'd0;
        end else if (h_curr == H_TOT-1) begin
            if (v_curr == V_TOT-1) begin
                v_curr <= 10'd0;
            end else begin
                v_curr <= v_curr + 10'd1;
            end
        end
    end

    assign vde           = (h_curr < H_PIX) && (v_curr < V_PIX);
    assign hsync         = !((h_curr >= 656) && (h_curr < 752));
    assign vsync         = !((v_curr >= 490) && (v_curr < 492));
    assign start_of_frame= (h_curr == 0) && (v_curr == 0);
    assign end_of_frame  = (h_curr == H_TOT-1) && (v_curr == V_TOT-1);
    assign end_of_line   = (h_curr == H_TOT-1);

endmodule
