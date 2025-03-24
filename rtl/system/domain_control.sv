/**
 *  Module: domain_control
 *
 *  About: Generates a four(4) cycle sync_rst pulse after clk_clock is raised.
 *         Then raises clk_en after a two(2) cycle rest.
 *         Finally, a single cycle init signal is generated two(2) cycles
 *         after clk_en rises.
 *
 *  Wave Form:
 * *              Cycle - 0123456789ABCDEF...0123
 * > buffered_clk_lock:   _/------------------\__
 * >          en_check:   ________/------------\_
 * >          clk_en:     _________/-----------\_
 * >          rst_check:  __/--\_________________
 * >          sync_rst:   ___/--\________________
 * >          init_check: _____________-_________
 *
**/
module domain_control (
    input  clk,
    input  async_rst,

    input  domain_enable,

    output clk_en,
    output sync_rst,
    output init
);

//? Domain Active
    //                                                                       //
    //* Active Vector
        reg  [11:0] domain_active_vector_current;
        wire [11:0] domain_active_vector_next = {domain_active_vector_current[10:0], domain_enable};
        always_ff @(posedge clk or posedge async_rst) begin
            if (async_rst) begin
                domain_active_vector_current <= 12'd0;
            end
            else begin
                domain_active_vector_current <= domain_active_vector_next;
            end
        end
    //                                                                       //
//?

//? Output Buffers
    //                                                                       //
    //* clk_en
        reg  clk_en_buffer_current;
        wire clk_en_buffer_next = domain_active_vector_current[8] && domain_active_vector_current[2];
        always_ff @(posedge clk or posedge async_rst) begin
            if (async_rst) begin
                clk_en_buffer_current <= 1'd0;
            end
            else begin
                clk_en_buffer_current <= clk_en_buffer_next;
            end
        end
        assign clk_en = clk_en_buffer_current;
    //                                                                       //
    //* sync_rst
        reg  sync_rst_buffer_current;
        wire sync_rst_buffer_next = ~domain_active_vector_current[6] && domain_active_vector_current[2];
        always_ff @(posedge clk or posedge async_rst) begin
            if (async_rst) begin
                sync_rst_buffer_current <= 1'b1;
            end
            else begin
                sync_rst_buffer_current <= sync_rst_buffer_next;
            end
        end
        assign sync_rst = sync_rst_buffer_current;
    //                                                                       //
    //* init
        reg  init_buffer_current;
        wire init_buffer_next = ~domain_active_vector_current[11] && domain_active_vector_current[10] && domain_active_vector_current[2];
        always_ff @(posedge clk or posedge async_rst) begin
            if (async_rst) begin
                init_buffer_current <= 1'd0;
            end
            else begin
                init_buffer_current <= init_buffer_next;
            end
        end
        assign init = init_buffer_current;
    //                                                                       //
//?

endmodule : domain_control
