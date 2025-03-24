/**
 *  Module: reset_control
 *
 *  About: Upon a power-on-reset or a user reset event, this module generates
 *         a reset signal of configurable length.
 *
 *         This pulse is generated in the `user_clk` domain. This clock source
 *         should be connected directly to an external or internal oscillator.
 *
 *         `async_rst` is buffered several times to allow for register duplication
 *         to aid in routing and timing issues, as this pulse is designed to be
 *         used as an asynchronous reset pulse for other clock domains.
 *
 *         The resulting `async_rst` can also be used as a `sync_rst` in the
 *         `user_clk` domain.
 *
**/
module reset_control #(
    parameter integer Reset_Delay_Cycles = 1024, // How many cycles after a reset is detected, is it actually forwarded to the rest of the system.
    parameter integer Reset_Pulse_Length = 8,

    parameter integer Press_Validation_Wait_Cycles = 35_000, // 1ms @ 35Mhz
    parameter integer Release_Lockout_Cycles = 3_500_000 // 1/10th of a second @ 35Mhz
)(
    input  user_clk,
    input  por_n, // Goes 0 when system initialized, holds system in-active when 1.

    input  user_rst_n,

    output async_rst
);

//? Input Control
    //                                                                       //
    //* Common Connections
        wire por_check;
        wire local_clk_en;
        wire debounced_reset;
    //                                                                       //
    //* Power-On-Reset_n Buffer
        reg  [3:0] por_n_current;
        wire [3:0] por_n_next = {por_n_current[2:0], por_n};
        always_ff @(posedge user_clk) begin
            por_n_current <= por_n_next;
        end
        assign por_check = por_n_current[1] && ~por_n_current[0]; // Falling Edge
        assign local_clk_en = ~por_n_current[3];
    //                                                                       //
    //* Reset Debouncer
        monostable_debouncer #(
            .Press_Validation_Wait_Cycles(Press_Validation_Wait_Cycles),
            .Release_Lockout_Cycles      (Release_Lockout_Cycles),
            .Pulse_Length                (1),
            .Repeat_Wait_Cycles          (0)
        ) button_debouncer (
            .clk            (user_clk),
            .clk_en         (local_clk_en),
            .sync_rst       (por_check),
            .repeat_en      (1'b0),
            .io_in          (~user_rst_n),
            .debounced_pulse(debounced_reset)
        );
    //                                                                       //
//?

//? State Control
    //                                                                       //
    //* Common Connections and Parameters
        localparam bit Length_Pulse_Longer = Reset_Pulse_Length >= Reset_Delay_Cycles;
        localparam     Longest_Wait = Length_Pulse_Longer
                                    ? Reset_Pulse_Length
                                    : Reset_Delay_Cycles;
        localparam     Counter_Bit_Width = $clog2(Longest_Wait);

        wire cycle_limit_elapsed;
    //                                                                       //
    //* Waiting
        reg  waiting_current;
        wire waiting_next = (por_check || debounced_reset) && ~cycle_limit_elapsed;
        wire waiting_trigger = por_check
                            || (local_clk_en && debounced_reset)
                            || (local_clk_en && cycle_limit_elapsed);
        always_ff @(posedge user_clk) begin
            if (waiting_trigger) begin
                waiting_current <= waiting_next;
            end
        end
    //                                                                       //
    //* Active
        reg  active_current;
        wire active_next = ~por_check && waiting_current && ~active_current;
        wire active_trigger = por_check
                           || (local_clk_en && cycle_limit_elapsed);
        always_ff @(posedge user_clk) begin
            if (active_trigger) begin
                active_current <= active_next;
            end
        end
    //                                                                       //
    //* Cycle Limit
        wire [Counter_Bit_Width-1:0] counter_limit = active_current
                                                   ? Counter_Bit_Width'(Reset_Pulse_Length - 1)
                                                   : Counter_Bit_Width'(Reset_Delay_Cycles - 1);
    //                                                                       //
    //* Cycle Counter
        reg   [Counter_Bit_Width-1:0] cycle_count_current;
        assign                        cycle_limit_elapsed = cycle_count_current == counter_limit;
        wire  [Counter_Bit_Width-1:0] cycle_count_next = (por_check || cycle_limit_elapsed)
                                                       ? Counter_Bit_Width'(0)
                                                       : (cycle_count_current + Counter_Bit_Width'(1));
        wire                          cycle_count_trigger = por_check
                                                         || (local_clk_en && waiting_current)
                                                         || (local_clk_en && active_current);
        always_ff @(posedge user_clk) begin
            if (cycle_count_trigger) begin
                cycle_count_current <= cycle_count_next;
            end
        end
    //                                                                       //
//?

//? Output Control
    //                                                                       //
    //* Buffer Chain - 4x
        reg  [3:0] output_buffer_current;
        wire [3:0] output_buffer_next = {output_buffer_current[2:0], active_current};
        always_ff @(posedge user_clk) begin
            output_buffer_current <= output_buffer_next;
        end
        assign async_rst = output_buffer_current[3];
    //                                                                       //
//?

endmodule : reset_control
