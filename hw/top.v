`include "icp.v"

module top
(
    input i_clk,
    input i_rst,

    input      [1:0]  i_reg_ctl,
    input      [31:0] i_reg_addr,
    input      [31:0] i_reg_data,
    output reg [31:0] o_reg_data,

    input i_logic_en,

    output reg o_read_en,
    output reg [63:0] o_read_addr,

    output reg o_write_en,
    output reg [63:0] o_write_addr,

    input wire [63:0] i_data,
    output reg [63:0] o_data
);

parameter CTL_NOP   = 2'h0;
parameter CTL_READ  = 2'h1;
parameter CTL_WRITE = 2'h2;

wire w_halted;

icp icp_inst
(
    .i_clk(i_clk & i_logic_en),
    .i_rst(i_rst),

    .o_read_en(o_read_en),
    .o_read_addr(o_read_addr[31:0]),
    .i_data_in(i_data[31:0]),

    .o_write_en(o_write_en),
    .o_write_addr(o_write_addr[31:0]),
    .o_data_out(o_data[31:0]),

    .o_halted(w_halted)
);

always @ (posedge i_clk)
    begin
        if ((i_reg_ctl == CTL_READ) & (i_reg_addr == 0))
            o_reg_data <= {{31{1'd0}}, w_halted};
    end

endmodule
