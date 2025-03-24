module monostable_debouncer_tb (
    input clk,
    input clk_en,
    input sync_rst
);

//? Cycle Counter
    //                                                                   //
    //* Connections
        localparam CYCLELIMIT = 256;
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
    wire async_rst = CycleCount == 8;
    wire clk_lock = CycleCount > 15;
    wire en;
    wire rst;
    wire init;
//! End Supporting Logic ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ //    
//                                                                   //

//                                                                   //
//! Start Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
        domain_control sys_domain_control (
            .clk      (clk),
            .async_rst(async_rst),
            .clk_lock (clk_lock),
            .clk_en   (en),
            .sync_rst (rst),
            .init     (init)
        );
//! End Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
//                                                                   //

endmodule : monostable_debouncer_tb
