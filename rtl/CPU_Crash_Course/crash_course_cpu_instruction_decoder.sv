/**
 *  Module: crash_course_cpu_instruction_decoder
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_instruction_decoder (
    input  [15:0] instruction,
    
    output        halt_enable,

    output        jump_enable,
    output  [2:0] branch_condition,
    output        branch_enable,
    output        call_enable,
    output        return_enable,

    output        store_enable,

    output  [3:0] reg_a_addr,
    output        reg_a_write_enable,
    output  [3:0] reg_b_addr,
    output  [3:0] reg_c_addr,
    output  [7:0] immediate,
    output  [3:0] opcode
);

    assign branch_condition = instruction[10:8];
    assign call_enable = instruction[9];
    assign return_enable = instruction[8];

    assign opcode = instruction[15:12];
    assign reg_a_addr = instruction[11:8];
    assign reg_b_addr = instruction[7:4];
    assign reg_c_addr = instruction[3:0];
    assign immediate = instruction[7:0];

    logic [4:0] control_vector; //* {halt_enable, jump_enable, branch_enable, store_enable, reg_a_write_enable}
    always_comb begin : alu_output_mux
        case (opcode)
            4'h0   : control_vector = 5'b0_0_0_0_0; // Nop
            4'h1   : control_vector = 5'b0_0_0_0_1; // Add
            4'h2   : control_vector = 5'b0_0_0_0_1; // Sub
            4'h3   : control_vector = 5'b0_0_0_0_1; // AND
            4'h4   : control_vector = 5'b0_0_0_0_1; // OR
            4'h5   : control_vector = 5'b0_0_0_0_1; // XOR
            4'h6   : control_vector = 5'b0_0_0_0_1; // NOT C
            4'h7   : control_vector = 5'b0_0_0_0_1; // Right Shift
            4'h8   : control_vector = 5'b0_0_0_0_1; // Load
            4'h9   : control_vector = 5'b0_0_0_1_0; // Store
            4'hA   : control_vector = 5'b0_0_0_0_1; // Add Imm
            4'hB   : control_vector = 5'b0_0_0_0_1; // Load Imm
            4'hC   : control_vector = 5'b0_0_0_0_0; //! Reserved
            4'hD   : control_vector = 5'b1_0_0_0_0; // Halt
            4'hE   : control_vector = 5'b0_1_0_0_0; // Jump
            4'hF   : control_vector = 5'b0_0_1_0_0; // Branch
            default: control_vector = 0;
        endcase
    end
    assign halt_enable = control_vector[4];
    assign jump_enable = control_vector[3];
    assign branch_enable = control_vector[2];
    assign store_enable = control_vector[1];
    assign reg_a_write_enable = control_vector[0];

endmodule : crash_course_cpu_instruction_decoder
