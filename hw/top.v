`include "icp.v"
`include "mem.v"
`include "uart_tx.v"
`include "uart_rx.v"

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
parameter MEM_ADDR_ICP_HALTED = 64'h8000_0000_0000_0001;

parameter MEM_ADDR_UART_TX_DATA = 64'h8000_0000_0000_0002;
parameter MEM_ADDR_UART_RX_DATA = 64'h8000_0000_0000_0003;

parameter MEM_OP_STATE_IDLE                  = 3'h0;
parameter MEM_OP_STATE_PENDING_READ_MEM      = 3'h1;
parameter MEM_OP_STATE_EXECUTE_READ_MEM      = 3'h2;
parameter MEM_OP_STATE_PENDING_WRITE_UART_TX = 3'h3;
parameter MEM_OP_STATE_PENDING_READ_UART_RX  = 3'h4;

reg [2:0] r_mem_op_state;

assign o_mem_op_pending = (r_mem_op_state != MEM_OP_STATE_IDLE);

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

wire w_uart_tx_data_rdy;
wire w_uart_tx;

reg [7:0] r_uart_tx_data;
reg r_uart_tx_data_valid;

uart_tx #(.CLK_PER_BIT(4)) uart_tx_inst
(
    .i_clk(i_clk),
    .i_rst(i_rst),

    .o_tx(w_uart_tx),
    .o_data_rdy(w_uart_tx_data_rdy),
    .i_data(r_uart_tx_data),
    .i_data_valid(r_uart_tx_data_valid)
);

wire [7:0] w_uart_rx_data;
wire w_uart_rx_data_valid;

uart_rx #(.CLK_PER_BIT(4)) uart_rx_inst
(
    .i_clk(i_clk),
    .i_rst(i_rst),

    .o_data(w_uart_rx_data),
    .o_data_valid(w_uart_rx_data_valid),
    .i_rx(w_uart_tx)
);

always @ (posedge i_clk)
    if (i_rst)
        begin
            r_icp_enable         <= 0;
            r_mem_op_state       <= MEM_OP_STATE_IDLE;
            r_uart_tx_data       <= 0;
            r_uart_tx_data_valid <= 0;
        end
    else
        begin
            case (r_mem_op_state)
                MEM_OP_STATE_IDLE:
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
                                    MEM_ADDR_ICP_HALTED:
                                        if (i_mem_op == MEM_OP_READ)
                                            o_mem_data <= {{63{1'd0}}, w_icp_halted};
                                    MEM_ADDR_UART_TX_DATA:
                                        if (i_mem_op == MEM_OP_WRITE)
                                            begin
                                                r_uart_tx_data       <= i_mem_data[7:0];
                                                r_uart_tx_data_valid <= 1;
                                                r_mem_op_state       <= MEM_OP_STATE_PENDING_WRITE_UART_TX;
                                            end
                                    MEM_ADDR_UART_RX_DATA:
                                        if (i_mem_op == MEM_OP_READ)
                                            r_mem_op_state <= MEM_OP_STATE_PENDING_READ_UART_RX;
                                endcase
                            end
                        else
                            // This is a regular memory operation
                            begin
                                if (i_mem_op == MEM_OP_READ)
                                    begin
                                        // Memory reads have some latency so we need to enter a wait state here
                                        r_mem_op_state <= MEM_OP_STATE_PENDING_READ_MEM;
                                        //$display("Preparing Read From %h", i_mem_addr);
                                    end
                                else if (i_mem_op == MEM_OP_WRITE)
                                    begin
                                        //$display("Writing %h To %h", i_mem_data, i_mem_addr);
                                    end
                            end
                    end
                MEM_OP_STATE_PENDING_READ_MEM:
                    begin
                        // Wait for the memory unit to read the request and write the output data to the bus, then transition to the read state
                        r_mem_op_state <= MEM_OP_STATE_EXECUTE_READ_MEM;
                    end
                MEM_OP_STATE_EXECUTE_READ_MEM:
                    begin
                        // Read the requested value from the memory unit's data output
                        //$display("Returing %h From Memory Bus", w_mem_data_out[0]);
                        o_mem_data     <= w_mem_data_out[0];
                        r_mem_op_state <= MEM_OP_STATE_IDLE;
                    end
                MEM_OP_STATE_PENDING_WRITE_UART_TX:
                    begin
                        if (r_uart_tx_data_valid)
                            begin
                                // This is a wait on a TX write so we need to wait until the UART TX interface is ready
                                if (w_uart_tx_data_rdy)
                                    begin
                                        r_uart_tx_data       <= 0;
                                        r_uart_tx_data_valid <= 0;
                                        r_mem_op_state       <= MEM_OP_STATE_IDLE;
                                    end
                            end
                    end
                MEM_OP_STATE_PENDING_READ_UART_RX:
                    begin
                        // This is a wait on an RX read so we need to wait until the UART RX interface has data
                        if (w_uart_rx_data_valid)
                            begin
                                o_mem_data     <= {{56{1'd0}}, w_uart_rx_data};
                                r_mem_op_state <= MEM_OP_STATE_IDLE;
                            end
                    end
                default:
                    begin
                        r_mem_op_state <= MEM_OP_STATE_IDLE;
                    end
            endcase
        end

endmodule
