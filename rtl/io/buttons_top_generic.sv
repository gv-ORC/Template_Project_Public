/**
 *  Module: buttons_top_generic
 *
 *  About: 
 *
 *  Ports:
 *
**/
module buttons_top_generic (
    input        clk,
    input        clk_en,
    input        sync_rst,

    input        button_up_n,     // 7 Seg Increment
    input        button_down_n,   // 7 Seg Decrement
    input        button_right_n,  // Flip LED State
    input        button_select_n, // 7 Seg Clear

    output [3:0] button_pulse_vector
);

//? Debounce Pulse Control
    //                                                                   //
    //* Common Connections and Parameters
        localparam integer Press_Validation_Wait_Cycles = 250_000; // 10ms @ 25Mhz
        localparam integer Release_Lockout_Cycles = 2_500_000; // 1/10th of a second @ 25Mhz
        localparam integer Pulse_Length = 1;
        localparam integer Repeat_Wait_Cycles = 12_500_000; // 1/5th of a second @ 25Mhz
    //                                                                   //
    //* Up
        monostable_debouncer #(
            .Press_Validation_Wait_Cycles(Press_Validation_Wait_Cycles),
            .Release_Lockout_Cycles      (Release_Lockout_Cycles),
            .Pulse_Length                (Pulse_Length),
            .Repeat_Wait_Cycles          (Repeat_Wait_Cycles)
        ) up_debouncer (
            .clk            (clk),
            .clk_en         (clk_en),
            .sync_rst       (sync_rst),
            .repeat_en      (1'b1),
            .io_in          (~button_up_n),
            .debounced_pulse(button_pulse_vector[3])
        );
    //                                                                   //
    //* Down
        monostable_debouncer #(
            .Press_Validation_Wait_Cycles(Press_Validation_Wait_Cycles),
            .Release_Lockout_Cycles      (Release_Lockout_Cycles),
            .Pulse_Length                (Pulse_Length),
            .Repeat_Wait_Cycles          (Repeat_Wait_Cycles)
        ) down_debouncer (
            .clk            (clk),
            .clk_en         (clk_en),
            .sync_rst       (sync_rst),
            .repeat_en      (1'b1),
            .io_in          (~button_down_n),
            .debounced_pulse(button_pulse_vector[2])
        );
    //                                                                   //
    //* Right
        monostable_debouncer #(
            .Press_Validation_Wait_Cycles(Press_Validation_Wait_Cycles),
            .Release_Lockout_Cycles      (Release_Lockout_Cycles),
            .Pulse_Length                (Pulse_Length),
            .Repeat_Wait_Cycles          (Repeat_Wait_Cycles)
        ) right_debouncer (
            .clk            (clk),
            .clk_en         (clk_en),
            .sync_rst       (sync_rst),
            .repeat_en      (1'b0),
            .io_in          (~button_right_n),
            .debounced_pulse(button_pulse_vector[1])
        );
    //                                                                   //
    //* Select
        monostable_debouncer #(
            .Press_Validation_Wait_Cycles(Press_Validation_Wait_Cycles),
            .Release_Lockout_Cycles      (Release_Lockout_Cycles),
            .Pulse_Length                (Pulse_Length),
            .Repeat_Wait_Cycles          (Repeat_Wait_Cycles)
        ) select_debouncer (
            .clk            (clk),
            .clk_en         (clk_en),
            .sync_rst       (sync_rst),
            .repeat_en      (1'b0),
            .io_in          (~button_select_n),
            .debounced_pulse(button_pulse_vector[0])
        );
    //                                                                   //
//?

endmodule : buttons_top_generic
