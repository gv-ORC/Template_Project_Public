module spi_top_generic_tb (
    input clk,
    input clk_en,
    input sync_rst
);

//? Cycle Counter
    //                                                                   //
    //* Connections
        localparam CYCLELIMIT = 2880;
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

        /*
        * Results
        cpol:cpha:start
        0:0:0 - Good
        1:0:0 - Good
        0:1:0 - 
        1:1:0 - 
        1:0:1 - 
        0:0:1 - 
        1:1:1 - 
        0:1:1 - 
        */
    //* Common Connections
        localparam integer Max_Bit_Width = 32;
        localparam integer Peripheral_Count = 1;
        localparam integer Bit_Index_Width = $clog2(Max_Bit_Width) + 1;

        reg  [15:0] transfer_end_current;

    //* Transfer Start
        wire                        transfer_start_req = (CycleCount == 50) || transfer_end_current[15];
        wire                        transfer_start_ack;
        wire                        transfer_start_nak;
        wire                 [15:0] transfer_clock_divisor = 16'd20;

        reg  [2:0] config_current;
        wire [2:0] config_next = sync_rst ? 3'd0 : (config_current + 3'd1);
        wire       config_trigger = sync_rst || (clk_en && transfer_end_current[7]);
        always_ff @(posedge clk) begin
            if (config_trigger) begin
                config_current <= config_next;
            end
        end

        wire                        transfer_cpol = config_current[2];
        wire                        transfer_cpha = config_current[1];
        wire                        transfer_sclk_start_polarity = config_current[0];
        wire  [Bit_Index_Width-1:0] transfer_width = Bit_Index_Width'(16);
        wire    [Max_Bit_Width-1:0] transfer_copi_data = 32'hAA00_0000;
        wire    [Max_Bit_Width-1:0] transfer_copi_mask = 32'hFF00_0000;
        wire    [Max_Bit_Width-1:0] transfer_cipo_mask = 32'h00FF_0000;

    //* Transfer End
        wire                        transfer_end_req;
        
        reg  transfer_end_ack_current;
        wire transfer_end_ack_next = transfer_end_req;
        always_ff @(posedge clk) begin
            transfer_end_ack_current <= transfer_end_ack_next;
        end
        wire                        transfer_end_ack = transfer_end_ack_current;

        wire [15:0] transfer_end_next = sync_rst ? 16'd0 : {transfer_end_current[14:0], (transfer_end_req && transfer_end_ack)};
        wire       transfer_end_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (transfer_end_trigger) begin
                transfer_end_current <= transfer_end_next;
            end
        end
        wire    [Max_Bit_Width-1:0] transfer_cipo_data;

    //* Interface
        wire                        chip_select_override = 1'b0;

        wire                        sclk;
        wire [Peripheral_Count-1:0] cs_n;
        wire                        copi;
        wire                        copi_en;
        wire                        cipo = 1'b1;

//! End Supporting Logic ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ //    
//                                                                   //

//                                                                   //
//! Start Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
    spi_top_generic #(
        .Max_Bit_Width(32)
    ) spi_controller (
        .clk                         (clk),
        .clk_en                      (clk_en),
        .sync_rst                    (sync_rst),
        .default_sclk_polarity       (transfer_cpol),
        .transfer_start_req          (transfer_start_req),
        .transfer_start_ack          (transfer_start_ack),
        .transfer_start_nak          (transfer_start_nak),
        .transfer_clock_divisor      (transfer_clock_divisor),
        .transfer_cpol               (transfer_cpol),
        .transfer_cpha               (transfer_cpha),
        .transfer_sclk_start_polarity(transfer_sclk_start_polarity),
        .transfer_width              (transfer_width),
        .transfer_copi_data          (transfer_copi_data),
        .transfer_copi_mask          (transfer_copi_mask),
        .transfer_cipo_mask          (transfer_cipo_mask),
        .transfer_end_req            (transfer_end_req),
        .transfer_end_ack            (transfer_end_ack),
        .transfer_cipo_data          (transfer_cipo_data),
        .chip_select_override        (chip_select_override),
        .sclk                        (sclk),
        .cs_n                        (cs_n),
        .copi                        (copi),
        .copi_en                     (copi_en),
        .cipo                        (cipo)
    );
//! End Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//    
//                                                                   //

endmodule : spi_top_generic_tb
