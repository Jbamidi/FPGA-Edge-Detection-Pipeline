module sccb_controller (
    input  logic clk,
    input  logic reset,
    output logic scl_o,
    output logic sda_o,
    input  logic sda_i,
    output logic done,
    output logic error
);

    localparam CLK_DIV = 250;
    localparam OV7670_ADDR_WR = 8'h42;
    localparam NUM_REGS = 20;

    typedef enum logic [3:0] {
        S_IDLE,
        S_START_WAIT,
        S_START,
        S_SEND_BIT,
        S_SCL_HIGH,
        S_SCL_FALL,
        S_ACK_DRIVE,
        S_ACK_HIGH,
        S_ACK_READ,
        S_STOP_LOW,
        S_STOP_HIGH,
        S_STOP_DONE,
        S_DELAY,
        S_NEXT_REG,
        S_DONE
    } state_t;

    logic [9:0]  clk_cnt;
    logic        clk_tick;
    state_t      state;
    logic [4:0]  reg_idx;
    logic [1:0]  byte_idx;
    logic [3:0]  bit_idx;
    logic [7:0]  shift_reg;
    logic [23:0] delay_cnt;
    logic [23:0] startup_delay;
    logic        startup_done;

    logic [15:0] reg_table [NUM_REGS];

    initial begin
        reg_table[ 0] = {8'h12, 8'h80};
        reg_table[ 1] = {8'hFF, 8'hF0};
        reg_table[ 2] = {8'h12, 8'h04};
        reg_table[ 3] = {8'h11, 8'h01};
        reg_table[ 4] = {8'h0C, 8'h00};
        reg_table[ 5] = {8'h3E, 8'h00};
        reg_table[ 6] = {8'h04, 8'h00};
        reg_table[ 7] = {8'h40, 8'hD0};
        reg_table[ 8] = {8'h3A, 8'h04};
        reg_table[ 9] = {8'h14, 8'h18};
        reg_table[10] = {8'h4F, 8'h80};
        reg_table[11] = {8'h50, 8'h80};
        reg_table[12] = {8'h51, 8'h00};
        reg_table[13] = {8'h52, 8'h22};
        reg_table[14] = {8'h53, 8'h5E};
        reg_table[15] = {8'h54, 8'h80};
        reg_table[16] = {8'h58, 8'h9E};
        reg_table[17] = {8'h17, 8'h16};
        reg_table[18] = {8'h18, 8'h04};
        reg_table[19] = {8'h32, 8'h24};
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            clk_cnt <= '0;
            clk_tick <= '0;
        end else begin
            if (clk_cnt == CLK_DIV - 1) begin
                clk_cnt <= '0;
                clk_tick <= 1'b1;
            end else begin
                clk_cnt <= clk_cnt + 1;
                clk_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            startup_delay <= '0;
            startup_done <= '0;
        end else if (!startup_done) begin
            if (startup_delay >= 24'd10_000_000)
                startup_done <= 1'b1;
            else
                startup_delay <= startup_delay + 1;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            scl_o <= 1'b1;
            sda_o <= 1'b1;
            reg_idx <= '0;
            byte_idx <= '0;
            bit_idx <= '0;
            done <= '0;
            error <= '0;
            delay_cnt <= '0;
            shift_reg <= '0;
        end else if (clk_tick) begin
            case (state)
                S_IDLE: begin
                    scl_o <= 1'b1;
                    sda_o <= 1'b1;
                    if (startup_done && !done) begin
                        if (reg_table[reg_idx] == {8'hFF, 8'hF0}) begin
                            state <= S_DELAY;
                            delay_cnt <= 24'd1_250_000;
                        end else begin
                            state <= S_START_WAIT;
                        end
                    end
                end

                S_START_WAIT: begin
                    sda_o <= 1'b1;
                    scl_o <= 1'b1;
                    byte_idx <= '0;
                    shift_reg <= OV7670_ADDR_WR;
                    bit_idx <= 4'd7;
                    state <= S_START;
                end

                S_START: begin
                    sda_o <= 1'b0;
                    state <= S_SEND_BIT;
                end

                S_SEND_BIT: begin
                    scl_o <= 1'b0;
                    sda_o <= shift_reg[7];
                    state <= S_SCL_HIGH;
                end

                S_SCL_HIGH: begin
                    scl_o <= 1'b1;
                    state <= S_SCL_FALL;
                end

                S_SCL_FALL: begin
                    scl_o <= 1'b0;
                    shift_reg <= {shift_reg[6:0], 1'b0};
                    if (bit_idx == 0)
                        state <= S_ACK_DRIVE;
                    else begin
                        bit_idx <= bit_idx - 1;
                        state <= S_SEND_BIT;
                    end
                end

                S_ACK_DRIVE: begin
                    sda_o <= 1'b1;
                    state <= S_ACK_HIGH;
                end

                S_ACK_HIGH: begin
                    scl_o <= 1'b1;
                    state <= S_ACK_READ;
                end

                S_ACK_READ: begin
                    scl_o <= 1'b0;
                    if (sda_i == 1'b1)
                        error <= 1'b1;
                    if (byte_idx == 0) begin
                        byte_idx <= 2'd1;
                        shift_reg <= reg_table[reg_idx][15:8];
                        bit_idx <= 4'd7;
                        state <= S_SEND_BIT;
                    end else if (byte_idx == 1) begin
                        byte_idx <= 2'd2;
                        shift_reg <= reg_table[reg_idx][7:0];
                        bit_idx <= 4'd7;
                        state <= S_SEND_BIT;
                    end else
                        state <= S_STOP_LOW;
                end

                S_STOP_LOW: begin
                    sda_o <= 1'b0;
                    scl_o <= 1'b0;
                    state <= S_STOP_HIGH;
                end

                S_STOP_HIGH: begin
                    scl_o <= 1'b1;
                    state <= S_STOP_DONE;
                end

                S_STOP_DONE: begin
                    sda_o <= 1'b1;
                    state <= S_NEXT_REG;
                end

                S_NEXT_REG: begin
                    if (reg_idx >= NUM_REGS - 1) begin
                        done <= 1'b1;
                        state <= S_DONE;
                    end else begin
                        reg_idx <= reg_idx + 1;
                        state <= S_IDLE;
                    end
                end

                S_DELAY: begin
                    if (delay_cnt == 0)
                        state <= S_NEXT_REG;
                    else
                        delay_cnt <= delay_cnt - 1;
                end

                S_DONE: begin
                    scl_o <= 1'b1;
                    sda_o <= 1'b1;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
