/**
 *  Module: crash_course_cpu_alu
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_alu (
    input clk,
    input clk_en,
    input sync_rst,

    input        system_enabled,

    input  [7:0] immediate,
    input  [7:0] load_data,

    input  [7:0] input_b,
    input  [7:0] input_c,

    input  [3:0] opcode,

    output [7:0] output_a,
    output [1:0] flag_register
);

wire  [8:0] padded_b = {1'b0, input_b};
wire  [8:0] padded_c = {1'b0, input_c};

logic [10:0] alu_output; //* {if_zero_enable, carry_out_enable, carry_out, data_out}
always_comb begin : alu_output_mux
    case (opcode)
        4'h0   : alu_output = {1'b0, 1'b0, 1'b0, 8'd0}; // Nop
        4'h1   : alu_output = {1'b1, 1'b1, (padded_b + padded_c)}; // Add
        4'h2   : alu_output = {1'b1, 1'b1, (padded_b - padded_c)}; // Sub
        4'h3   : alu_output = {1'b1, 1'b0, 1'b0, (input_b & input_c)}; // AND
        4'h4   : alu_output = {1'b1, 1'b0, 1'b0, (input_b | input_c)}; // OR
        4'h5   : alu_output = {1'b1, 1'b0, 1'b0, (input_b ^ input_c)}; // XOR
        4'h6   : alu_output = {1'b1, 1'b0, 1'b0, ~input_c}; // NOT C
        4'h7   : alu_output = {1'b1, 1'b1, input_c[0], (input_c >> 1)}; // Right Shift
        4'h8   : alu_output = {1'b1, 1'b0, 1'b0, load_data}; // Load
        4'h9   : alu_output = {1'b0, 1'b0, 1'b0, 8'd0}; // Store
        4'hA   : alu_output = {1'b0, 1'b0, 1'b0, immediate}; // Load Imm
        4'hB   : alu_output = {1'b0, 1'b0, 1'b0, 8'd0}; //? Reserved
        4'hC   : alu_output = {1'b0, 1'b0, 1'b0, 8'd0}; //? Reserved
        4'hD   : alu_output = {1'b0, 1'b0, 1'b0, 8'd0}; // Halt
        4'hE   : alu_output = {1'b0, 1'b0, 1'b0, 8'd0}; // Jump - //! Managed in the Program Counter
        4'hF   : alu_output = {1'b0, 1'b0, 1'b0, 8'd0}; // Branch - //! Managed in the Program Counter
        default: alu_output = 11'd0;
    endcase
end
assign output_a = alu_output[7:0];

reg  if_carry_out_current;
wire if_carry_out_next = ~sync_rst && alu_output[8];
wire if_carry_out_trigger = sync_rst
                         || (clk_en && alu_output[9] && system_enabled);
always_ff @(posedge clk) begin
    if (if_carry_out_trigger) begin
        if_carry_out_current <= if_carry_out_next;
    end
end
assign flag_register[0] = if_carry_out_current;

reg  if_zero_current;
wire if_zero_next = ~sync_rst && (alu_output[7:0] == 8'd0);
wire if_zero_trigger = sync_rst
                    || (clk_en && clk_en && alu_output[10] && system_enabled);
always_ff @(posedge clk) begin
    if (if_zero_trigger) begin
        if_zero_current <= if_zero_next;
    end
end
assign flag_register[1] = if_zero_current;

endmodule : crash_course_cpu_alu
