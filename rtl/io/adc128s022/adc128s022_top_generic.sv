/**
 *  Module: adc128s022_top_generic
 *
 *  About: 
 *
 *  Ports:
 *
**/
module adc128s022_top_generic (
    input              clk, // 50Mhz
    input              clk_en,
    input              sync_rst,

    input              single_update_req,
    input              burst_update_req, // Update all 8 channels (Takes priority)
    output             update_ack,
    input        [2:0] channel_addr,

    output [7:0][11:0] channels_out,  // ToDo: Not storing output
    output [7:0]       channel_valid, // ToDo: Not storing output

    output             sclk,
    output             cs_n,
    output             copi,
    output             copi_en, // Raise when wanting to Transmit data - Not required
    input              cipo
);

/*
    16 bit transfer
    8b control {X, X, A2, A1, A0, X, X, X} 8b don't car after
    12b data with 4b leading 0s {16b total}

    burst is back to back transfers without a gap

    * Interface Modes:
    > Update Single Channel
    > Update All Channels

*/

//? State Control
    /*
    
    Idle,         00
    Start-Waiting 01
    End-Waiting   10 - Idle if decrementer at 00

    2b decrementer, start at 11 for burst, 00 for single, decrement on every end
    
    */
    //                                                                       //
    //* Common Connections
        wire transfer_start_req;
        wire transfer_start_ack;
        wire transfer_end_req;
        wire transfer_end_ack;

        wire offset_equals_zero;
    //                                                                       //
    //* State
        reg   [1:0] state_current;
        wire        idle_trigger = single_update_req || burst_update_req;
        logic [2:0] state_vector;
        always_comb begin : state_update_mux
            case (state_current)
                //*                      Trigger           - Next State
                2'b00  : state_vector = {idle_trigger,       2'b01}; // Idle
                2'b01  : state_vector = {transfer_start_ack, 2'b10}; // Start Waiting
                2'b10  : state_vector = {transfer_end_req,   1'b0, ~offset_equals_zero}; // End Waiting
                default : state_vector = 0;
            endcase
        end
        wire [1:0] state_next = sync_rst ? 2'd0 : state_vector[1:0];
        wire        state_trigger = sync_rst || (clk_en && state_vector[2]);
        always_ff @(posedge clk) begin
            if (state_trigger) begin
                state_current <= state_next;
            end
        end
        assign transfer_start_req = state_current[0];
        assign transfer_end_ack = state_current[1];
        assign update_ack = state_current == 2'b00;
    //                                                                       //
    //* Single Active - for address selection
        reg  single_active_current;
        wire single_active_next = ~sync_rst && single_update_req && ~transfer_end_req;
        wire single_active_trigger = sync_rst
                                  || (clk_en && single_update_req && update_ack)
                                  || (clk_en && transfer_end_req && transfer_end_ack);
        always_ff @(posedge clk) begin
            if (single_active_trigger) begin
                single_active_current <= single_active_next;
            end
        end
    //                                                                       //
    //* Burst Offset - 11 on burst, 00 on single
        reg    [1:0] burst_offset_current;
        logic  [1:0] burst_offset_next;
        wire   [1:0] burst_offset_next_condition;
        assign       burst_offset_next_condition[0] = burst_update_req;
        assign       burst_offset_next_condition[1] = update_ack || sync_rst;
        always_comb begin : burst_offset_next_mux
            case (burst_offset_next_condition)
                2'b00  : burst_offset_next = burst_offset_current - 2'd1; // Normal Operation
                2'b01  : burst_offset_next = burst_offset_current - 2'd1; // Normal Operation
                2'b10  : burst_offset_next = 2'b00;                       // Reset, Single Init
                2'b11  : burst_offset_next = {~sync_rst, ~sync_rst};      // Reset, Burst Init
                default: burst_offset_next = 2'b00;
            endcase
        end
        assign offset_equals_zero = burst_offset_current == 2'b00;
        wire   burst_offset_trigger = sync_rst
                                   || (clk_en && single_update_req && update_ack)
                                   || (clk_en && burst_update_req && update_ack)
                                   || (clk_en && transfer_end_req && transfer_end_ack && ~offset_equals_zero);
        always_ff @(posedge clk) begin
            if (burst_offset_trigger) begin
                burst_offset_current <= burst_offset_next;
            end
        end
    //                                                                       //
    //* Active Address - 000 on burst, `channel_addr` on single
        reg  [2:0] active_address_current;
        wire [2:0] active_address_next = sync_rst
                                       ? 3'd0 
                                       : channel_addr;
        wire       active_address_trigger = sync_rst
                                         || (clk_en && single_update_req && update_ack);
        always_ff @(posedge clk) begin
            if (active_address_trigger) begin
                active_address_current <= active_address_next;
            end
        end
    //                                                                       //
//?

//? SPI Controller
    //                                                                       //
    //* Common Connections
        wire  [5:0] transfer_width = single_active_current
                                   ? 6'd16
                                   : 6'd32;
        wire [31:0] transfer_copi_data = single_active_current
                                       ? {2'b00, active_address_current, 3'b000, 8'd0,  16'd0}
                                       : {2'b00, burst_offset_current, 4'b1000, 8'd0,  2'b00, burst_offset_current, 4'b0000, 8'd0};
        wire [31:0] transfer_copi_mask = single_active_current
                                       ? {16'hFF00, 16'd0}
                                       : {16'hFF00, 16'hFF00};
        wire [31:0] transfer_cipo_mask = single_active_current
                                       ? {16'h0FFF, 16'd0}
                                       : {16'h0FFF, 16'hFFFF};
        wire [31:0] transfer_cipo_data;
    //                                                                       //
    //* SPI Interface
        spi_top_generic #(
            .Max_Bit_Width(32)
        ) spi_controller (
            .clk                         (clk),
            .clk_en                      (clk_en),
            .sync_rst                    (sync_rst),
            .default_sclk_polarity       (1'b1), // Same as cpol
            .transfer_start_req          (transfer_start_req),
            .transfer_start_ack          (transfer_start_ack),
            .transfer_start_nak          (), // Dont Care
            .transfer_clock_divisor      (16'd20),
            .transfer_cpol               (1'b1),
            .transfer_cpha               (1'b1),
            .transfer_sclk_start_polarity(1'b1),
            .transfer_width              (transfer_width),
            .transfer_copi_data          (transfer_copi_data),
            .transfer_copi_mask          (transfer_copi_mask),
            .transfer_cipo_mask          (transfer_cipo_mask),
            .transfer_end_req            (transfer_end_req),
            .transfer_end_ack            (transfer_end_ack),
            .transfer_cipo_data          (transfer_cipo_data),
            .chip_select_override        (1'b0),
            .sclk                        (sclk),
            .cs_n                        (cs_n),
            .copi                        (copi),
            .copi_en                     (copi_en),
            .cipo                        (cipo)
        );
    //                                                                       //
//?

//? Channel Control
    //                                                                       //
    //* Channel Tracking
        genvar channel_index;
        generate
            for (channel_index = 0; channel_index < 4; channel_index = channel_index + 1) begin : Channel_Generation
                //                                                           //
                // Output Control
                localparam upper_index = (channel_index * 2) + 1;
                localparam lower_index = (channel_index * 2);
                // Upper Channel
                adc128s022_channel_control #(
                    .Channel_Index(channel_index),
                    .Upper_Channel(1'b1)
                ) upper_channel (
                    .clk               (clk),
                    .clk_en            (clk_en),
                    .sync_rst          (sync_rst),
                    .single_active     (single_active_current),
                    .active_address    (active_address_current),
                    .burst_offset      (burst_offset_current),
                    .transfer_start_req(transfer_start_req),
                    .transfer_end_req  (transfer_end_req),
                    .transfer_cipo_data(transfer_cipo_data),
                    .channel_data      (channels_out[upper_index]),
                    .channel_valid     (channel_valid[upper_index])
                );
                // Lower Channel
                adc128s022_channel_control #(
                    .Channel_Index(channel_index),
                    .Upper_Channel(1'b0)
                ) lower_channel (
                    .clk               (clk),
                    .clk_en            (clk_en),
                    .sync_rst          (sync_rst),
                    .single_active     (single_active_current),
                    .active_address    (active_address_current),
                    .burst_offset      (burst_offset_current),
                    .transfer_start_req(transfer_start_req),
                    .transfer_end_req  (transfer_end_req),
                    .transfer_cipo_data(transfer_cipo_data),
                    .channel_data      (channels_out[lower_index]),
                    .channel_valid     (channel_valid[lower_index])
                );
                //                                                           //
            end
        endgenerate
    //                                                                       //
//?
endmodule : adc128s022_top_generic
