/**
 *  Module: double_dabble_cell
 *
 *  About: Performs the basic double dabble cell algorithm.
**/
module double_dabble_cell (
    input  [3:0] data_in,
    output [3:0] data_out
);

//? Cell Logic
    //                                                                       //
    //* Offset Generation
        wire       greater_than_4 = data_in > 4'd4;
        wire [3:0] offset = {2'b00, {2{greater_than_4}}};
    //                                                                       //
    //* Output Assignment
        assign data_out = data_in + offset;
    //                                                                       //
//?

endmodule : double_dabble_cell
