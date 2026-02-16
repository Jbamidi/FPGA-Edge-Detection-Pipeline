module framebuffer (
    input  logic        clk_wr,
    input  logic        wr_en,
    input  logic [16:0] wr_addr,
    input  logic [7:0]  wr_data,
    input  logic        clk_rd,
    input  logic [16:0] rd_addr,
    output logic [7:0]  rd_data
);

    logic [7:0] mem [0:76799];

    always_ff @(posedge clk_wr) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end

    always_ff @(posedge clk_rd) begin
        rd_data <= mem[rd_addr];
    end

endmodule
