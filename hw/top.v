`include "icp.v"
`include "mem.v"

module top
(
    input i_clk,
    input i_rst,

    input  wire [1:0]  i_mem_op,
    input  wire [63:0] i_mem_addr,
    input  wire [63:0] i_mem_data,
    output reg  [63:0] o_mem_data,

    output wire o_mem_op_pending
);

parameter MEM_OP_NOP   = 2'h0;
parameter MEM_OP_READ  = 2'h1;
parameter MEM_OP_WRITE = 2'h2;

parameter MEM_ADDR_ICP_ENABLE = 64'h8000_0000_0000_0000;
parameter MEM_ADDR_HALTED     = 64'h8000_0000_0000_0001;

parameter MEM_READ_STATE_IDLE  = 2'h0;
parameter MEM_READ_STATE_LOAD  = 2'h1;
parameter MEM_READ_STATE_WRITE = 2'h2;

reg  [1:0]  r_mem_op[3:0];
reg  [12:0] r_mem_addr[3:0];
reg  [63:0] r_mem_data_in[3:0];
wire [63:0] w_mem_data_out[3:0];
reg  [1:0]  r_mem_read_state;

assign o_mem_op_pending = ((r_mem_read_state == MEM_READ_STATE_LOAD) | (r_mem_read_state == MEM_READ_STATE_WRITE));

mem mem_inst
(
    .i_clk(i_clk),

    .i_op(r_mem_op),
    .i_addr(r_mem_addr),
    .i_data(r_mem_data_in),
    .o_data(w_mem_data_out)
);

wire w_halted;
reg r_icp_enable;

icp icp_inst
(
    .i_clk(i_clk & r_icp_enable),
    .i_rst(i_rst),

    .o_op(r_mem_op),
    .o_addr(r_mem_addr),
    .i_data(w_mem_data_out),
    .o_data(r_mem_data_in),

    .o_halted(w_halted)
);

always @ (posedge i_clk)
    if (i_rst)
        begin
            r_icp_enable     <= 0;
            r_mem_read_state <= MEM_READ_STATE_IDLE;
        end
    else
        begin
            case (r_mem_read_state)
                MEM_READ_STATE_IDLE:
                    begin
                        if (i_mem_addr[63])
                            // If the high bit is set, this is a register operation
                            begin
                                case (i_mem_addr)
                                    MEM_ADDR_ICP_ENABLE:
                                        if (i_mem_op == MEM_OP_WRITE)
                                            r_icp_enable <= i_mem_data[0];
                                        else if (i_mem_op == MEM_OP_READ)
                                            o_mem_data <= {{63{1'd0}}, r_icp_enable};
                                    MEM_ADDR_HALTED:
                                        if (i_mem_op == MEM_OP_READ)
                                            o_mem_data <= {{63{1'd0}}, w_halted};
                                endcase
                            end
                        else if (r_icp_enable == 0)
                            // This is a regular memory operation
                            // We can only handle these if the icp is currently disabled otherwise we risk memory unit conflicts
                            begin
                                // Forward the memory operation to the memory unit
                                r_mem_op[0]   <= i_mem_op;
                                r_mem_addr[0] <= i_mem_addr[12:0];

                                if (i_mem_op == MEM_OP_READ)
                                    begin
                                        // Memory reads have a one cycle latency so we need to wait here
                                        r_mem_read_state <= MEM_READ_STATE_LOAD;
                                        //$display("Preparing Read From %h", i_mem_addr);
                                    end
                                else if (i_mem_op == MEM_OP_WRITE)
                                    begin
                                        r_mem_data_in[0] <= i_mem_data;
                                        //$display("Writing %h To %h", i_mem_data, i_mem_addr);
                                    end
                            end
                    end
                MEM_READ_STATE_LOAD:
                    begin
                        r_mem_read_state <= MEM_READ_STATE_WRITE;
                    end
                MEM_READ_STATE_WRITE:
                    begin
                        //$display("Returing %h From Memory Bus", w_mem_data_out[0]);
                        o_mem_data <= w_mem_data_out[0];
                        r_mem_read_state <= MEM_READ_STATE_IDLE;
                    end
                default:
                    begin
                        r_mem_read_state <= MEM_READ_STATE_IDLE;
                    end
            endcase
        end

endmodule
