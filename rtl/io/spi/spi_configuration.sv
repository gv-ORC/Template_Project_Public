/**
 *  Module: spi_configuration
 *
 *  About: 
 *
 *  Ports:
 *
**/
module spi_configuration (
    input  clk,
    input  clk_en,
    input  sync_rst,

    input  configure,

    input  cpol_in,
    input  cpha_in,
    input  sclk_start_polarity_in,

    output initialize_out_going_trigger,
    output initialize_out_going_normal,
    output initialize_out_going_preamble,

    output cpol,
    output sclk_start_polarity,
    output preamble_required,
    output update_on_first_edge
);

//? Configuration Control
    //                                                                       //
    //* Configuration Buffer
        reg  [3:0] configuration_buffer_current;
        wire       preamble_check = cpol_in && cpha_in;
        wire       update_on_first_edge_check = ~sclk_start_polarity_in ^ (cpol_in ^ cpha_in);
        wire [3:0] configuration_buffer_next = sync_rst
                                             ? 4'b0
                                             : {cpol_in, sclk_start_polarity_in, preamble_check, update_on_first_edge_check};
        wire        configuration_buffer_trigger = sync_rst || (clk_en && configure);
        always_ff @(posedge clk) begin
            if (configuration_buffer_trigger) begin
                configuration_buffer_current <= configuration_buffer_next;
            end
        end
    //                                                                       //
    //* Initialization Delay
        reg  [2:0] init_delay_current;
        wire       normal_init_check = configure && update_on_first_edge_check;
        wire       preamble_init_check = configure && ~update_on_first_edge_check;
        wire [2:0] init_delay_next = sync_rst
                                   ? 3'd0
                                   : {configure, normal_init_check, preamble_init_check};
        wire        init_delay_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (init_delay_trigger) begin
                init_delay_current <= init_delay_next;
            end
        end
        assign initialize_out_going_trigger = init_delay_current[2];
        assign initialize_out_going_normal = init_delay_current[1];
        assign initialize_out_going_preamble = init_delay_current[0];
    //                                                                       //
    //* Output Assignments
        assign cpol = configuration_buffer_current[3];
        assign sclk_start_polarity = configuration_buffer_current[2];
        assign preamble_required = configuration_buffer_current[1];
        assign update_on_first_edge = configuration_buffer_current[0];
    //                                                                       //
//?

endmodule : spi_configuration
