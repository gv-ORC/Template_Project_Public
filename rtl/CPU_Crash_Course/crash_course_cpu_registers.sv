/**
 *  Module: crash_course_cpu_registers
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_registers (
    input clk,
    input clk_en,
    input sync_rst,

    input        system_enabled,

    input  [3:0] reg_a_addr,
    input        reg_a_write_enable,
    input  [7:0] reg_a_write_data, // Uses reg_b_read_data

    input  [3:0] reg_b_addr,
    output [7:0] reg_b_read_data,

    input  [3:0] reg_c_addr,
    output [7:0] reg_c_read_data
);


    logic [15:0] write_decoder;
    always_comb begin
        write_decoder = 0;
        write_decoder[reg_a_addr] = 1'b1;
    end

    wire [7:0] read_vector[15:0];
    genvar reg_index;
    generate
        for (reg_index = 0; reg_index < 16; reg_index = reg_index + 1) begin : register_generation
            if (reg_index == 0) begin : zero_register_exception
                assign read_vector[reg_index] = 8'd0;
            end
            else begin : general_purpose_registers
                reg  [7:0] register_current;
                wire [7:0] register_next = sync_rst ? 8'd0 : reg_a_write_data;
                wire        register_trigger = sync_rst || (clk_en && write_decoder[reg_index] && reg_a_write_enable && system_enabled);
                always_ff @(posedge clk) begin
                    if (register_trigger) begin
                        register_current <= register_next;
                    end
                end
                assign read_vector[reg_index] = register_current;
            end
        end
    endgenerate

    assign reg_b_read_data = read_vector[reg_b_addr];

    assign reg_c_read_data = read_vector[reg_c_addr];

endmodule : crash_course_cpu_registers
