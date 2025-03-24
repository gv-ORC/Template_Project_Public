/**
 *  Module: double_dabble_top_generic
 *
 *  About: 
 *
**/
module double_dabble_top_generic #(
    parameter integer Input_Bit_Width = 8, //! Minimum of 4
    //? Do Not Instantiate:
    parameter integer Total_Nibbles = (Input_Bit_Width / 3) + 1
)(
    input                           clk,
    input                           clk_en,
    input                           sync_rst,

    input     [Input_Bit_Width-1:0] bin,
    input                           bin_valid,

    output [Total_Nibbles-1:0][3:0] nibbles_out,
    output [Total_Nibbles-1:0]      nibbles_valid
);

//? Layer Control
    //                                                                       //
    //* Common Connections and Parameters
        localparam integer Total_Bit_Width = Total_Nibbles * 4;
        localparam integer Layer_Count = (Input_Bit_Width < 4)
                                   ? 0
                                   : (Input_Bit_Width - 3);

        wire [Layer_Count:0][Total_Bit_Width-1:0] partial_products;
        wire [Layer_Count:0]                      partial_valid;

        assign partial_products[Layer_Count] = Total_Bit_Width'(bin);
        assign partial_valid[Layer_Count] = bin_valid;
    //                                                                       //
    //* Layer Generation
        genvar Layer_Index;
        generate
            for (Layer_Index = Layer_Count; Layer_Index > 0; Layer_Index = Layer_Index - 1) begin : Layer_Generation
            //                                                               //
                // Parameter
                localparam integer Cell_Count = (Input_Bit_Width - Layer_Index) / 3;
                localparam integer Half_Layer_Index = Layer_Index >> 1;
                localparam     bit Buffered = Half_Layer_Index[0]; // Buffer every 4 layers
                // Layer Instantiation
                double_dabble_layer #(
                    .Input_Bit_Width(Input_Bit_Width),
                    .Buffered       (Buffered),
                    .Starting_Index (Layer_Index),
                    .Cell_Count     (Cell_Count),
                    .Layer_Bit_Width(Total_Bit_Width)
                ) layer (
                    .clk         (clk),
                    .clk_en      (clk_en),
                    .sync_rst    (sync_rst),
                    .layer_input (partial_products[Layer_Index]),
                    .valid_input (partial_valid[Layer_Index]),
                    .layer_output(partial_products[Layer_Index-1]),
                    .valid_output(partial_valid[Layer_Index-1])
                );
            //                                                               //
            end
        endgenerate
    //                                                                       //
//?

//? Output Control
    //                                                                       //
    //* Common Connections
        wire [Total_Nibbles-1:0][3:0] final_nibble_vector = partial_products[0];
        wire [Total_Nibbles-1:0]      nibble_zero_vector;
        wire [Total_Nibbles-1:0]      nibble_valid_vector;
    //                                                                       //
    //* Digit Valid Check
    // Note: This removes leading Zeros, allowing the system to keep those digits entirely turned off.
        assign nibble_valid_vector[0] = 1'b1; // Least Significant Digit is always valid
        genvar valid_index;
        generate
            for (valid_index = 1; valid_index < Total_Nibbles; valid_index = valid_index + 1) begin : Valid_Check_Generation
                // If Zero Check
                assign nibble_zero_vector[valid_index] = (final_nibble_vector[valid_index] == 4'd0) && partial_valid[0];
                assign nibble_valid_vector[valid_index] = ~&nibble_zero_vector[Total_Nibbles-1:valid_index];
            end
        endgenerate
    //                                                                       //
    //* Buffers
        reg  [Total_Nibbles-1:0][3:0] output_nibbles_current;
        wire [Total_Nibbles-1:0][3:0] output_nibbles_next = sync_rst
                                                          ? Total_Bit_Width'(0)
                                                          : final_nibble_vector;
        wire                          output_nibbles_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (output_nibbles_trigger) begin
                output_nibbles_current <= output_nibbles_next;
            end
        end

        reg  [Total_Nibbles-1:0] output_valid_current;
        wire [Total_Nibbles-1:0] output_valid_next = sync_rst
                                                   ? Total_Nibbles'(0)
                                                   : nibble_valid_vector;
        wire                     output_valid_trigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (output_valid_trigger) begin
                output_valid_current <= output_valid_next;
            end
        end
    //                                                                       //
    //* Assignments
        assign nibbles_out = output_nibbles_current;
        assign nibbles_valid = output_valid_current;
    //                                                                       //
//?

endmodule : double_dabble_top_generic
