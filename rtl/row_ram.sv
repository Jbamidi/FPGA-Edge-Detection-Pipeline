module line_ram #(
    parameter int DEPTH     = 640,  
    parameter int ADDR_BITS = 10     
) (
    input  logic                 clk,
    input  logic                 we,
    input  logic [ADDR_BITS-1:0] waddr,
    input  logic [7:0]           wdata,
    input  logic [ADDR_BITS-1:0] raddr,
    output logic [7:0]           rdata
);


    logic [7:0] mem [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (we) begin
            mem[waddr] <= wdata;
        end
        rdata <= mem[raddr];
    end

endmodule
