/**
 *  Module: io_clock_divider
 *
 *  About: 
 *
 *  Ports:
 *
**/
module io_clock_divider (
    input         clk,
    input         clk_en,
    input         sync_rst,

    input  [15:0] clock_divisor,
    input         default_sclk_polarity,

    // When 0: First Low/Rising, Second High/Falling
    // When 1: First High/Falling, Second Low/Rising
    input         starting_polarity,
    input         clock_start,
    input         ending_polarity,
    input         clock_stop,

    output        clock_state,

    output        first_center,
    output        first_edge,
    output        second_center,
    output        second_edge
);

//? Divisor Control
    //                                                                       //
    //* Buffer
        reg  [15:0] divisor_current;
        wire [15:0] divisor_next = sync_rst
                                 ? 16'd0
                                 : clock_divisor;
        wire        divisor_trigger = sync_rst
                                   || (clk_en && clock_start);
        always_ff @(posedge clk) begin
            if (divisor_trigger) begin
                divisor_current <= divisor_next;
            end
        end
    //                                                                       //
    //* Limits
        wire [15:0] quarter_divisor = {2'd0, divisor_current[15:2]};
        wire [15:0] half_divisor = {1'd0, divisor_current[15:1]};

        wire [15:0] first_center_limit = quarter_divisor - 16'd1; // 25% of the clock period has passed
        wire [15:0] first_edge_limit = half_divisor - 16'd1; // 50% of the clock period has passed
        wire [15:0] second_center_limit = half_divisor + quarter_divisor - 16'd1; // 75% of the clock period has passed
        wire [15:0] second_edge_limit = divisor_current - 16'd1; // 100% of the clock period has passed, reset counter
    //                                                                       //
//?

//? State Control
    //                                                                       //
    //* Common Connections
        wire second_edge_check;
        wire first_edge_check;
    //                                                                       //
    //* Active
        reg  active_current;
        wire active_next = ~sync_rst && clock_start && ~clock_stop;
        wire active_trigger = sync_rst
                           || (clk_en && clock_start)
                           || (clk_en && clock_stop);
        always_ff @(posedge clk) begin
            if (active_trigger) begin
                active_current <= active_next;
            end
        end
    //                                                                       //
    //* Cycle Counter
        reg  [15:0] cycle_counter_current;
        wire [15:0] cycle_counter_next = (sync_rst || clock_start || second_edge_check)
                                       ? 16'd0
                                       : (cycle_counter_current + 16'd1);
        wire        cycle_counter_trigger = sync_rst
                                         || (clk_en && active_current);
        always_ff @(posedge clk) begin
            if (cycle_counter_trigger) begin
                cycle_counter_current <= cycle_counter_next;
            end
        end
    //                                                                       //
    //* Clock State
        reg  clock_state_current;
        wire clock_state_next = (sync_rst && default_sclk_polarity)
                             || (~sync_rst && starting_polarity && clock_start)
                             || (~sync_rst && ending_polarity && clock_stop)
                             || (~sync_rst && active_current && ~clock_state_current);
        wire either_edge_check = second_edge_check || first_edge_check;
        wire clock_state_trigger = sync_rst
                                || (clk_en && either_edge_check && active_current)
                                || (clk_en && clock_start)
                                || (clk_en && clock_stop);
        always_ff @(posedge clk) begin
            if (clock_state_trigger) begin
                clock_state_current <= clock_state_next;
            end
        end

        assign clock_state = clock_state_current;
    //                                                                       //
    //* Event Buffers
        wire   first_center_check = first_center_limit == cycle_counter_current;
        assign first_edge_check = first_edge_limit == cycle_counter_current;
        wire   second_center_check = second_center_limit == cycle_counter_current;
        assign second_edge_check = second_edge_limit == cycle_counter_current;

        reg  [3:0] event_buffers_current;
        wire [3:0] event_buffers_next = sync_rst
                                      ? 4'd0
                                      : {first_center_check, first_edge_check, second_center_check, second_edge_check};
        wire        event_buffers_trigger = sync_rst || (clk_en && active_current);
        always_ff @(posedge clk) begin
            if (event_buffers_trigger) begin
                event_buffers_current <= event_buffers_next;
            end
        end

        assign first_center = event_buffers_current[3];
        assign first_edge = event_buffers_current[2];
        assign second_center = event_buffers_current[1];
        assign second_edge = event_buffers_current[0];
    //                                                                       //
//?

endmodule : io_clock_divider
