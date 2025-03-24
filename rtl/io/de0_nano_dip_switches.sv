/**
 *  Module: de0_nano_dip_switches
 *
 *  About: 
 *
 *  Ports:
 *
**/
module de0_nano_dip_switches #(
    parameter integer Validation_Wait_Cycles = 500_000, // 10ms @ 50Mhz
    parameter integer Lockout_Cycles = 5_000_000      // 1/10th of a second @ 50Mhz
)(
    input        clk,
    input        clk_en,
    input        sync_rst,

    input  [3:0] dip_switches,

    output [3:0] state_out
);

genvar switch_index;
generate
    for (switch_index = 0; switch_index < 4; switch_index = switch_index + 1) begin : Switch_Generation
        level_debouncer #(
            .Validation_Wait_Cycles(Validation_Wait_Cycles),
            .Lockout_Cycles(Lockout_Cycles)
        ) switch_debouncer (
            .clk            (clk),
            .clk_en         (clk_en),
            .sync_rst       (sync_rst),
            .io_in          (dip_switches[switch_index]),
            .debounced_level(state_out[switch_index])
        );       
    end
endgenerate

endmodule : de0_nano_dip_switches
