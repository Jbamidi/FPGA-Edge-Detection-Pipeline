module ov7670_sccb_init #(
    parameter int CLK_HZ = 100_000_000,
    parameter int I2C_HZ = 100_000
)(
    input  logic clk,
    input  logic reset,
    output logic scl,
    input  logic sda_in,
    output logic sda_t,
    output logic done,
    output logic busy,
    output logic error
);

    localparam int DIV = CLK_HZ / (I2C_HZ*4);

    logic [$clog2(DIV)-1:0] divcnt;
    logic tick;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            divcnt <= '0;
            tick   <= 1'b0;
        end else begin
            if (divcnt == DIV-1) begin
                divcnt <= '0;
                tick   <= 1'b1;
            end else begin
                divcnt <= divcnt + 1'b1;
                tick   <= 1'b0;
            end
        end
    end

    logic sda_oe_n;
    assign sda_t = sda_oe_n;

    logic scl_r;
    assign scl = scl_r;

    typedef struct packed { logic [7:0] rega; logic [7:0] val; } regpair_t;

    localparam int N = 6;
    regpair_t rom [N] = '{
        '{8'h12, 8'h80},
        '{8'h11, 8'h01},
        '{8'h12, 8'h04},
        '{8'h40, 8'hD0},
        '{8'h3A, 8'h04},
        '{8'h8C, 8'h00}
    };

    localparam logic [6:0] DEV7 = 7'h21;

    typedef enum logic [3:0] {
        IDLE, LOAD, START1, START2,
        BIT_LOW, BIT_HIGH, ACK_LOW, ACK_HIGH,
        STOP1, STOP2, NEXT, DONE, FAIL
    } state_t;

    state_t st;
    int idx;
    logic [7:0] sh;
    int bitpos;
    logic [1:0] byte_sel;

    function automatic logic od_bit(input logic b);
        od_bit = b ? 1'b1 : 1'b0;
    endfunction

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            st       <= IDLE;
            idx      <= 0;
            done     <= 1'b0;
            busy     <= 1'b0;
            error    <= 1'b0;
            scl_r    <= 1'b1;
            sda_oe_n <= 1'b1;
            sh       <= 8'h00;
            bitpos   <= 7;
            byte_sel <= 0;
        end else if (tick) begin
            case (st)
                IDLE: begin
                    done  <= 1'b0;
                    busy  <= 1'b1;
                    error <= 1'b0;
                    idx   <= 0;
                    st    <= LOAD;
                end

                LOAD: begin
                    byte_sel <= 0;
                    sh     <= {DEV7,1'b0};
                    bitpos <= 7;
                    st     <= START1;
                end

                START1: begin
                    scl_r    <= 1'b1;
                    sda_oe_n <= 1'b1;
                    st       <= START2;
                end

                START2: begin
                    sda_oe_n <= 1'b0;
                    st       <= BIT_LOW;
                end

                BIT_LOW: begin
                    scl_r    <= 1'b0;
                    sda_oe_n <= od_bit(sh[bitpos]);
                    st       <= BIT_HIGH;
                end

                BIT_HIGH: begin
                    scl_r <= 1'b1;
                    if (bitpos == 0) begin
                        st <= ACK_LOW;
                    end else begin
                        bitpos <= bitpos - 1;
                        st <= BIT_LOW;
                    end
                end

                ACK_LOW: begin
                    scl_r    <= 1'b0;
                    sda_oe_n <= 1'b1;
                    st       <= ACK_HIGH;
                end

                ACK_HIGH: begin
                    scl_r <= 1'b1;
                    if (sda_in != 1'b0) begin
                        st <= FAIL;
                    end else begin
                        if (byte_sel == 0) begin
                            byte_sel <= 1;
                            sh <= rom[idx].rega;
                            bitpos <= 7;
                            st <= BIT_LOW;
                        end else if (byte_sel == 1) begin
                            byte_sel <= 2;
                            sh <= rom[idx].val;
                            bitpos <= 7;
                            st <= BIT_LOW;
                        end else begin
                            st <= STOP1;
                        end
                    end
                end

                STOP1: begin
                    scl_r    <= 1'b0;
                    sda_oe_n <= 1'b0;
                    st       <= STOP2;
                end

                STOP2: begin
                    scl_r    <= 1'b1;
                    sda_oe_n <= 1'b1;
                    st       <= NEXT;
                end

                NEXT: begin
                    if (idx == N-1) begin
                        st <= DONE;
                    end else begin
                        idx <= idx + 1;
                        st <= LOAD;
                    end
                end

                DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    st   <= DONE;
                end

                FAIL: begin
                    busy  <= 1'b0;
                    error <= 1'b1;
                    st    <= FAIL;
                end
            endcase
        end
    end
endmodule
