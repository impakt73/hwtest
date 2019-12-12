`include "icp.v"
`include "mem.v"

module top
(
    input i_clk,
    input i_rst,
    input i_logic_en,

    input  wire [1:0]  i_mem_op,
    input  wire [63:0] i_mem_addr,
    input  wire [63:0] i_mem_data,
    output reg  [63:0] o_mem_data,

    output wire o_mem_op_pending
);

parameter MEM_OP_NOP   = 2'h0;
parameter MEM_OP_READ  = 2'h1;
parameter MEM_OP_WRITE = 2'h2;

parameter MEM_ADDR_HALTED = 64'h8000_0000_0000_0000;

reg [1:0]  w_mem_op[3:0];
reg [12:0] w_mem_addr[3:0];
reg [63:0] w_mem_data_in[3:0];
reg [63:0] r_mem_data_out[3:0];
reg        r_mem_op_pending;

assign o_mem_op_pending = r_mem_op_pending;

mem mem_inst
(
    .i_clk(i_clk),

    .i_op(w_mem_op),
    .i_addr(w_mem_addr),
    .i_data(w_mem_data_in),
    .o_data(r_mem_data_out)
);

wire w_halted;

icp icp_inst
(
    .i_clk(i_clk & i_logic_en),
    .i_rst(i_rst),

    .o_op(w_mem_op),
    .o_addr(w_mem_addr),
    .i_data(r_mem_data_out),
    .o_data(w_mem_data_in),

    .o_halted(w_halted)
);

always @ (posedge i_clk)
    if (i_rst)
        r_mem_op_pending <= 0;
    else
        if (r_mem_op_pending)
            begin
                o_mem_data <= r_mem_data_out[0];
                r_mem_op_pending <= 0;
            end
        else
            begin
                if (i_mem_addr[63])
                    // If the high bit is set, this is a register operation
                    begin
                        case (i_mem_addr)
                            MEM_ADDR_HALTED:
                                if (i_mem_op == MEM_OP_READ)
                                    o_mem_data <= {{63{1'd0}}, w_halted};
                        endcase
                    end
                else
                    // This is a regular memory operation
                    begin
                        // Forward the memory operation to the memory unit
                        w_mem_op[0]   <= i_mem_op;
                        w_mem_addr[0] <= i_mem_addr[12:0];

                        if (i_mem_op == MEM_OP_READ)
                            // Memory reads have a one cycle latency so we need to wait here
                            r_mem_op_pending <= 1;
                        else if (i_mem_op == MEM_OP_WRITE)
                            w_mem_data_in[0] <= i_mem_data;
                    end
            end

endmodule
