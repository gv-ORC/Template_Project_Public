module double_dabble_tb (
    input clk,
    input clk_en,
    input sync_rst
);

//? Cycle Counter
    //                                                                   //
    //* Connections
        localparam CYCLELIMIT = 300;
    //                                                                   //
    //* Counter
        reg  [31:0] CycleCount;
        wire [31:0] NextCycleCount = sync_rst ? 32'd0 : (CycleCount + 1);
        wire        CycleLimitReached = CycleCount == CYCLELIMIT;
        wire CycleCountTrigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (CycleCountTrigger) begin
                CycleCount <= NextCycleCount;
            end
            if (CycleLimitReached) begin
                $display("><><><><><><><>< CYCLECOUNT ELAPSED! ><><><><><><><><");
                $finish;
            end
        end
    //                                                                   //
//?

//                                                                   //
//! Start Supporting Logic ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ //
    localparam integer Input_Bit_Width = 8; //! Minimum of 4
    localparam integer Total_Nibbles = (Input_Bit_Width / 3) + 1;

    wire    [Input_Bit_Width-1:0] bin = CycleCount[Input_Bit_Width-1:0];
    wire                          bin_valid = 1'b1;
    wire [Total_Nibbles-1:0][3:0] nibbles_out;
    wire [Total_Nibbles-1:0]      nibbles_valid;
//! End Supporting Logic ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ //    
//                                                                   //

//                                                                   //
//! Start Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
        double_dabble_top_generic #(
            .Input_Bit_Width(Input_Bit_Width)
        ) double_dabble (
            .clk          (clk),
            .clk_en       (clk_en),
            .sync_rst     (sync_rst),
            .bin          (bin),
            .bin_valid    (bin_valid),
            .nibbles_out  (nibbles_out),
            .nibbles_valid(nibbles_valid)
        );
//! End Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
//                                                                   //

endmodule : double_dabble_tb
