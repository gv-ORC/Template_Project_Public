/**
 *  Module: crash_course_cpu_io
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_io (
    input clk,
    input clk_en,
    input sync_rst,

    input        system_enabled,

    input  [7:0] io_in,
    output [7:0] io_out,

    output [7:0] io_read_data,
    input  [7:0] io_write_data,
    input        io_write_enable
);

    reg  [7:0] io_in_current;
    wire [7:0] io_in_next = sync_rst ? 8'd0 : io_in;
    wire        io_in_trigger = sync_rst || (clk_en && system_enabled);
    always_ff @(posedge clk) begin
        if (io_in_trigger) begin
            io_in_current <= io_in_next;
        end
    end
    assign io_read_data = io_in_current;

    reg  [7:0] io_out_current;
    wire [7:0] io_out_next = sync_rst ? 8'd0 : io_write_data;
    wire        io_out_trigger = sync_rst || (clk_en && io_write_enable && system_enabled);
    always_ff @(posedge clk) begin
        if (io_out_trigger) begin
            io_out_current <= io_out_next;
        end
    end
    assign io_out = io_out_current;

endmodule : crash_course_cpu_io
