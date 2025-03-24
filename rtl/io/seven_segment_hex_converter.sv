/**
 *  Module: seven_segment_hex_converter
 *
 *  About: 
 *
 *  Ports:
 *
**/
module seven_segment_hex_converter (
    input  [3:0] hex,
    input        hex_valid,
    output [6:0] seven_segment
);

//? Conversion
    //                                                                       //
    //* ROM
        logic [6:0] decoded_seven_seg;
        always_comb begin : decoded_seven_seg_mux
            case (hex)
                //                               g f e d c b a
                //                               6 5 4 3 2 1 0
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
                4'hA   : decoded_seven_seg = 7'b1_1_1_0_1_1_1; // A
                4'hB   : decoded_seven_seg = 7'b1_1_1_1_1_0_0; // b
                4'hC   : decoded_seven_seg = 7'b0_1_1_1_0_0_1; // C
                4'hD   : decoded_seven_seg = 7'b1_0_1_1_1_1_0; // d
                4'hE   : decoded_seven_seg = 7'b1_1_1_1_0_0_1; // E
                4'hF   : decoded_seven_seg = 7'b1_1_1_0_0_0_1; // F
                default: decoded_seven_seg = 7'b0_0_0_0_0_0_0; // Default to everything off
            endcase
        end
    //                                                                       //
    //* Assignments
        assign seven_segment = hex_valid
                             ? decoded_seven_seg
                             : 7'd0;
    //                                                                       //
//?

endmodule : seven_segment_hex_converter















