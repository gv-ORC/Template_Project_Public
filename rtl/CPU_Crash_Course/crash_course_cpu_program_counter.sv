/**
 *  Module: crash_course_cpu_program_counter
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_program_counter (
    input clk,
    input clk_en,
    input sync_rst,

    input        system_start,
    input        system_enabled,

    input        jump_enable,

    input  [7:0] branch_destination,
    input  [2:0] branch_condition,
    input        branch_enable,
    input        call_enable,
    input        return_enable,

    input  [1:0] flag_register,

    output [7:0] program_counter
);

    logic       flag_select;
    always_comb begin : condition_met_mux
        case (branch_condition[1:0])
            2'b00  : flag_select = 1'b0; // If Equal
            2'b01  : flag_select = flag_register[0]; // If COut
            2'b10  : flag_select = flag_register[1]; // If Zero
            2'b11  : flag_select = 1'b0; // Unused
            default: flag_select = 1'b0;
        endcase
    end
    wire condition_met = branch_condition[2] ^ flag_select;

    reg    [7:0] program_counter_current;
    logic  [7:0] program_counter_next;
    wire   [7:0] return_address;
    wire   [1:0] program_counter_next_condition;
    assign       program_counter_next_condition[0] = sync_rst
                                                  || (branch_enable && condition_met && ~system_start)
                                                  || (jump_enable && ~return_enable && ~system_start);
    assign       program_counter_next_condition[1] = sync_rst
                                                  || (jump_enable && return_enable && ~system_start);
    always_comb begin : program_counter_next_mux
        case (program_counter_next_condition)
            2'b00  : program_counter_next = program_counter_current + 8'd1; // Normal Operation
            2'b01  : program_counter_next = branch_destination; // Branch/Jump
            2'b10  : program_counter_next = return_address; // Return
            2'b11  : program_counter_next = 8'd0; // Reset
            default: program_counter_next = 8'd0;
        endcase
    end
    wire       program_counter_trigger = sync_rst
                                      || (clk_en && system_start)
                                      || (clk_en && system_enabled);
    always_ff @(posedge clk) begin
        if (program_counter_trigger) begin
            program_counter_current <= program_counter_next;
        end
    end
    assign program_counter = program_counter_current;


//? Call Stack
    crash_course_cpu_call_stack call_stack (
        .clk                    (clk),
        .clk_en                 (clk_en),
        .sync_rst               (sync_rst),
        .program_counter_current(program_counter_current),
        .jump_enable            (jump_enable),
        .call_enable            (call_enable),
        .return_enable          (return_enable),
        .return_address         (return_address)
    );
//?


endmodule : crash_course_cpu_program_counter
