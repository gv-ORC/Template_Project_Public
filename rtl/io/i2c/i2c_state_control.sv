/**
 *  Module: i2c_state_control
 *
 *  About: 
 *
 *  Ports:
 *
**/
module i2c_state_control (
    input clk,
    input clk_en,
    input sync_rst,

    
);

//? Metadata Buffers
    //* Length
    //* Read/Write
//?

//? Transaction Depth

//?

//? Transaction State
/*
*Name             - Bin  - Trigger - Next
Idle              - 0000 - 
Peripheral Addr 0 - 0010 - 
Peripheral Addr 1 - 0011 - 
Register Addr     - 0100 - 
Write Data        - 0101 - 
Peripheral Addr 2 - 1010 - 
Peripheral Addr 3 - 1011 - 
Read Data         - 1100 - 

*/

//?

//? Transfer State
/*
*Name - Bin - Trigger - Next
Idle
Start

*/
//?

endmodule : i2c_state_control
