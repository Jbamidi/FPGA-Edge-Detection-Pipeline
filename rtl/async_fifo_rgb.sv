module async_fifo_rgb #(
    parameter int ADDR_BITS = 10
)(
    input  logic        wclk,
    input  logic        wrst,
    input  logic        w_en,
    input  logic [23:0] w_data,
    output logic        w_full,

    input  logic        rclk,
    input  logic        rrst,
    input  logic        r_en,
    output logic [23:0] r_data,
    output logic        r_empty
);
    localparam int DEPTH = 1 << ADDR_BITS;

    logic [23:0] mem [0:DEPTH-1];

    logic [ADDR_BITS:0] wptr_bin, wptr_bin_n;
    logic [ADDR_BITS:0] rptr_bin, rptr_bin_n;

    logic [ADDR_BITS:0] wptr_gray, wptr_gray_n;
    logic [ADDR_BITS:0] rptr_gray, rptr_gray_n;

    logic [ADDR_BITS:0] wptr_gray_sync1, wptr_gray_sync2;
    logic [ADDR_BITS:0] rptr_gray_sync1, rptr_gray_sync2;

    function automatic logic [ADDR_BITS:0] bin2gray(input logic [ADDR_BITS:0] b);
        bin2gray = (b >> 1) ^ b;
    endfunction

    function automatic logic [ADDR_BITS:0] gray2bin(input logic [ADDR_BITS:0] g);
        logic [ADDR_BITS:0] b;
        int i;
        begin
            b[ADDR_BITS] = g[ADDR_BITS];
            for (i = ADDR_BITS-1; i >= 0; i--) begin
                b[i] = b[i+1] ^ g[i];
            end
            gray2bin = b;
        end
    endfunction

    always_comb begin
        wptr_bin_n  = wptr_bin + (w_en && !w_full);
        wptr_gray_n = bin2gray(wptr_bin_n);
    end

    always_comb begin
        rptr_bin_n  = rptr_bin + (r_en && !r_empty);
        rptr_gray_n = bin2gray(rptr_bin_n);
    end

    always_ff @(posedge wclk or posedge wrst) begin
        if (wrst) begin
            wptr_bin  <= '0;
            wptr_gray <= '0;
        end else begin
            wptr_bin  <= wptr_bin_n;
            wptr_gray <= wptr_gray_n;
            if (w_en && !w_full) begin
                mem[wptr_bin[ADDR_BITS-1:0]] <= w_data;
            end
        end
    end

    always_ff @(posedge rclk or posedge rrst) begin
        if (rrst) begin
            rptr_bin  <= '0;
            rptr_gray <= '0;
            r_data    <= 24'd0;
        end else begin
            rptr_bin  <= rptr_bin_n;
            rptr_gray <= rptr_gray_n;
            if (r_en && !r_empty) begin
                r_data <= mem[rptr_bin[ADDR_BITS-1:0]];
            end
        end
    end

    always_ff @(posedge wclk or posedge wrst) begin
        if (wrst) begin
            rptr_gray_sync1 <= '0;
            rptr_gray_sync2 <= '0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    always_ff @(posedge rclk or posedge rrst) begin
        if (rrst) begin
            wptr_gray_sync1 <= '0;
            wptr_gray_sync2 <= '0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    logic [ADDR_BITS:0] wptr_gray_next_full;
    logic [ADDR_BITS:0] rptr_gray_next_empty;

    assign wptr_gray_next_full = wptr_gray_n;
    assign rptr_gray_next_empty = rptr_gray_n;

    wire [ADDR_BITS:0] rptr_gray_sync = rptr_gray_sync2;
    wire [ADDR_BITS:0] wptr_gray_sync = wptr_gray_sync2;

    assign w_full =
        (wptr_gray_next_full == {~rptr_gray_sync[ADDR_BITS:ADDR_BITS-1], rptr_gray_sync[ADDR_BITS-2:0]});

    assign r_empty = (rptr_gray_next_empty == wptr_gray_sync);

endmodule
