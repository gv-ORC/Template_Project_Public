/**
 *  Module: crash_course_cpu_dataloop
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_dataloop (
    input clk,
    input clk_en,
    input sync_rst,

    input        system_enabled,
    
    input  [3:0] reg_a_addr,
    input        reg_a_write_enable,

    input  [3:0] reg_b_addr,

    input  [3:0] reg_c_addr,

    input  [7:0] immediate,
    input  [3:0] opcode,

    output [7:0] memory_address,
    input  [7:0] load_data,
    output [7:0] store_data,

    output [1:0] flag_register
);


wire [7:0] reg_a_write_data;
wire [7:0] reg_b_read_data;
wire [7:0] reg_c_read_data;

crash_course_cpu_registers register_file (
    .clk               (clk),
    .clk_en            (clk_en),
    .sync_rst          (sync_rst),
    .system_enabled    (system_enabled),
    .reg_a_addr        (reg_a_addr),
    .reg_a_write_enable(reg_a_write_enable),
    .reg_a_write_data  (reg_a_write_data),
    .reg_b_addr        (reg_b_addr),
    .reg_b_read_data   (reg_b_read_data),
    .reg_c_addr        (reg_c_addr),
    .reg_c_read_data   (reg_c_read_data)
);
assign store_data = reg_c_read_data;
assign memory_address = reg_b_read_data;

crash_course_cpu_alu alu (
    .clk              (clk),
    .clk_en           (clk_en),
    .sync_rst         (sync_rst),
    .system_enabled   (system_enabled),
    .immediate        (immediate),
    .load_data        (load_data),
    .input_b          (reg_b_read_data),
    .input_c          (reg_c_read_data),
    .opcode           (opcode),
    .output_a         (reg_a_write_data),
    .flag_register    (flag_register)
);


endmodule : crash_course_cpu_dataloop
