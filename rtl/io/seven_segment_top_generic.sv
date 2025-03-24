/**
 *  Module: seven_segment_top_generic
 *
 *  About: 
 *
 *  Ports:
 *
**/
module seven_segment_top_generic (
    input        clk,
    input        clk_en,
    input        sync_rst,

    input [31:0] clk_pps,

    input        increment,
    input        decrement,
    input        clear,

    //* RGB LED Tests
    output [2:0] count_lower,
    input  [6:0] digit_3_in,

    //* Cyclone V Outputs
    output [6:0] digit_0,
    output [6:0] digit_1,
    output [6:0] digit_2,
    output [6:0] digit_3,
    //* Cyclone 10 Outputs
    output [7:0] segments,
    output [3:0] digit_select
);

//? State Control
    //                                                                       //
    //* Counter
        reg    [7:0] counter_current;
        logic  [7:0] counter_next;
        wire   [1:0] counter_next_condition;
        assign       counter_next_condition[0] = decrement;
        assign       counter_next_condition[1] = clear || sync_rst;
        always_comb begin : counter_next_mux
            case (counter_next_condition)
                2'b00  : counter_next = counter_current + 8'd1; // Increment
                2'b01  : counter_next = counter_current - 8'd1; // Decrement 
                2'b10  : counter_next = 8'd0; // Clear / Reset
                2'b11  : counter_next = 8'd0; // Clear / Reset
                default: counter_next = 8'd0;
            endcase
        end
        wire counter_trigger = sync_rst
                            || (clk_en && increment)
                            || (clk_en && decrement)
                            || (clk_en && clear);
        always_ff @(posedge clk) begin
            if (counter_trigger) begin
                counter_current <= counter_next;
            end
        end
    //                                                                       //
    //* RGB LED Test Assignments
        assign count_lower = counter_current[2:0];
    //                                                                       //
//?

//? Binary to BCD
    //                                                                       //
    //* Common Connections
        wire [2:0][3:0] converted_bcd;
        wire [2:0]      bcd_valid_vector;
    //                                                                       //
    //* Double Dabble
        double_dabble_top_generic #(
            .Input_Bit_Width(8)
        ) double_dabble (
            .clk          (clk),
            .clk_en       (clk_en),
            .sync_rst     (sync_rst),
            .bin          (counter_current),
            .bin_valid    (1'b1),
            .nibbles_out  (converted_bcd),
            .nibbles_valid(bcd_valid_vector)
        );
    //                                                                       //
//?

//? Display Driver
    //                                                                       //
    //* Common Connections
        wire [6:0] converted_digit_0;
        wire [6:0] converted_digit_1;
        wire [6:0] converted_digit_2;
    //                                                                       //
    //* BCD to Seven Segment
        // Digit 0
        seven_segment_bcd_converter digit_0_bcd_conversion (
            .bcd          (converted_bcd[0]),
            .bcd_valid    (bcd_valid_vector[0]),
            .seven_segment(converted_digit_0)
        );
        // Digit 1  
        seven_segment_bcd_converter digit_1_bcd_conversion (
            .bcd          (converted_bcd[1]),
            .bcd_valid    (bcd_valid_vector[1]),
            .seven_segment(converted_digit_1)
        );
        // Digit 2
        seven_segment_bcd_converter digit_2_bcd_conversion (
            .bcd          (converted_bcd[2]),
            .bcd_valid    (bcd_valid_vector[2]),
            .seven_segment(converted_digit_2)
        );
    //                                                                       //
    //* Digit Output
        // Digit 0
        reg  [6:0] digit_0_current;
        wire [6:0] digit_0_next = ~converted_digit_0;
        always_ff @(posedge clk) begin
            digit_0_current <= digit_0_next;
        end
        assign digit_0 = digit_0_current;
        // Digit 1
        reg  [6:0] digit_1_current;
        wire [6:0] digit_1_next = ~converted_digit_1;
        always_ff @(posedge clk) begin
            digit_1_current <= digit_1_next;
        end
        assign digit_1 = digit_1_current;
        // Digit 2
        reg  [6:0] digit_2_current;
        wire [6:0] digit_2_next = ~converted_digit_2;
        always_ff @(posedge clk) begin
            digit_2_current <= digit_2_next;
        end
        assign digit_2 = digit_2_current;
        // Digit 3
        reg  [6:0] digit_3_current;
        wire [6:0] digit_3_next = ~digit_3_in;
        always_ff @(posedge clk) begin
            digit_3_current <= digit_3_next;
        end
        assign digit_3 = digit_3_current;
    //                                                                       //
    //* Multiplexer
        seven_segment_multiplexer multiplexer (
            .clk         (clk),
            .clk_en      (clk_en),
            .sync_rst    (sync_rst),
            .clk_pps     (clk_pps),
            .digit_0     (converted_digit_0),
            .digit_1     (converted_digit_1),
            .digit_2     (converted_digit_2),
            .digit_3     (digit_3_in),
            .segments    (segments),
            .digit_select(digit_select)
        );
    //                                                                       //
//?

endmodule : seven_segment_top_generic

