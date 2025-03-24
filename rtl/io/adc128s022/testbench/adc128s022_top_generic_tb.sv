module adc128S022_top_generic_tb (
    input clk,
    input clk_en,
    input sync_rst
);

//? Cycle Counter
    //                                                                   //
    //* Connections
        localparam CYCLELIMIT = 4000;
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
    //* Control   
        wire             single_update_req = CycleCount == 8;
        wire             burst_update_req = CycleCount == 500;
        wire             update_ack;
        wire       [2:0] channel_addr = 3'b000;
        wire [7:0][11:0] channels_out;
        wire [7:0]       channel_valid;
    //* Interface
        wire                        sclk;
        wire                        cs_n;
        wire                        copi;
        wire                        copi_en;
        wire                        cipo = 1'b1;

//! End Supporting Logic ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ //    
//                                                                   //

//                                                                   //
//! Start Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
    adc128s022_top_generic adc_controller (
        .clk              (clk),
        .clk_en           (clk_en),
        .sync_rst         (sync_rst),
        .single_update_req(single_update_req),
        .burst_update_req (burst_update_req),
        .update_ack       (update_ack),
        .channel_addr     (channel_addr),
        .channels_out     (channels_out),
        .channel_valid    (channel_valid),
        .sclk             (sclk),
        .cs_n             (cs_n),
        .copi             (copi),
        .copi_en          (copi_en),
        .cipo             (cipo)
    );
//! End Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
//                                                                   //

endmodule : adc128S022_top_generic_tb
