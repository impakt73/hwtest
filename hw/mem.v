module mem
(
    input i_clk,

    input  wire [1:0]  i_op[3:0],
    input  wire [12:0] i_addr[3:0],
    input  wire [63:0] i_data[3:0],
    output reg  [63:0] o_data[3:0]
);

parameter OP_NONE  = 2'h0;
parameter OP_READ  = 2'h1;
parameter OP_WRITE = 2'h2;

reg [63:0] r_mem[8191:0];

always @ (posedge i_clk)
    begin
        integer portIndex;
        for (portIndex = 0; portIndex < 4; ++portIndex)
            begin
                //$display("Memory Op: %d", i_op[portIndex]);
                case (i_op[portIndex])
                    OP_NONE:
                        o_data[portIndex] <= 64'h0;
                    OP_READ:
                        begin
                            o_data[portIndex] <= r_mem[i_addr[portIndex]];
                            //$display("Read[%d]: %h (From %h)", portIndex, r_mem[i_addr[portIndex]], i_addr[portIndex]);
                        end
                    OP_WRITE:
                        begin
                            r_mem[i_addr[portIndex]] <= i_data[portIndex];
                            //$display("Write[%d]: %h (To %h)", portIndex, i_data[portIndex], i_addr[portIndex]);
                        end
                    default:
                        o_data[portIndex] <= 64'h0;
                endcase
            end
    end

endmodule
