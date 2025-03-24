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
    wire [7:0] test = 6 / 3;

    wire user_rst_n = (CycleCount < 50) || (CycleCount > 80);
    wire por_n = CycleCount <= 7;
    wire async_rst;
//! End Supporting Logic ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ //    
//                                                                   //

//                                                                   //
//! Start Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
        reset_control #(
            .Reset_Pulse_Length          (4),
            .Reset_Delay_Cycles          (8),
            .Press_Validation_Wait_Cycles(10),
            .Release_Lockout_Cycles      (20)
        ) reset_controller (
            .user_clk      (clk),
            .user_rst_n    (user_rst_n),
            .por_n         (por_n),
            .async_rst     (async_rst)
        );
//! End Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
//                                                                   //

endmodule : monostable_debouncer_tb
