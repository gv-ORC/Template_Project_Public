/**
 *  Module: rgb_test_top_generic
 *
 *  About: 
 *
 *  Ports:
 *
**/
module rgb_test_top_generic (
    input clk,
    input clk_en,
    input sync_rst,

    input  [2:0] count_lower,
    input        invert_led_state,

    output [6:0] digit_3,
    output [2:0] rgb_state
);

//? State Control
    //                                                                       //
    //* Inversion Control
        reg  invert_current;
        wire invert_next = ~sync_rst && ~invert_current;
        wire invert_trigger = sync_rst || (clk_en && invert_led_state);
        always_ff @(posedge clk) begin
            if (invert_trigger) begin
                invert_current <= invert_next;
            end
        end
    //                                                                       //
    //* Current State
        reg    [2:0] state_current;
        logic  [2:0] state_next;
        wire   [1:0] state_next_condition;
        assign       state_next_condition[0] = invert_current;
        assign       state_next_condition[1] = sync_rst;
        always_comb begin : state_next_mux
            case (state_next_condition)
                2'b00  : state_next = count_lower; // Normal Operation
                2'b01  : state_next = ~count_lower; // Invert
                2'b10  : state_next = 3'd0; // Reset
                2'b11  : state_next = 3'd0; // Reset
                default: state_next = 3'd0;
            endcase
        end
        wire state_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (state_trigger) begin
                state_current <= state_next;
            end
        end
    //                                                                       //
//?

//? Output Control
    //                                                                       //
    //* Common Connections
        wire [6:0] animated_digit_3;
    //                                                                       //
    //* Digit 3 Conversion
        seven_segment_animation animator (
            .frame        (state_current),
            .seven_segment(animated_digit_3)
        );
    //                                                                       //
    //* Digit 3 Buffer
        reg  [6:0] digit_3_current;
        wire [6:0] digit_3_next = sync_rst
                                ? 7'd0
                                : animated_digit_3;
        wire       digit_3_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (digit_3_trigger) begin
                digit_3_current <= digit_3_next;
            end
        end
    //                                                                       //
    //* RGB Buffer
        reg  [2:0] rgb_current;
        wire [2:0] rgb_next = state_current;
        always_ff @(posedge clk) begin
            rgb_current <= rgb_next;
        end
    //                                                                       //
    //* Assignments
        assign digit_3 = digit_3_current;
        assign rgb_state = rgb_current;
    //                                                                       //
//?

endmodule : rgb_test_top_generic
