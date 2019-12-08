`include "icp.v"

module top
(
    input i_clk,
    input i_rst,

    output reg o_read_en,
    output reg [63:0] o_read_addr,

    output reg o_write_en,
    output reg [63:0] o_write_addr,

    input wire [63:0] i_data,
    output reg [63:0] o_data
);

icp icp_inst
(
    .i_clk(i_clk),
    .i_rst(i_rst),

    .o_read_en(o_read_en),
    .o_read_addr(o_read_addr[31:0]),
    .i_data_in(i_data[31:0]),

    .o_write_en(o_write_en),
    .o_write_addr(o_write_addr[31:0]),
    .o_data_out(o_data[31:0])
);

endmodule
