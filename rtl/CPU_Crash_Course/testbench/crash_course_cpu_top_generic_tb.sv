`timescale 1ns / 1ps
module crash_course_cpu_top_generic_tb (
    input clk,
    input clk_en,
    input sync_rst
);

//? Cycle Counter
    //                                                                   //
    //* Connections
        localparam CYCLELIMIT = 1000;
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
    wire             local_clk_en = CycleCount > 0;
    wire             system_start = CycleCount == 4;
    wire             system_idle;
    wire       [7:0] test_input = 8'd42;
    wire [15:0][7:0] io_in = {(test_input + 8'd15),
                              (test_input + 8'd14),
                              (test_input + 8'd13),
                              (test_input + 8'd12),
                              (test_input + 8'd11),
                              (test_input + 8'd10),
                              (test_input + 8'd9),
                              (test_input + 8'd8),
                              (test_input + 8'd7),
                              (test_input + 8'd6),
                              (test_input + 8'd5),
                              (test_input + 8'd4),
                              (test_input + 8'd3),
                              (test_input + 8'd2),
                              (test_input + 8'd1),
                              (test_input + 8'd0)};
    wire             io_read_en;
    wire [15:0][7:0] io_out;
    wire             io_write_en;
//! End Supporting Logic ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ //	
//                                                                   //

//                                                                   //
//! Start Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//	
crash_course_cpu_top_generic cpu_test (
    .clk           (clk),
    .clk_en        (local_clk_en),
    .sync_rst      (sync_rst),
    .system_start  (system_start),
    .system_idle   (system_idle),
    .io_in         (io_in),
    .io_read_en    (io_read_en),
    .io_out        (io_out),
    .io_write_en   (io_write_en)
);
//! End Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//	
//                                                                   //

endmodule : crash_course_cpu_top_generic_tb
