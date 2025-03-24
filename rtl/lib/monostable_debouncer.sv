/**
 *  Module: monostable_debouncer
 *
 *  About: Creates a debounced_pulse of configurable length every time a button is pressed.
 *         Then locks out the detection of any additional button presses until
 *         a configurable number cycles have passed.
 *
**/
module monostable_debouncer #(
    parameter integer Press_Validation_Wait_Cycles = 35_000, // 1ms @ 35Mhz
    parameter integer Release_Lockout_Cycles = 3_500_000, // 1/10th of a second @ 35Mhz
    parameter integer Pulse_Length = 1,
    parameter integer Repeat_Wait_Cycles = 7_000_000 // 1/5th of a second @ 35Mhz
)(
    input  clk,
    input  clk_en,
    input  sync_rst,

    input  repeat_en, // When button is held, pulses are triggered every time `Repeat_Wait_Cycles" elapses.

    input  io_in, // Active High

    output debounced_pulse // Active High
);

//? Input Control
    //                                                                       //
    //* Common Connections
        wire press_check;
        wire release_check;
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
        reg  [1:0] input_buffer_current;
        wire [1:0] input_buffer_next = sync_rst
                                     ? 2'd0
                                     : {input_buffer_current[0], blind_buffer_current[1]};
        wire       input_buffer_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (input_buffer_trigger) begin
                input_buffer_current <= input_buffer_next;
            end
        end
        assign press_check = ~input_buffer_current[1] && input_buffer_current[0];   // Rising Edge
        assign release_check = input_buffer_current[1] && ~input_buffer_current[0]; // Falling Edge
    //                                                                       //
//?

//? State Control
    //                                                                       //
    //* Common Connections and Parameters
        localparam bit Press_Longer_Than_Release = Release_Lockout_Cycles >= Press_Validation_Wait_Cycles;
        localparam     Longest_Edge = Press_Longer_Than_Release
                                    ? Release_Lockout_Cycles
                                    : Press_Validation_Wait_Cycles;
        localparam bit Repeat_Longer_Than_Edge = Repeat_Wait_Cycles >= Longest_Edge;
        localparam     Longest_Wait = Repeat_Longer_Than_Edge
                                    ? Repeat_Wait_Cycles
                                    : Longest_Edge;
        localparam     Counter_Bit_Width = $clog2(Longest_Wait);

        wire       counter_enabled;
        wire       counter_clear;

        wire validity_check = input_buffer_current[0];
        wire counter_limit_elapsed;

        reg  [1:0] state_current;
        wire       pulse_check = (~state_current[1] && state_current[0] && counter_limit_elapsed && validity_check)  // Validation
                              || (state_current[1] && ~state_current[0] && counter_limit_elapsed && validity_check); // Repeat
    //                                                                       //
    //* State
        wire        stable_counter_clear = release_check || counter_limit_elapsed;
        logic [4:0] state_vector;
        always_comb begin : state_update_mux
            case (state_current)
                //*                       Next Trigger -         Counter Enable - Counter Clear        - Next State
                2'b00   : state_vector = {press_check,           press_check,     press_check,           2'b01};                // Idle
                2'b01   : state_vector = {counter_limit_elapsed, 1'b1,            counter_limit_elapsed, validity_check, 1'b0}; // Validation
                2'b10   : state_vector = {release_check,         repeat_en,       stable_counter_clear,  2'b11};                // Stable
                2'b11   : state_vector = {counter_limit_elapsed, 1'b1,            counter_limit_elapsed, 2'b00};                // Lockout
                default : state_vector = {1'b1,                  1'b0,            1'b0,                  2'b00};
            endcase
        end
        wire [1:0] state_next = sync_rst
                              ? 2'd0
                              : state_vector[1:0];
        wire       state_trigger = sync_rst
                                || (clk_en && state_vector[4]);
        always_ff @(posedge clk) begin
            if (state_trigger) begin
                state_current <= state_next;
            end
        end
        assign counter_enabled = state_vector[3];
        assign counter_clear = state_vector[2];
    //                                                                       //\
    //* Counter Limit
        logic [Counter_Bit_Width-1:0] counter_limit;
        always_comb begin : counter_limit_mux
            case (state_current)
                2'b00  : counter_limit = Counter_Bit_Width'(0);
                2'b01  : counter_limit = Counter_Bit_Width'(Press_Validation_Wait_Cycles - 1);
                2'b10  : counter_limit = Counter_Bit_Width'(Repeat_Wait_Cycles - 1);
                2'b11  : counter_limit = Counter_Bit_Width'(Release_Lockout_Cycles - 1);
                default: counter_limit = Counter_Bit_Width'(0);
            endcase
        end
    //                                                                       //\
    //* Cycle Counter
        reg    [Counter_Bit_Width-1:0] cycle_count_current;
        wire   [Counter_Bit_Width-1:0] cycle_count_next = (sync_rst || counter_clear)
                                                        ? Counter_Bit_Width'(0)
                                                        : (cycle_count_current + Counter_Bit_Width'(1));
        wire                           cycle_count_trigger = sync_rst
                                                          || (clk_en && counter_enabled)
                                                          || (clk_en && counter_clear);
        always_ff @(posedge clk) begin
            if (cycle_count_trigger) begin
                cycle_count_current <= cycle_count_next;
            end
        end
        assign counter_limit_elapsed = cycle_count_current == counter_limit;
    //                                                                       //
//?

//? Output Control
    //                                                                       //
    //* Parameterized Pulse Generation
        wire debounced_pulse_check;
        generate
            //                                                               //
            //* Zero Exception - Throw a simulation error
            if (Pulse_Length <= 0) begin : Zero_Cycle_Exception
                assign debounced_pulse_check = 1'b0;
                always_ff @(posedge clk) begin
                    $display(" ~ ~ ~ ~ ~User Defined Error: Monostable Pulse Length Set to Zero or Less! ~ ~ ~ ~ ~");
                    $finish();
                end
            //                                                               //
            end
            else if (Pulse_Length == 1) begin : Single_Cycle_Pulse
            //                                                               //
            //* Active
                reg  [1:0] pulse_check_monostable_current;
                wire [1:0] pulse_check_monostable_next = sync_rst
                                                       ? 2'd0
                                                       : {pulse_check_monostable_current[0], pulse_check};
                wire       pulse_check_monostable_trigger = sync_rst || clk_en;
                always_ff @(posedge clk) begin
                    if (pulse_check_monostable_trigger) begin
                        pulse_check_monostable_current <= pulse_check_monostable_next;
                    end
                end
                assign debounced_pulse_check = ~pulse_check_monostable_current[1] && pulse_check_monostable_current[0];
            //                                                               //
            end
            else begin : Multi_Cycle_Pulse
            //                                                               //
            //* Common Connections and Parameters
                localparam Pulse_Count_Bit_Width = $clog2(Pulse_Length);

                wire pulse_elapsed;
            //                                                               //
            //* Active
                reg  pulse_active_current;
                wire pulse_active_next = ~sync_rst && pulse_check && ~pulse_elapsed;
                wire pulse_active_trigger = sync_rst
                                         || (clk_en && pulse_check)
                                         || (clk_en && ~pulse_elapsed);
                always_ff @(posedge clk) begin
                    if (pulse_active_trigger) begin
                        pulse_active_current <= pulse_active_next;
                    end
                end
                assign debounced_pulse_check = pulse_active_current;
            //                                                               //
            //* Cycle Count
                reg  [Pulse_Count_Bit_Width:0] pulse_cycle_count_current;
                wire [Pulse_Count_Bit_Width:0] pulse_cycle_count_next = (sync_rst || pulse_elapsed)
                                                                      ? Pulse_Count_Bit_Width'(0)
                                                                      : (pulse_cycle_count_current + Pulse_Count_Bit_Width'(1));
                wire        pulse_cycle_count_trigger = sync_rst
                                                     || (clk_en && pulse_active_current);
                always_ff @(posedge clk) begin
                    if (pulse_cycle_count_trigger) begin
                        pulse_cycle_count_current <= pulse_cycle_count_next;
                    end
                end
                assign pulse_elapsed = pulse_cycle_count_current == (Pulse_Length - 1);
            //                                                               //
            end
        endgenerate
    //                                                                       //
    //* Pulse Buffer
        reg  output_buffer_current;
        wire output_buffer_next = ~sync_rst && debounced_pulse_check;
        wire output_buffer_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (output_buffer_trigger) begin
                output_buffer_current <= output_buffer_next;
            end
        end
        assign debounced_pulse = output_buffer_current;
    //                                                                       //
//?

endmodule : monostable_debouncer
