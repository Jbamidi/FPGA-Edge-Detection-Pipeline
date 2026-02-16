module vga_sync (
    input  logic       clk,
    input  logic       reset,
    output logic       hsync,
    output logic       vsync,
    output logic       video_active,
    output logic [9:0] px,
    output logic [9:0] py
);

    localparam H_ACTIVE = 640;
    localparam H_FP     = 16;
    localparam H_SYNC   = 96;
    localparam H_BP     = 48;
    localparam H_TOTAL  = 800;

    localparam V_ACTIVE = 480;
    localparam V_FP     = 10;
    localparam V_SYNC   = 2;
    localparam V_BP     = 33;
    localparam V_TOTAL  = 525;

    logic [9:0] h_cnt;
    logic [9:0] v_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            h_cnt <= '0;
            v_cnt <= '0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= '0;
                if (v_cnt == V_TOTAL - 1)
                    v_cnt <= '0;
                else
                    v_cnt <= v_cnt + 1;
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end

    assign hsync = ~(h_cnt >= (H_ACTIVE + H_FP) && h_cnt < (H_ACTIVE + H_FP + H_SYNC));
    assign vsync = ~(v_cnt >= (V_ACTIVE + V_FP) && v_cnt < (V_ACTIVE + V_FP + V_SYNC));
    assign video_active = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
    assign px = h_cnt;
    assign py = v_cnt;

endmodule
