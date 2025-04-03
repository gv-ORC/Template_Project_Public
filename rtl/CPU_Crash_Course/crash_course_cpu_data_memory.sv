/**
 *  Module: crash_course_cpu_data_memory
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_data_memory (
    input clk,
    input clk_en,
    input sync_rst,

    input        system_enabled,

    input        [7:0] memory_address,
    input              store_enable,
    input        [7:0] store_data,
    output       [7:0] load_data,

    input  [15:0][7:0] io_in,
    output             io_read_en,
    output [15:0][7:0] io_out,
    output             io_write_en
);

    reg  [7:0] data_ram [255:0];
    wire data_ram_trigger = clk_en && store_enable && system_enabled;
    always_ff @(posedge clk) begin
        if (data_ram_trigger) begin
            data_ram[memory_address] <= store_data;
        end
    end

    wire address_upper_zero_check = memory_address[7:3] == 4'd0;

    //? IO 0
    wire [7:0] io_0_read;
    wire       io_0_write_enable = address_zero_check && store_enable;
    crash_course_cpu_io io_0 (
        .clk            (clk),
        .clk_en         (clk_en),
        .sync_rst       (sync_rst),
        .system_enabled (system_enabled),
        .io_in          (io_0_in),
        .io_out         (io_0_out),
        .io_read_data   (io_0_read),
        .io_write_data  (store_data),
        .io_write_enable(io_0_write_enable)
    );

    //? IO 1
    wire [7:0] io_1_read;
    wire       io_1_write_enable = address_one_check && store_enable;
    crash_course_cpu_io io_1 (
        .clk            (clk),
        .clk_en         (clk_en),
        .sync_rst       (sync_rst),
        .system_enabled (system_enabled),
        .io_in          (io_1_in),
        .io_out         (io_1_out),
        .io_read_data   (io_1_read),
        .io_write_data  (store_data),
        .io_write_enable(io_1_write_enable)
    );

    logic  [7:0] selected_output;
    wire   [1:0] selected_output_condition;
    assign       selected_output_condition[0] = address_zero_check;
    assign       selected_output_condition[1] = address_one_check;
    always_comb begin : selected_output_mux
        case (selected_output_condition)
            2'b00  : selected_output = data_ram[memory_address];
            2'b01  : selected_output = io_0_read;
            2'b10  : selected_output = io_1_read;
            2'b11  : selected_output = 8'd0; //! Error
            default: selected_output = 8'd0;
        endcase
    end
    assign load_data = selected_output;

endmodule : crash_course_cpu_data_memory
