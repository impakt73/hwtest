`include "icp.v"
`include "mem.v"

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

wire [1:0]  w_mem_op[3:0];
wire [12:0] w_mem_addr[3:0];
wire [63:0] w_mem_data_in[3:0];
reg  [63:0] w_mem_data_out[3:0];

mem mem_inst
(
    .i_clk(i_clk),
    .i_rst(i_rst),

    .i_op(w_mem_op),
    .i_addr(w_mem_addr),
    .i_data(w_mem_data_in),
    .o_data(w_mem_data_out)
);

wire w_halted;

icp icp_inst
(
    .i_clk(i_clk & i_logic_en),
    .i_rst(i_rst),

    .o_op(w_mem_op),
    .o_addr(w_mem_addr),
    .i_data(w_mem_data_out),
    .o_data(w_mem_data_in),

    .o_halted(w_halted)
);

always @ (posedge i_clk)
    begin
        if ((i_reg_ctl == CTL_READ) & (i_reg_addr == 0))
            o_reg_data <= {{31{1'd0}}, w_halted};
    end

endmodule
