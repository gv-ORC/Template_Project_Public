/**
 *  Module: crash_course_cpu_program_memory
 *
 *  About: 
 *
 *  Ports:
 *
**/
module crash_course_cpu_program_memory (
    input   [7:0] program_counter,

    output [15:0] instruction
);

logic  [15:0] instruction_vector;
assign        instruction = instruction_vector;
always_comb begin : instruction_vector_mux
    case (program_counter)
            //! First Test
            // 8'h00 : instruction_vector = 16'hA101; // AddImm r1 #1
            // 8'h01 : instruction_vector = 16'h9100; // Store r1 [0]
            // 8'h02 : instruction_vector = 16'hE000; // Jump #0
            //! Fib Test
            8'h00 : instruction_vector = 16'hA100; // LoadImm r1 #0 
            8'h01 : instruction_vector = 16'hA200; // LoadImm r2 #1
            8'h02 : instruction_vector = 16'hA301; // LoadImm r3 #0
            8'h03 : instruction_vector = 16'h9001; // Store r1 #0
            8'h04 : instruction_vector = 16'h9003; // Store r3 #0
            8'h05 : instruction_vector = 16'h1123; // Add r1 r2 r3
            8'h06 : instruction_vector = 16'h9001; // Store r1 #0
            8'h07 : instruction_vector = 16'h1231; // Add r2 r3 r1 
            8'h08 : instruction_vector = 16'h9002; // Store r2 #0
            8'h09 : instruction_vector = 16'h1312; // Add r3 r1 r2
            8'h0A : instruction_vector = 16'h9003; // Store r3 #0
            8'h0B : instruction_vector = 16'hE005; // Jump #5
            //! Waffle's Fib
            // 8'h00 : instruction_vector = 16'hB101;
            // 8'h01 : instruction_vector = 16'h1012;
            // 8'h02 : instruction_vector = 16'h1121;
            // 8'h03 : instruction_vector = 16'h9103;
            // 8'h04 : instruction_vector = 16'h1212;
            // 8'h05 : instruction_vector = 16'h9203;
            // 8'h06 : instruction_vector = 16'hE003;

            // 8'h00 : instruction_vector = 16'h0000;
            // 8'h01 : instruction_vector = 16'h0000;
            // 8'h02 : instruction_vector = 16'h0000;
            // 8'h03 : instruction_vector = 16'h0000;
            // 8'h04 : instruction_vector = 16'h0000;
            // 8'h05 : instruction_vector = 16'h0000;
            // 8'h06 : instruction_vector = 16'h0000;
            // 8'h07 : instruction_vector = 16'h0000;
            // 8'h08 : instruction_vector = 16'h0000;
            // 8'h09 : instruction_vector = 16'h0000;
            // 8'h0A : instruction_vector = 16'h0000;
            // 8'h0B : instruction_vector = 16'h0000;
            // 8'h0C : instruction_vector = 16'h0000;
            // 8'h0D : instruction_vector = 16'h0000;
            // 8'h0E : instruction_vector = 16'h0000;
            // 8'h0F : instruction_vector = 16'h0000;
            // 8'h10 : instruction_vector = 16'h0000;
            // 8'h11 : instruction_vector = 16'h0000;
            // 8'h12 : instruction_vector = 16'h0000;
            // 8'h13 : instruction_vector = 16'h0000;
            // 8'h14 : instruction_vector = 16'h0000;
            // 8'h15 : instruction_vector = 16'h0000;
            // 8'h16 : instruction_vector = 16'h0000;
            // 8'h17 : instruction_vector = 16'h0000;
            // 8'h18 : instruction_vector = 16'h0000;
            // 8'h19 : instruction_vector = 16'h0000;
            // 8'h1A : instruction_vector = 16'h0000;
            // 8'h1B : instruction_vector = 16'h0000;
            // 8'h1C : instruction_vector = 16'h0000;
            // 8'h1D : instruction_vector = 16'h0000;
            // 8'h1E : instruction_vector = 16'h0000;
            // 8'h1F : instruction_vector = 16'h0000;
        default: instruction_vector = 0;
    endcase
end

endmodule : crash_course_cpu_program_memory
