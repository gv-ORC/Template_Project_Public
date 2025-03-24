/**
 *  Module: seven_segment_hex_converter
 *
 *  About: 
 *
 *  Ports:
 *
**/
module seven_segment_animation (
    input  [2:0] frame,
    input        frame_valid,
    output [6:0] seven_segment
);

//? Conversion
    //                                                                       //
    //* Note: Animates a figure-8 pattern using a 3b counter.
    //                                                                       //
    //* ROM
        logic [6:0] decoded_seven_seg;
        always_comb begin : decoded_seven_seg_mux
            case (frame)
                //                              g f e d c b a
                //                              6 5 4 3 2 1 0
                3'h0   : decoded_seven_seg = 7'b1_1_0_0_0_0_0; // 0
                3'h1   : decoded_seven_seg = 7'b1_0_0_0_1_0_0; // 1
                3'h2   : decoded_seven_seg = 7'b0_0_0_1_1_0_0; // 2 
                3'h3   : decoded_seven_seg = 7'b0_0_1_1_0_0_0; // 3
                3'h4   : decoded_seven_seg = 7'b1_0_1_0_0_0_0; // 4
                3'h5   : decoded_seven_seg = 7'b1_0_0_0_0_1_0; // 5
                3'h6   : decoded_seven_seg = 7'b0_0_0_0_0_1_1; // 6
                3'h7   : decoded_seven_seg = 7'b0_1_0_0_0_0_1; // 7
                default: decoded_seven_seg = 7'b0_0_0_0_0_0_0; // Default to everything off
            endcase
        end
    //                                                                       //
    //* Assignments
        assign seven_segment = frame_valid
                             ? decoded_seven_seg
                             : 7'd0;
    //                                                                       //
//?

endmodule : seven_segment_animation















