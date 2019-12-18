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

parameter MEM_READ_STATE_IDLE    = 2'h0;
parameter MEM_READ_STATE_REQUEST = 2'h1;
parameter MEM_READ_STATE_READ    = 2'h2;

reg [1:0] r_mem_read_state;

assign o_mem_op_pending = ((r_mem_read_state == MEM_READ_STATE_REQUEST) || (r_mem_read_state == MEM_READ_STATE_READ));

wire [1:0]  w_mem_op[3:0];
wire [12:0] w_mem_addr[3:0];
wire [63:0] w_mem_data_in[3:0];
wire [63:0] w_mem_data_out[3:0];

mem mem_inst
(
    .i_clk(i_clk),

    .i_op(w_mem_op),
    .i_addr(w_mem_addr),
    .i_data(w_mem_data_in),
    .o_data(w_mem_data_out)
);

reg r_icp_enable;
wire [1:0]  w_icp_mem_op[3:0];
wire [12:0] w_icp_mem_addr[3:0];
wire [63:0] w_icp_mem_data_in[3:0];
wire [63:0] w_icp_mem_data_out[3:0];
wire w_icp_halted;

icp icp_inst
(
    .i_clk(i_clk & r_icp_enable),
    .i_rst(i_rst),

    .o_op(w_icp_mem_op),
    .o_addr(w_icp_mem_addr),
    .i_data(w_icp_mem_data_in),
    .o_data(w_icp_mem_data_out),

    .o_halted(w_icp_halted)
);

wire w_reg_op;

// If the high bit is set, it indicates a register operation
assign w_reg_op = i_mem_addr[63];

// Make sure the memory unit is only talking to one client at a time
// When the icp is enabled, it talks to the icp, when it's disabled, it talks to the host system
// Also make sure register operations are not visible to the memory unit
assign w_mem_op[0] = r_icp_enable ? w_icp_mem_op[0] : (w_reg_op ? 2'b0 : i_mem_op);
assign w_mem_op[1] = r_icp_enable ? w_icp_mem_op[1] : 2'b0;
assign w_mem_op[2] = r_icp_enable ? w_icp_mem_op[2] : 2'b0;
assign w_mem_op[3] = r_icp_enable ? w_icp_mem_op[3] : 2'b0;

assign w_mem_addr[0] = r_icp_enable ? w_icp_mem_addr[0] : (w_reg_op ? 13'b0 : i_mem_addr[12:0]);
assign w_mem_addr[1] = r_icp_enable ? w_icp_mem_addr[1] : 13'b0;
assign w_mem_addr[2] = r_icp_enable ? w_icp_mem_addr[2] : 13'b0;
assign w_mem_addr[3] = r_icp_enable ? w_icp_mem_addr[3] : 13'b0;

assign w_mem_data_in[0] = r_icp_enable ? w_icp_mem_data_out[0] : (w_reg_op ? 64'b0 : i_mem_data);
assign w_mem_data_in[1] = r_icp_enable ? w_icp_mem_data_out[1] : 64'b0;
assign w_mem_data_in[2] = r_icp_enable ? w_icp_mem_data_out[2] : 64'b0;
assign w_mem_data_in[3] = r_icp_enable ? w_icp_mem_data_out[3] : 64'b0;

assign w_icp_mem_data_in = w_mem_data_out;

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
                        if (w_reg_op)
                            // This is a register operation
                            begin
                                case (i_mem_addr)
                                    MEM_ADDR_ICP_ENABLE:
                                        if (i_mem_op == MEM_OP_WRITE)
                                            r_icp_enable <= i_mem_data[0];
                                        else if (i_mem_op == MEM_OP_READ)
                                            o_mem_data <= {{63{1'd0}}, r_icp_enable};
                                    MEM_ADDR_HALTED:
                                        if (i_mem_op == MEM_OP_READ)
                                            o_mem_data <= {{63{1'd0}}, w_icp_halted};
                                endcase
                            end
                        else
                            // This is a regular memory operation
                            begin
                                if (i_mem_op == MEM_OP_READ)
                                    begin
                                        // Memory reads have some latency so we need to enter a wait state here
                                        r_mem_read_state <= MEM_READ_STATE_REQUEST;
                                        //$display("Preparing Read From %h", i_mem_addr);
                                    end
                                else if (i_mem_op == MEM_OP_WRITE)
                                    begin
                                        //$display("Writing %h To %h", i_mem_data, i_mem_addr);
                                    end
                            end
                    end
                MEM_READ_STATE_REQUEST:
                    begin
                        // Wait for the memory unit to read the request and write the output data to the bus, then transition to the read state
                        r_mem_read_state <= MEM_READ_STATE_READ;
                    end
                MEM_READ_STATE_READ:
                    begin
                        // Read the requested value from the memory unit's data output
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
