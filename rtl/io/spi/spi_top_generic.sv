/**
 *  Module: spi_top_generic
 *
 *  About: 
 *
 *  Ports:
 *
**/
module spi_top_generic #(
    parameter integer Max_Bit_Width = 32,
    parameter integer Peripheral_Count = 1, //TODO:
    //? Do Not Instantiate:
    parameter integer Bit_Index_Width = $clog2(Max_Bit_Width) + 1
)(
    input                         clk, // 50Mhz
    input                         clk_en,
    input                         sync_rst,
    input                         default_sclk_polarity,

//? Transfer Start
    input                         transfer_start_req,
    output                        transfer_start_ack,

     //! Transfer too large - can ignore if using a constant width
    output                        transfer_start_nak,

    // 20 for 2.5Mhz `sclk`
    input                  [15:0] transfer_clock_divisor,
    input                         transfer_cpol,
    input                         transfer_cpha,

    // start clock high or low when cs goes active. (can be used to select endianness of transfer with some peripherals)
    input                         transfer_sclk_start_polarity,
    input   [Bit_Index_Width-1:0] transfer_width,

    // COPI Data shifts right on transfer (LSB First)
    input     [Max_Bit_Width-1:0] transfer_copi_data,
    // Writes when 1, Reads when 0
    input     [Max_Bit_Width-1:0] transfer_copi_mask, // Set bits to 1 to transfer respective copi_data bits
    input     [Max_Bit_Width-1:0] transfer_cipo_mask, // Set bits to 1 to read respective cipo bits in
//?

//? Read Response
    output                        transfer_end_req,
    input                         transfer_end_ack,
    output    [Max_Bit_Width-1:0] transfer_cipo_data,
//?

//? SPI Interface
    input                         chip_select_override,

    output                        sclk,
    output [Peripheral_Count-1:0] cs_n,
    output                        copi,
    output                        copi_en, // Raise when wanting to Transmit data - Not required
    input                         cipo
);


//? Clocking & Configuration
    //                                                                       //
    //* Common Connections
        wire transfer_start_hs_good = transfer_start_req && transfer_start_ack;

        wire initialize_out_going_trigger;
        wire initialize_out_going_normal;
        wire initialize_out_going_preamble;

        wire cpol;
        wire starting_polarity;
        wire update_on_first_edge;

        wire transfer_complete;

        wire divided_clk;
        
        wire first_edge;
        wire second_edge;
    //                                                                       //
    //* Configuration - Updated upon every successful transfer_start handshake
        spi_configuration configuration (
            .clk                          (clk),
            .clk_en                       (clk_en),
            .sync_rst                     (sync_rst),
            .configure                    (transfer_start_hs_good),
            .cpol_in                      (transfer_cpol),
            .cpha_in                      (transfer_cpha),
            .sclk_start_polarity_in       (transfer_sclk_start_polarity),
            .initialize_out_going_trigger (initialize_out_going_trigger),
            .initialize_out_going_normal  (initialize_out_going_normal),
            .initialize_out_going_preamble(initialize_out_going_preamble),
            .cpol                         (cpol),
            .sclk_start_polarity          (starting_polarity),
            .preamble_required            (preamble_required), //TODO: Possibly Not needed
            .update_on_first_edge         (update_on_first_edge)
        );
    //                                                                       //
    //* Clock Divider
        io_clock_divider clock_divider (
            .clk                  (clk),
            .clk_en               (clk_en),
            .sync_rst             (sync_rst),
            .clock_divisor        (transfer_clock_divisor),
            .default_sclk_polarity(default_sclk_polarity),
            .starting_polarity    (~transfer_sclk_start_polarity),
            .clock_start          (transfer_start_hs_good),
            .ending_polarity      (cpol),
            .clock_stop           (transfer_complete),
            .clock_state          (divided_clk),
            .first_center         (), // Not Used
            .first_edge           (first_edge),
            .second_center        (), // Not Used
            .second_edge          (second_edge)
        );
    //                                                                       //
//?

//? State Control
    //                                                                       //
    //* Common Connections
        wire idle;

        wire transfer_end_hs_good = transfer_end_req && transfer_end_ack;
    //                                                                       //
    //* Edge Resolution
        /*
        * Notes
            ! Mode CPOL:CPHA
                00: Latches on Rising Edge
                01: Latches on Falling Edge
                10: Latches on Falling Edge
                11: Latches on Rising Edge
            ? Starting Polarity 0:
                Mode 0:0 - CS: --________________--- //* Update on Falling (first_edge) - skip first update edge
                         SCLK: ___-_-_-_-_-_-_-_-___ //* Override Clock Output & Start clock with Inverse Polarity, Enable Clock Output, Drop CS
                         Data: -x0011223344556677---

                Mode 0:1 - CS: --_________________-- //! Update on Rising (second_edge) - Preamble Required (skip first & second update edge)
                         SCLK: ___-_-_-_-_-_-_-_-___ //* Override Clock Output & Start clock with Inverse Polarity, Enable Clock Output, Drop CS
                         Data: --x0011223344556677--

                Mode 1:0 - CS: --_________________-- //! Update on Rising (second_edge) - Preamble Required (skip first & second update edge)
                         SCLK: -__-_-_-_-_-_-_-_-_-- //* Override Clock Output & Start clock with Inverse Polarity, Enable Clock Output, Drop CS
                         Data: --x0011223344556677-- 

                Mode 1:1 - CS: ---________________-- //* Update on Falling (first_edge) - skip first update edge
                         SCLK: --__-_-_-_-_-_-_-_--- //* Override Clock Output & Start clock with Inverse Polarity, Enable Clock Output, Drop CS
                         Data: --x0011223344556677--
            ? Starting Polarity 1:
                Mode 0:0 - CS: --_________________-- //! Update on Falling (second_edge) - Preamble Required (skip first & second update edge)
                         SCLK: _--_-_-_-_-_-_-_-_-__ //* Override Clock Output & Start clock with Inverse Polarity, Enable Clock Output, Drop CS 
                         Data: --x0011223344556677--

                Mode 0:1 - CS: --________________--- //* Update on Rising (first_edge) - skip first update edge
                         SCLK: _--_-_-_-_-_-_-_-____ //* Override Clock Output & Start clock with Inverse Polarity, Enable Clock Output, Drop CS
                         Data: -x0011223344556677---

                Mode 1:0 - CS: --________________--- //* Update on Rising (first_edge) - skip first update edge
                         SCLK: ---_-_-_-_-_-_-_-_--- //* Override Clock Output & Start clock with Inverse Polarity, Enable Clock Output, Drop CS
                         Data: -x0011223344556677---

                Mode 1:1 - CS: --_________________-- //! Update on Falling (second_edge) - Preamble Required (skip first & second update edge)
                         SCLK: ---_-_-_-_-_-_-_-_--- //* Override Clock Output & Start clock with Inverse Polarity, Enable Clock Output, Drop CS
                         Data: --x0011223344556677--

            ! > Can pad the Tx data with 1 additional bit, then conditionally add 1 to the starting index, this will "ignore" the first update
        */
    //                                                                       //
    //* State
        reg   [2:0] state_current;
        logic [3:0] state_vector;
        always_comb begin : state_update_mux
            case (state_current)
                //*                      Trigger                - Next State
                3'b000  : state_vector = {transfer_start_hs_good, 3'b001}; // Idle (set polarity on trigger)
                3'b001  : state_vector = {first_edge,            3'b010}; // Setup
                3'b010  : state_vector = {transfer_complete,      3'b100}; // Transfer
                3'b100  : state_vector = {transfer_end_hs_good,   3'b000}; // Read Acknowledgement
                default : state_vector = 4'b1_000; //! Error
            endcase
        end
        wire [2:0] state_next = sync_rst ? 3'd0 : state_vector[2:0];
        wire       state_trigger = sync_rst || (clk_en && state_vector[3]);
        always_ff @(posedge clk) begin
            if (state_trigger) begin
                state_current <= state_next;
            end
        end
        assign idle = state_current == 3'b000;
    //                                                                       //
    //* Start Handshake Control
        assign transfer_start_ack = idle && (Max_Bit_Width >= transfer_width);
        assign transfer_start_nak = idle && (Max_Bit_Width < transfer_width);
    //                                                                       //
    //* End Handshake Control
        assign transfer_end_req = state_current[2];
    //                                                                       //
    //* Transfer Remaining
        reg    [Bit_Index_Width-1:0] transfer_remaining_current;
        logic  [Bit_Index_Width-1:0] transfer_remaining_next;
        wire                   [1:0] transfer_remaining_next_condition;
        assign                       transfer_remaining_next_condition[0] = transfer_start_hs_good;
        // assign                       transfer_remaining_next_condition[1] = (transfer_start_hs_good && preamble_required) ||  sync_rst;
        assign                       transfer_remaining_next_condition[1] = sync_rst;
        always_comb begin : transfer_remaining_next_mux
            case (transfer_remaining_next_condition)
                2'b00  : transfer_remaining_next = transfer_remaining_current - Bit_Index_Width'(1); // Normal Operation
                2'b01  : transfer_remaining_next = transfer_width; // Initialize Normal
                2'b10  : transfer_remaining_next = Bit_Index_Width'(0); // Reset
                // 2'b11  : transfer_remaining_next = transfer_width + Bit_Index_Width'(1); // Initialize Preamble Exception
                2'b11  : transfer_remaining_next = Bit_Index_Width'(0); // Reset
                default: transfer_remaining_next = Bit_Index_Width'(0);
            endcase
        end
        wire transfer_remaining_trigger = sync_rst
                                   || (clk_en && transfer_start_hs_good) // Init
                                   || (clk_en && update_on_first_edge && first_edge) // First Edge Update
                                   || (clk_en && ~update_on_first_edge && second_edge); // Second Edge Update
        always_ff @(posedge clk) begin
            if (transfer_remaining_trigger) begin
                transfer_remaining_current <= transfer_remaining_next;
            end
        end
        assign transfer_complete = update_on_first_edge
                                 ? ((transfer_remaining_current == Bit_Index_Width'(0)) && first_edge)
                                 : ((transfer_remaining_current == Bit_Index_Width'(0)) && second_edge);
    //                                                                       //
//?

//? SPI Out-Going Control
    //                                                                       //
    //* Common Connections
        localparam integer Transfer_Bit_Width = Max_Bit_Width + 1;

        wire   [1:0] out_going_condition;
        assign       out_going_condition[0] = initialize_out_going_normal || sync_rst || transfer_complete;
        assign       out_going_condition[1] = initialize_out_going_preamble || sync_rst || transfer_complete;

        wire         out_going_trigger = sync_rst
                                      || (clk_en && initialize_out_going_trigger) // Init
                                      || (clk_en && update_on_first_edge && first_edge && state_current[1]) // First Edge Update
                                      || (clk_en && ~update_on_first_edge && second_edge && state_current[1]); // Second Edge Update
    //                                                                       //
    //* Out-Going Data
        reg    [Transfer_Bit_Width-1:0] out_going_data_current;
        logic  [Transfer_Bit_Width-1:0] out_going_data_next;
        always_comb begin : out_going_data_next_mux
            case (out_going_condition)
                2'b00  : out_going_data_next = {out_going_data_current[Transfer_Bit_Width-2:0], 1'b0}; // Normal Operation
                2'b01  : out_going_data_next = {transfer_copi_data, 1'b0};                             // Initialization - Normal
                2'b10  : out_going_data_next = {1'b0, transfer_copi_data};                             // Initialization - Preamble
                2'b11  : out_going_data_next = Transfer_Bit_Width'(0);                                 // Reset
                default: out_going_data_next = Transfer_Bit_Width'(0);                                 //! Error
            endcase
        end
        always_ff @(posedge clk) begin
            if (out_going_trigger) begin
                out_going_data_current <= out_going_data_next;
            end
        end
    //                                                                       //
    //* Out-Going Mask
        reg    [Transfer_Bit_Width-1:0] out_going_mask_current;
        logic  [Transfer_Bit_Width-1:0] out_going_mask_next;
        always_comb begin : out_going_mask_next_mux
            case (out_going_condition)
                2'b00  : out_going_mask_next = {out_going_mask_current[Transfer_Bit_Width-2:0], 1'b0}; // Normal Operation
                2'b01  : out_going_mask_next = {transfer_copi_mask, 1'b0};                             // Initialization - Normal
                2'b10  : out_going_mask_next = {1'b0, transfer_copi_mask};                             // Initialization - Preamble
                2'b11  : out_going_mask_next = Transfer_Bit_Width'(0);                                 // Reset
                default: out_going_mask_next = Transfer_Bit_Width'(0);                                 //! Error
            endcase
        end
        always_ff @(posedge clk) begin
            if (out_going_trigger) begin
                out_going_mask_current <= out_going_mask_next;
            end
        end
    //                                                                       //
    //* Output Buffer
        reg    [3:0] copi_output_current;
        wire         sclk_check = (state_current[0] || transfer_start_req)
                                ? starting_polarity
                                : divided_clk;
        logic  [3:0] copi_output_next;
        wire   [1:0] copi_output_next_condition;
        assign       copi_output_next_condition[0] = transfer_complete || sync_rst;
        assign       copi_output_next_condition[1] = sync_rst;
        always_comb begin : copi_output_next_mux
            case (copi_output_next_condition)
                2'b00  : copi_output_next = {sclk_check, out_going_data_current[Transfer_Bit_Width-1], out_going_mask_current[Transfer_Bit_Width-1], state_current[1]};
                2'b01  : copi_output_next = {cpol, 3'b0_0_0};
                2'b10  : copi_output_next = {default_sclk_polarity, 3'b0_0_0};
                2'b11  : copi_output_next = {default_sclk_polarity, 3'b0_0_0};
                default: copi_output_next = 0;
            endcase
        end
        wire        copi_output_trigger = sync_rst
                                       || (clk_en && state_current[1])
                                       || (clk_en && state_current[0]);
        always_ff @(posedge clk) begin
            if (copi_output_trigger) begin
                copi_output_current <= copi_output_next;
            end
        end
    //                                                                       //
    //* SCLK Delay
        reg  sclk_delay_current;
        wire sclk_delay_next = copi_output_current[3];
        always_ff @(posedge clk) begin
            sclk_delay_current <= sclk_delay_next;
        end
    //                                                                       //
    //* Output Assignments
        reg  [3:0] output_buffer_current;
        wire       cs_n_override_check = ~copi_output_current[0] || chip_select_override;
        wire [3:0] output_buffer_next = {sclk_delay_current, copi_output_current[2], copi_output_current[1], cs_n_override_check};
        always_ff @(posedge clk) begin
            output_buffer_current <= output_buffer_next;
        end

        assign sclk = output_buffer_current[3];
        assign copi = output_buffer_current[2];
        assign copi_en = output_buffer_current[1];
        assign cs_n = output_buffer_current[0];
    //                                                                       //
//?

//? SPI In-Coming Control
    //                                                                       //
    //* In-Coming Mask
        reg    [Transfer_Bit_Width-1:0] in_coming_mask_current;
        logic  [Transfer_Bit_Width-1:0] in_coming_mask_next;
        always_comb begin : in_coming_mask_next_mux
            case (out_going_condition)
                2'b00  : in_coming_mask_next = {in_coming_mask_current[Transfer_Bit_Width-2:0], 1'b0}; // Normal Operation
                2'b01  : in_coming_mask_next = {transfer_cipo_mask, 1'b0};                             // Initialization - Normal
                2'b10  : in_coming_mask_next = {1'b0, transfer_cipo_mask};                             // Initialization - Preamble
                2'b11  : in_coming_mask_next = Transfer_Bit_Width'(0);                                 // Reset
                default: in_coming_mask_next = Transfer_Bit_Width'(0);                                 //! Error
            endcase
        end
        always_ff @(posedge clk) begin
            if (out_going_trigger) begin
                in_coming_mask_current <= in_coming_mask_next;
            end
        end
    //                                                                       //
    //* Latch Synchronization
        // Delayed to account for output buffer delay on sclk and the In-Coming Blind Buffer delay
        reg    [3:0] cipo_sclk_sync_current;
        logic  [3:0] cipo_sclk_sync_next;
        wire   [1:0] cipo_sclk_sync_next_condition;
        assign       cipo_sclk_sync_next_condition[0] = update_on_first_edge;
        assign       cipo_sclk_sync_next_condition[1] = sync_rst;
        always_comb begin : cipo_sclk_sync_next_mux
            case (cipo_sclk_sync_next_condition)
                2'b00  : cipo_sclk_sync_next = {cipo_sclk_sync_current[2:0], (first_edge && in_coming_mask_current[Transfer_Bit_Width-1] && state_current[1])}; // Update on Second - Latch on First
                2'b01  : cipo_sclk_sync_next = {cipo_sclk_sync_current[2:0], (second_edge && in_coming_mask_current[Transfer_Bit_Width-1] && state_current[1])}; // Update on First - Latch on Second
                2'b10  : cipo_sclk_sync_next = 4'd0;
                2'b11  : cipo_sclk_sync_next = 4'd0;
                default: cipo_sclk_sync_next = 4'd0;
            endcase
        end
        wire cipo_sclk_sync_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (cipo_sclk_sync_trigger) begin
                cipo_sclk_sync_current <= cipo_sclk_sync_next;
            end
        end
    //                                                                       //
    //* In-Coming Blind Buffer
        reg  [1:0] cipo_current;
        wire [1:0] cipo_next = {cipo_current[0], cipo};
        always_ff @(posedge clk) begin
            cipo_current <= cipo_next;
        end
    //                                                                       //
    
    //* In-Coming Data
        reg  [Max_Bit_Width-1:0] in_coming_data_current;
        wire [Max_Bit_Width-1:0] in_coming_data_next = (sync_rst || transfer_start_hs_good)
                                                ? Max_Bit_Width'(0)
                                                : {in_coming_data_current[Max_Bit_Width-2:0], cipo_current[1]};
        wire                     in_coming_data_trigger = sync_rst
                                                  || (clk_en && transfer_start_hs_good)
                                                  || (clk_en && cipo_sclk_sync_current[3]);
        always_ff @(posedge clk) begin
            if (in_coming_data_trigger) begin
                in_coming_data_current <= in_coming_data_next;
            end
        end
        assign transfer_cipo_data = in_coming_data_current;
    //                                                                       //
//?

endmodule : spi_top_generic

