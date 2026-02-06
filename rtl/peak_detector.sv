module peak_detector( 
    input logic clk,
    input logic reset,
    input logic tensor_valid,
    input logic signed [7:0] rdata,
    output logic [9:0] raddr,
    output logic [4:0] peak_u,
    output logic [4:0] peak_v,
    output logic peak_ready
    );

    typedef enum logic [1:0] {START, SCAN, DONE} state_t;
    state_t state;

    logic [10:0] curr_addr; 
    logic signed [7:0] max_val;
    logic [9:0] max_addr;   

    assign raddr = curr_addr[9:0];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= START;
            peak_u <= 5'd0;
            peak_v <= 5'd0;
            max_val <= -8'sd128;
            max_addr <= 10'd0;
            curr_addr <= 11'd0;
            peak_ready <= 1'b0;
        end

        else begin
            case (state) 
                START: begin
                    if (tensor_valid) begin
                        curr_addr <= 11'd0;
                        max_val <= -8'sd128;
                        state <= SCAN;
                    end
                    peak_ready <= 1'b0;
                end
                SCAN: begin
                    if (curr_addr > 0) begin
                        if (rdata >= max_val) begin
                            max_val <= rdata;
                            max_addr <= curr_addr - 10'd1;
                        end
                    end

                    if (curr_addr == 11'd1025) begin
                        state <= DONE;
                    end
                    else begin
                        curr_addr <= curr_addr + 11'd1;
                    end
                    peak_ready <= 1'b0;
                end

                DONE: begin
                    peak_u <= max_addr [4:0];
                    peak_v <= max_addr [9:5];
                    state <= START;
                    peak_ready <= 1'b1;
                    
                end

            endcase
        end
            
    end




endmodule

                                                
