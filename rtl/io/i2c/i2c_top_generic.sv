/*
    > SCL Stays high when not used

    Start/Repeat Start
    > Lower SDA, while SCL stays high... Change data high after the ACK bit in order to trigger a Start during the next SCL High event

    Stop
    > Raise SDA, while SCL stays high... Change data low after the ACK bit in order to trigger a Stop during the next SCL High event - Then hold SCL high until next transfer

    ACK/NAK
    > Every 9th bit of transfer, allow peripheral to control SDA. If driven LOW, ACK and continue. If pulled/driven HIGH, NAK and retry transfer.
    > ACK/NAK is our control during a read. ACK to trigger another sequential read. NAK to end read streak

    > Data can only change when SCL is low, data must be stable during rising, high, and falling clock states

    7b Addressing
    > First Byte is a 7b address followed by a single bit for Read(1)/Write(0)

    10b Addressing
    > First Byte is 11110xxY, where xx is the 2 MSBs of the address, and Y is the Read(1)/Write(0) control bit.
    > Second Byte is the lowest 8b of the address..

    Register Read
    > Transfer a Write with the Peripheral and Register Addresses. Followed by a Read with just the Peripheral Address


*/

/**
 *  Module: i2c_top_generic
 *
 *  About: 
 *
 *  Ports:
 *
**/
module i2c_top_generic (
    input         clk,
    input         clk_en,
    input         sync_rst,

    input  [15:0] clock_divisor, // Target 100Khz or 400Khz
    input         divisor_write_en,

    input         ten_bit_addressing_enabled,
    input   [9:0] peripheral_address,

    input         transaction_req,
    output        transaction_ack,
    input   [7:0] transaction_length,
    input         transaction_rw, // 0: Read, 1: Write
    input   [9:0] transaction_peripheral_address,
    input   [7:0] transaction_register_address,
    input   [7:0] transaction_write_data,

    output        read_req,
    input         read_ack,
    output        read_last,
    output  [7:0] read_data,

    output        i2c_scl,
    input         i2c_input_data,
    output        i2c_output_data,
    output        i2c_output_enable
);


//? Clock Divider and Event Triggers
    //                                                                       //
    //* Common Connections
        wire clock_state;
        wire high_center;
        wire falling_edge;
        wire low_center;
        wire rising_edge;
    //                                                                       //
    //* Divider
        i2c_clock_divider clock_divider(
            .clk             (clk),
            .clk_en          (clk_en),
            .sync_rst        (sync_rst),
            .clock_divisor   (clock_divisor),
            .divisor_write_en(divisor_write_en),
            .clock_state     (clock_state),
            .high_center     (high_center),
            .falling_edge    (falling_edge),
            .low_center      (low_center),
            .rising_edge     (rising_edge)
        );
    //                                                                       //
//?

//? Transaction Control
    //                                                                       //
    //* Common Connections
    //                                                                       //
    //* Read/Write Status
    //                                                                       //
    //* Handshake Control
    //                                                                       //
//?

//? State Control
    //                                                                       //
    //* Common Connections
    //                                                                       //
    //* I2C Bus States
    //                                                                       //
//?

//? Tx Buffers
    //                                                                       //
    //* Common Connections
    //                                                                       //
    //* Peripheral Address
    //                                                                       //
    //* Register Address
    //                                                                       //
    //* Data
    //                                                                       //
//?

//? Rx Control
    //                                                                       //
    //* Common Connections
    //                                                                       //
    //* Data Buffer
    //                                                                       //
    //* Handshake Control
    //                                                                       //
//?

//? Interface Controller
    //                                                                       //
    //* SCL Buffer
    //                                                                       //
    //* Output Assignments
    //                                                                       //
//?

endmodule : i2c_top_generic
