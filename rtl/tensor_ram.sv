module tensor_ram (
    input logic clk,
    input logic we,
    input logic [9:0] waddr,
    input logic signed [7:0] wdata,
    input logic [9:0] raddr,
    output logic signed [7:0] rdata
);

logic signed [7:0] mem [0:1023];

always_ff @(posedge clk) begin
    if (we) begin
        mem[waddr] <= wdata;
    end
    rdata <= mem[raddr];
end

endmodule
