/**
 *  Module: double_dabble_layer
 *
 *  About: 
 *
 *  Ports:
 *
**/
module double_dabble_layer #(
    parameter integer Input_Bit_Width = 8,
    parameter     bit Buffered = 1'b1,
    parameter integer Starting_Index = 1,
    parameter integer Cell_Count = 1,
    parameter integer Layer_Bit_Width = 8
)(
    input                        clk,
    input                        clk_en,
    input                        sync_rst,

    input  [Layer_Bit_Width-1:0] layer_input,
    input                        valid_input,

    output [Layer_Bit_Width-1:0] layer_output,
    output                       valid_output
);

//? Layer Generation
    //                                                                       //
    //* Common Connections and Parameters
        localparam integer Upper_Bit_Index = Starting_Index + 3 + ((Cell_Count - 1) * 4);
        localparam integer Lower_Bit_Index = Starting_Index;

        wire [Layer_Bit_Width-1:0] layer;
    //                                                                       //
    //* Passthrough Bits
        // Upper Bits
        assign layer[Layer_Bit_Width-1:Upper_Bit_Index+1] = layer_input[Layer_Bit_Width-1:Upper_Bit_Index+1];
        // Lower Bits
        assign layer[Lower_Bit_Index-1:0] = layer_input[Lower_Bit_Index-1:0];
    //                                                                       //
    //* Cell Generation
        genvar cell_index;
        generate
            for (cell_index = 0; cell_index < Cell_Count; cell_index = cell_index + 1) begin : Cell_Generation
            //                                                               //
                // Parameters
                localparam Cell_Upper_Index = Lower_Bit_Index + 3 + (cell_index * 4);
                localparam Cell_Lower_Index = Lower_Bit_Index + (cell_index * 4);
                // Bypass Exception
                if (Cell_Lower_Index > Input_Bit_Width) begin : Cell_Bypass
                    assign layer[Cell_Upper_Index:Cell_Lower_Index] = layer_input[Cell_Upper_Index:Cell_Lower_Index];
                end
                // Cell Instantiation
                else begin : Cell_Generation
                    double_dabble_cell dd_cell (
                        .data_in (layer_input[Cell_Upper_Index:Cell_Lower_Index]),
                        .data_out(layer[Cell_Upper_Index:Cell_Lower_Index])
                    );
                end
            //                                                               //
            end
        endgenerate
    //                                                                       //
//?

//? Output Control
    //                                                                       //
    //* Conditional Buffer Generation
        generate
            //                                                               //
            //* Buffered Layer
            if (Buffered == 1'b1) begin : Buffer_Generation
                // Parameter Generation
                localparam Buffer_Bit_Width = Layer_Bit_Width + 1;
                // Layer Buffer
                reg  [Layer_Bit_Width:0] layer_buffer_current;
                wire [Layer_Bit_Width:0] layer_buffer_next = sync_rst
                                                           ? Buffer_Bit_Width'(0)
                                                           : {valid_input, layer};
                wire        layer_buffer_trigger = sync_rst || clk_en;
                always_ff @(posedge clk) begin
                    if (layer_buffer_trigger) begin
                        layer_buffer_current <= layer_buffer_next;
                    end
                end
                // Output Assignments
                assign layer_output = layer_buffer_current[Layer_Bit_Width-1:0];
                assign valid_output = layer_buffer_current[Layer_Bit_Width];
            end
            //                                                               //
            //* Non-Buffered Layer Output Assignments
            else begin : Buffer_Bypass
                assign layer_output = layer;
                assign valid_output = valid_input;
            //                                                               //
            end
        endgenerate
    //                                                                       //
//?

endmodule : double_dabble_layer
