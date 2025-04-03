/**
 *  Module: crash_course_cpu_top_generic
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_top_generic (
    input clk,
    input clk_en,
    input sync_rst,

    input        system_start,
    output       system_idle,

    input  [15:0][7:0] io_in,
    output             io_read_en,
    output [15:0][7:0] io_out,
    output             io_write_en
);

reg  system_enabled_current;
wire halt_enable;
wire system_enabled_next = ~sync_rst && system_start && ~halt_enable;
wire system_enabled_trigger = sync_rst
                           || (clk_en && system_start)
                           || (clk_en && halt_enable && system_enabled_current);
always_ff @(posedge clk) begin
    if (system_enabled_trigger) begin
        system_enabled_current <= system_enabled_next;
    end
end
assign system_idle = ~system_enabled_current;


wire  [7:0] program_counter;
wire [15:0] instruction;
crash_course_cpu_program_memory program_memory(
    .program_counter(program_counter),
    .instruction    (instruction)
);


wire       jump_enable;
wire [2:0] branch_condition;
wire       branch_enable;
wire       call_enable;
wire       return_enable;
wire       store_enable;
wire [3:0] opcode;
wire [3:0] reg_a_addr;
wire       reg_a_write_enable;
wire [3:0] reg_b_addr;
wire [3:0] reg_c_addr;
wire [7:0] immediate;
crash_course_cpu_instruction_decoder instruction_decoder(
    .instruction       (instruction),
    .halt_enable       (halt_enable),
    .jump_enable       (jump_enable),
    .branch_condition  (branch_condition),
    .branch_enable     (branch_enable),
    .call_enable       (call_enable),
    .return_enable     (return_enable),
    .store_enable      (store_enable),
    .reg_a_addr        (reg_a_addr),
    .reg_a_write_enable(reg_a_write_enable),
    .reg_b_addr        (reg_b_addr),
    .reg_c_addr        (reg_c_addr),
    .immediate         (immediate),
    .opcode            (opcode)
);


wire [7:0] memory_address;
wire [7:0] store_data;
wire [7:0] load_data;
crash_course_cpu_data_memory ram (
    .clk           (clk),
    .clk_en        (clk_en),
    .sync_rst      (sync_rst),
    .system_enabled(system_enabled_current),
    .memory_address(memory_address),
    .store_enable  (store_enable),
    .store_data    (store_data),
    .load_data     (load_data),
    .io_in         (io_in),
    .io_read_en    (io_read_en),
    .io_out        (io_out),
    .io_write_en   (io_write_en)
);


wire [1:0] flag_register;
crash_course_cpu_dataloop dataloop (
    .clk               (clk),
    .clk_en            (clk_en),
    .sync_rst          (sync_rst),
    .system_enabled    (system_enabled_current),
    .reg_a_addr        (reg_a_addr),
    .reg_a_write_enable(reg_a_write_enable),
    .reg_b_addr        (reg_b_addr),
    .reg_c_addr        (reg_c_addr),
    .immediate         (immediate),
    .opcode            (opcode),
    .memory_address    (memory_address),
    .load_data         (load_data),
    .store_data        (store_data),
    .flag_register     (flag_register)
);


crash_course_cpu_program_counter program_counter_control (
    .clk               (clk),
    .clk_en            (clk_en),
    .sync_rst          (sync_rst),
    .system_start      (system_start),
    .system_enabled    (system_enabled_current),
    .jump_enable       (jump_enable),
    .branch_destination(immediate),
    .branch_condition  (branch_condition),
    .branch_enable     (branch_enable),
    .call_enable       (call_enable),
    .return_enable     (return_enable),
    .flag_register     (flag_register),
    .program_counter   (program_counter)
);

endmodule : crash_course_cpu_top_generic
