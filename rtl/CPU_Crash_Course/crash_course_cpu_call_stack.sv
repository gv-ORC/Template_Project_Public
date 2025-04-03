/**
 *  Module: crash_course_cpu_call_stack
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_call_stack (
    input clk,
    input clk_en,
    input sync_rst,

    input  [7:0] program_counter_current,
    input        jump_enable,
    input        call_enable,
    input        return_enable,

    output [7:0] return_address
);

wire   [7:0] call_stack_vector [7:0];
assign       return_address = call_stack_vector[0];

genvar call_stack_index;
generate
    for (call_stack_index = 0; call_stack_index < 8; call_stack_index = call_stack_index + 1) begin : call_stack_generation
        if (call_stack_index == 0) begin : head_of_call_stack
           //                                                            //
               reg    [7:0] call_stack_entry_current;
               logic  [7:0] call_stack_entry_next;
               wire   [1:0] call_stack_entry_next_condition;
               assign       call_stack_entry_next_condition[0] = call_enable || sync_rst;
               assign       call_stack_entry_next_condition[1] = return_enable || sync_rst;
               always_comb begin : call_stack_entry_next_mux
                   case (call_stack_entry_next_condition)
                       2'b00  : call_stack_entry_next = 8'd0; //! Error
                       2'b01  : call_stack_entry_next = program_counter_current + 8'd1; // Call
                       2'b10  : call_stack_entry_next = call_stack_vector[call_stack_index + 1]; // Return
                       2'b11  : call_stack_entry_next = 8'd0; // Reset
                       default: call_stack_entry_next = 0;
                   endcase
               end
               wire       call_stack_entry_trigger = sync_rst
                                                  || (clk_en && call_enable && jump_enable)
                                                  || (clk_en && return_enable && jump_enable);
               always_ff @(posedge clk) begin
                   if (call_stack_entry_trigger) begin
                       call_stack_entry_current <= call_stack_entry_next;
                   end
               end
               assign call_stack_vector[call_stack_index] = call_stack_entry_current;
           //                                                            //
        end
        else if (call_stack_index == 15) begin : end_of_call_stack
           //                                                            //
               reg    [7:0] call_stack_entry_current;
               logic  [7:0] call_stack_entry_next;
               wire   [1:0] call_stack_entry_next_condition;
               assign       call_stack_entry_next_condition[0] = call_enable || sync_rst;
               assign       call_stack_entry_next_condition[1] = return_enable || sync_rst;
               always_comb begin : call_stack_entry_next_mux
                   case (call_stack_entry_next_condition)
                       2'b00  : call_stack_entry_next = 8'd0; //! Error
                       2'b01  : call_stack_entry_next = call_stack_vector[call_stack_index - 1]; // Call
                       2'b10  : call_stack_entry_next = 8'd0; // Return
                       2'b11  : call_stack_entry_next = 8'd0; // Reset
                       default: call_stack_entry_next = 0;
                   endcase
               end
               wire       call_stack_entry_trigger = sync_rst
                                                  || (clk_en && call_enable && jump_enable)
                                                  || (clk_en && return_enable && jump_enable);
               always_ff @(posedge clk) begin
                   if (call_stack_entry_trigger) begin
                       call_stack_entry_current <= call_stack_entry_next;
                   end
               end
               assign call_stack_vector[call_stack_index] = call_stack_entry_current;
           //                                                            //
        end
        else begin : body_of_call_stack
           //                                                            //
               reg    [7:0] call_stack_entry_current;
               logic  [7:0] call_stack_entry_next;
               wire   [1:0] call_stack_entry_next_condition;
               assign       call_stack_entry_next_condition[0] = call_enable || sync_rst;
               assign       call_stack_entry_next_condition[1] = return_enable || sync_rst;
               always_comb begin : call_stack_entry_next_mux
                   case (call_stack_entry_next_condition)
                       2'b00  : call_stack_entry_next = 8'd0; //! Error
                       2'b01  : call_stack_entry_next = call_stack_vector[call_stack_index - 1]; // Call
                       2'b10  : call_stack_entry_next = call_stack_vector[call_stack_index + 1]; // Return
                       2'b11  : call_stack_entry_next = 8'd0; // Reset
                       default: call_stack_entry_next = 0;
                   endcase
               end
               wire       call_stack_entry_trigger = sync_rst
                                                  || (clk_en && call_enable && jump_enable)
                                                  || (clk_en && return_enable && jump_enable);
               always_ff @(posedge clk) begin
                   if (call_stack_entry_trigger) begin
                       call_stack_entry_current <= call_stack_entry_next;
                   end
               end
               assign call_stack_vector[call_stack_index] = call_stack_entry_current;
           //                                                            //
        end
    end
endgenerate

endmodule : crash_course_cpu_call_stack
