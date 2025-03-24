/**
 *  Module: adc128s022_channel_control
 *
 *  About: 
 *
 *  Ports:
 *
**/
module adc128s022_channel_control #(
    parameter integer Channel_Index = 0,
    parameter     bit Upper_Channel = 1'b0
)(
    input         clk,
    input         clk_en,
    input         sync_rst,

    input         single_active,
    input   [2:0] active_address,
    input   [1:0] burst_offset,

    input         transfer_start_req,
    input         transfer_end_req,
    input  [31:0] transfer_cipo_data,

    output [11:0] channel_data,
    output        channel_valid
);

//? State
    //                                                                       //
    //* Common Connections
        wire [2:0] active_index = {2'(Channel_Index), Upper_Channel};
    //                                                                       //
    //* Data
        reg    [11:0] channel_current;
        logic  [11:0] channel_next;
        wire    [1:0] channel_next_condition;
        assign        channel_next_condition[0] = single_active;
        assign        channel_next_condition[1] = sync_rst;
        always_comb begin : channel_next_mux
            case (channel_next_condition)
                2'b00  : channel_next = transfer_cipo_data[27:16];
                2'b01  : channel_next = transfer_cipo_data[11:0];
                2'b10  : channel_next = 12'd0;
                2'b11  : channel_next = 12'd0;
                default: channel_next = 12'd0;
            endcase
        end
        wire       channel_trigger = sync_rst
                                  || (clk_en && single_active && transfer_end_req && (active_address == active_index))  // Single
                                  || (clk_en && ~single_active && transfer_end_req && (burst_offset == 2'(Channel_Index))); // Burst
        always_ff @(posedge clk) begin
            if (channel_trigger) begin
                channel_current <= channel_next;
            end
        end
    //                                                                       //
    //* Single Valid
        reg  single_valid_current;
        wire single_valid_next = ~sync_rst && ~transfer_start_req && transfer_end_req;
        wire single_valid_trigger = sync_rst
                                 || (clk_en && single_active && (active_address == active_index) && transfer_start_req)
                                 || (clk_en && single_active && (active_address == active_index) && transfer_end_req)
                                 || (clk_en && ~single_active && (burst_offset == 2'(Channel_Index)) && transfer_end_req);
        always_ff @(posedge clk) begin
            if (single_valid_trigger) begin
                single_valid_current <= single_valid_next;
            end
        end
    //                                                                       //
    //* Burst Valid
        reg  burst_valid_current;
        wire burst_valid_next = ~sync_rst && ~transfer_start_req && transfer_end_req;
        wire burst_valid_trigger = sync_rst
                                      || (clk_en && ~single_active && (burst_offset == 2'(Channel_Index)) && transfer_start_req)
                                      || (clk_en && ~single_active && (burst_offset == 2'(Channel_Index)) && transfer_end_req)
                                      || (clk_en && single_active && (active_address == active_index) && transfer_end_req);
        always_ff @(posedge clk) begin
            if (burst_valid_trigger) begin
                burst_valid_current <= burst_valid_next;
            end
        end
    //                                                                       //
    //* Output Assignment
        assign channel_data = channel_current;
        assign channel_valid = single_valid_current && burst_valid_current;
    //                                                                       //
//?

endmodule : adc128s022_channel_control
