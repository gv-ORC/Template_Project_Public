/**
 *  Module: de0_nano_leds_top_generic
 *
 *  About: 
 *
 *  Ports:
 *
**/
module de0_nano_leds_top_generic (
    input clk,
    input clk_en,
    input sync_rst,

    //TODO: make a new clock divider for variable PWM systems, use that for brightness
    // input [31:0] clock_pps,

    input  [7:0] data_in,
    input        update_leds,

    // input  [7:0] brightness,
    // input        update_brightness,

    output [7:0] leds_out
);

//? LED Control
    //                                                                       //
    //* State Buffer
        reg  [7:0] leds_current;
        wire [7:0] leds_next = sync_rst
                             ? 8'd0
                             : data_in;
        wire       leds_trigger = sync_rst
                               || (clk_en && update_leds);
        always_ff @(posedge clk) begin
            if (leds_trigger) begin
                leds_current <= leds_next;
            end
        end
    //                                                                       //
    //* Output Buffer
        reg  [7:0] output_current;
        wire [7:0] output_next = leds_current;
        always_ff @(posedge clk) begin
            output_current <= output_next;
        end
        assign leds_out = output_current;
    //                                                                       //
//?


endmodule : de0_nano_leds_top_generic
