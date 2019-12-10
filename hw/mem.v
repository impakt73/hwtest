module mem
(
    input i_clk,
    input i_rst,

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
    if (i_rst)
        begin
            //$display("Initializing Memory");

            r_mem[0]  <= 64'd1;
            r_mem[1]  <= 64'd9;
            r_mem[2]  <= 64'd10;
            r_mem[3]  <= 64'd3;
            r_mem[4]  <= 64'd2;
            r_mem[5]  <= 64'd3;
            r_mem[6]  <= 64'd11;
            r_mem[7]  <= 64'd0;
            r_mem[8]  <= 64'd99;
            r_mem[9]  <= 64'd30;
            r_mem[10] <= 64'd40;
            r_mem[11] <= 64'd50;
        end
    else
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
                                $display("Read[%d]: %h (From %h)", portIndex, r_mem[i_addr[portIndex]], i_addr[portIndex]);
                            end
                        OP_WRITE:
                            begin
                                r_mem[i_addr[portIndex]] <= i_data[portIndex];
                                $display("Write[%d]: %h (To %h)", portIndex, i_data[portIndex], i_addr[portIndex]);
                            end
                        default:
                            o_data[portIndex] <= 64'h0;
                    endcase
                end
        end

endmodule
