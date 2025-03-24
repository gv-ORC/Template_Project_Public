/**
 *  Module: seven_segment_bcd_converter
 *
 *  About: 
 *
 *  Ports:
 *
**/
module seven_segment_bcd_converter (
    input  [3:0] bcd,
    input        bcd_valid,
    output [6:0] seven_segment
);

//? Conversion
    //                                                                       //
    //* ROM
        logic [6:0] decoded_seven_seg;
        always_comb begin : decoded_seven_seg_mux
            case (bcd)
                //                              g f e d c b a
                //                              6 5 4 3 2 1 0
                4'h0   : decoded_seven_seg = 7'b0_1_1_1_1_1_1; // 0
                4'h1   : decoded_seven_seg = 7'b0_0_0_0_1_1_0; // 1
                4'h2   : decoded_seven_seg = 7'b1_0_1_1_0_1_1; // 2 
                4'h3   : decoded_seven_seg = 7'b1_0_0_1_1_1_1; // 3
                4'h4   : decoded_seven_seg = 7'b1_1_0_0_1_1_0; // 4
                4'h5   : decoded_seven_seg = 7'b1_1_0_1_1_0_1; // 5
                4'h6   : decoded_seven_seg = 7'b1_1_1_1_1_0_1; // 6
                4'h7   : decoded_seven_seg = 7'b0_0_0_0_1_1_1; // 7
                4'h8   : decoded_seven_seg = 7'b1_1_1_1_1_1_1; // 8
                4'h9   : decoded_seven_seg = 7'b1_1_0_1_1_1_1; // 9
                default: decoded_seven_seg = 7'b0_0_0_0_0_0_0; // Default to everything off
            endcase
        end
    //                                                                       //
    //* Assignments
        assign seven_segment = bcd_valid
                             ? decoded_seven_seg
                             : 7'd0;
    //                                                                       //
//?

endmodule : seven_segment_bcd_converter
