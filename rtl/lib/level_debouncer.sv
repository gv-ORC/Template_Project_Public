/**
 *  Module: level_debouncer
 *
 *  About: Creates a stable High/Low signal based on a bouncy switch state
 *
 *  Ports:
 *
**/
module level_debouncer #(
    parameter integer Validation_Wait_Cycles = 350_000, // 10ms @ 35Mhz
    parameter integer Lockout_Cycles = 3_500_000      // 1/10th of a second @ 35Mhz
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  io_in,

    output debounced_level
);

/*
    When `io` changes state, a validation timer starts. The state then changes to whatever the input is at the end of that validation
    The IO is then locked-out from any changes for a set amount of time
*/

//? Input Control
    //                                                                       //
    //* "Blind" Input Buffer
    /*
    This register does not use any clk_en or reset signal in order to
    minimize the routing and timing complexity between the external FPGA pin
    and the internal FPGA logic.
    */
        reg  [1:0] blind_buffer_current;
        wire [1:0] blind_buffer_next = {blind_buffer_current[0], io_in};
        always_ff @(posedge clk) begin
            blind_buffer_current <= blind_buffer_next;
        end
    //                                                                       //
    //* Controlled Buffer
        reg  input_buffer_current;
        wire input_buffer_next = ~sync_rst && blind_buffer_current[1];
        wire input_buffer_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (input_buffer_trigger) begin
                input_buffer_current <= input_buffer_next;
            end
        end
    //                                                                       //
//?

//? State Control
    //                                                                       //
    //* Common Connections and Parameters
        localparam bit Validation_Wait_Longer = Validation_Wait_Cycles >= Lockout_Cycles;
        localparam     Longest_Wait = Validation_Wait_Longer
                                    ? Validation_Wait_Cycles
                                    : Lockout_Cycles;
        localparam     Counter_Bit_Width = $clog2(Longest_Wait);

        wire validating;
        wire cycle_limit_elapsed;
    //                                                                       //
    //* Active Level
        reg  level_current;
        wire level_next = ~sync_rst && input_buffer_current;
        wire level_change_check = level_current ^ input_buffer_current;
        wire level_trigger = sync_rst
                          || (clk_en && validating && cycle_limit_elapsed && level_change_check);
        always_ff @(posedge clk) begin
            if (level_trigger) begin
                level_current <= level_next;
            end
        end
    //                                                                       //
    //* Transition State
        /*
        * Name       - Bin - Trigger             - Next
          Stable     - 00  - edge_check          - 01
          Validation - 01  - cycle_limit_elapsed - 10, 00
          Lockout    - 10  - cycle_limit_elapsed - 00
        */
        reg   [1:0] state_current;
        logic [2:0] state_vector;
        always_comb begin : state_update_mux
            case (state_current)
                //*                       Trigger            - Next State
                2'b00   : state_vector = {level_change_check,  2'b01}; // Stable
                2'b01   : state_vector = {cycle_limit_elapsed, level_change_check, 1'b0}; // Validation
                2'b10   : state_vector = {cycle_limit_elapsed, 2'b00}; // Lockout
                default : state_vector = {1'b1,                2'b00};
            endcase
        end
        wire [1:0] state_next = sync_rst 
                              ? 2'd0
                              : state_vector[1:0];
        wire        state_trigger = sync_rst
                                 || (clk_en && state_vector[2]);
        always_ff @(posedge clk) begin
            if (state_trigger) begin
                state_current <= state_next;
            end
        end
        assign validating = state_current[0];
    //                                                                       //
    //* Counter Limit
        wire [Counter_Bit_Width-1:0] counter_limit = state_current[1]
                                                   ? Counter_Bit_Width'(Lockout_Cycles - 1)
                                                   : Counter_Bit_Width'(Validation_Wait_Cycles - 1);
    //                                                                       //
    //* Cycle Counter
        reg    [Counter_Bit_Width-1:0] cycle_count_current;
        assign                         cycle_limit_elapsed = cycle_count_current == counter_limit;
        wire   [Counter_Bit_Width-1:0] cycle_count_next = (sync_rst || cycle_limit_elapsed)
                                                        ? Counter_Bit_Width'(0)
                                                        : (cycle_count_current + Counter_Bit_Width'(1));
        wire                           cycle_count_trigger = sync_rst
                                                          || (clk_en && state_current[0])
                                                          || (clk_en && state_current[1]);
        always_ff @(posedge clk) begin
            if (cycle_count_trigger) begin
                cycle_count_current <= cycle_count_next;
            end
        end
    //                                                                       //
//?

//? Output Control
    //                                                                       //
    //* Level Buffer
        reg  output_buffer_current;
        wire output_buffer_next = ~sync_rst && level_current;
        wire output_buffer_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (output_buffer_trigger) begin
                output_buffer_current <= output_buffer_next;
            end
        end
        assign debounced_level = output_buffer_current;
    //                                                                       //
//?

endmodule : level_debouncer
