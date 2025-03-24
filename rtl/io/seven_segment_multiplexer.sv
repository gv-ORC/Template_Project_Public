/**
 *  Module: seven_segment_multiplexer
 *
 *  About: 
 *
 *  Ports:
 *
**/
module seven_segment_multiplexer (
    input        clk,
    input        clk_en,
    input        sync_rst,

    input [31:0] clk_pps,

    input  [6:0] digit_0,
    input  [6:0] digit_1,
    input  [6:0] digit_2,
    input  [6:0] digit_3,

    output [7:0] segments,
    output [3:0] digit_select
);

//? Multiplex Control
    //                                                                       //
    //* Cycle Counter
        reg  [31:0] multiplex_cycle_count_current;
        wire [31:0] multiplex_cycle_limit = clk_pps >> 5'd10; // 1/1024th the clock speed;
        wire        multiplex_cycle_elapsed = multiplex_cycle_count_current == multiplex_cycle_limit;
        wire [31:0] multiplex_cycle_count_next = (sync_rst || multiplex_cycle_elapsed)
                                               ? 32'd0
                                               : (multiplex_cycle_count_current + 32'd1);
        wire        multiplex_cycle_count_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (multiplex_cycle_count_trigger) begin
                multiplex_cycle_count_current <= multiplex_cycle_count_next;
            end
        end
    //                                                                       //
    //* Display Index
        reg  [1:0] display_index_current;
        wire [1:0] display_index_next = sync_rst ? 2'd0 : (display_index_current + 2'd1);
        wire       display_index_trigger = sync_rst || (clk_en && multiplex_cycle_elapsed);
        always_ff @(posedge clk) begin
            if (display_index_trigger) begin
                display_index_current <= display_index_next;
            end
        end
    //                                                                       //
    //* Value Select
        logic [11:0] selected_output;
        always_comb begin : selected_output_mux
            case (display_index_current)
                2'b00  : selected_output = {4'b0001, 1'b0, digit_0};
                2'b01  : selected_output = {4'b0010, 1'b0, digit_1};
                2'b10  : selected_output = {4'b0100, 1'b1, digit_2};
                2'b11  : selected_output = {4'b1000, 1'b0, digit_3};
                default: selected_output = 12'd0;
            endcase
        end
    //                                                                       //
    //* Value Buffer
        reg  [11:0] output_buffer_current;
        wire [11:0] output_buffer_next = sync_rst ? 12'd0 : selected_output;
        wire        output_buffer_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (output_buffer_trigger) begin
                output_buffer_current <= output_buffer_next;
            end
        end
    //                                                                       //
    //* Output Assignments
        assign segments = output_buffer_current[7:0];
        assign digit_select = output_buffer_current[11:8];
    //                                                                       //
//?

endmodule : seven_segment_multiplexer
