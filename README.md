# Template_Project_Public

Template Project that can be easily ported to new FPGA platforms

## Setup Requirements:

### Windows 10/11:

Build latest version of Verilator in WSL
Install GTKwave in WSL
Install an x11 server (windows 10 only)

### Linux:

Build latest version of Verilator
Install GTKwave

## Use:

Go into VSCode, set the default task to testBench_Clean then when you make a testbench in system verilog, make sure its in a /testbench/ folder somewhere under /rtl/.

If you have your testbench as the active window in VSCode, you can then do crtl-shift-B to build your project. It will verilate and simulate the project for you, then open GTKwave with the output.

## Crash Course CPU

Their is a basic 16 bit educational CPU included with this template project. It is currently in a "zombie" state where the memory module needs updating... I will get to that soon.
For now; here is the ISA for it: https://docs.google.com/spreadsheets/d/1elO1e7osur-0VDggtVYSnr1LFjubyBr9qg9z-xEgIX0/edit?ouid=101087744752973423523&usp=sheets_home&ths=true