module video_timing(input logic clk, 
                    input logic reset,
                    output logic hsync, 
                    output logic vsync, 
                    output logic vde, 
                    output logic [9:0] x, 
                    output logic [9:0] y,
                    output logic start_of_frame,
                    output logic end_of_frame,
                    output logic end_of_line);

    //Pixel Clock h_tot*v_tot*60 = ~25 MHz

    //Pixel Size
    localparam int h_pixel = 640;
    localparam int v_pixel = 480;
    
    //Pixels Plus Porches 640x480
    localparam int h_tot = 800;
    localparam int v_tot = 525;
    
    //Counter Values
    logic [9:0] h_curr;
    logic [9:0] v_curr;

    // x and y coordinantes
    assign x = h_curr;
    assign y = v_curr;

    //Horizontal Counter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_curr <= 10'b0;
        end
        else if (h_curr == (h_tot - 1)) begin
            h_curr <= 10'b0;
        end
        else begin
            h_curr <= h_curr + 1;
        end
    end

    //Vertical Counter
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            v_curr <= 10'b0;
        end
        else if (h_curr == (h_tot - 1))begin
            if (v_curr == (v_tot - 1)) begin
                v_curr <= 10'b0;
            end
            else begin
                v_curr <= v_curr + 1;
            end
        end
        else begin
            v_curr <= v_curr;
        end
    end

    //Output Signals
    assign vde  = (h_curr < h_pixel) && (v_curr < v_pixel);
    assign hsync =  !((h_curr >= 656) && (h_curr < 752));
    assign vsync = !((v_curr >= 490) && (v_curr < 492));
    assign start_of_frame = (h_curr == 0) && (v_curr == 0);
    assign end_of_frame = (h_curr == (h_tot -1)) && (v_curr ==  (v_tot -1));
    assign end_of_line = (h_curr == (h_tot - 1));
    


endmodule


