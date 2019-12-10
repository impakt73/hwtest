module icp
(
    input i_clk,
    input i_rst,

    output  reg  [1:0]  o_op[3:0],
    output  reg  [12:0] o_addr[3:0],
    input   wire [63:0] i_data[3:0],
    output  reg  [63:0] o_data[3:0],

    output reg o_halted
);

reg [10:0] r_pc;
reg [1:0]  r_state;

parameter S_FETCH_OPCODE   = 2'h0;
parameter S_DECODE_OPCODE  = 2'h1;
parameter S_EXECUTE_OPCODE = 2'h2;
parameter S_HALTED         = 2'h3;

parameter OP_ADD      = 7'd1;
parameter OP_MULTIPLY = 7'd2;
parameter OP_HALT     = 7'd99;
parameter OP_JUMP     = 7'd100;

assign o_halted = (r_state == S_HALTED);

always @ (posedge i_clk) begin

    if (i_rst) begin
        integer portIndex;
        for (portIndex = 0; portIndex < 4; ++portIndex)
            o_op[portIndex] <= 0; // NONE

        r_pc    <= 0;
        r_state <= S_FETCH_OPCODE;
    end
    else begin
        $display("State: %d", r_state);
        case (r_state)
            S_FETCH_OPCODE:
                begin
                    // Request the opcode from memory
                    integer portIndex;
                    for (portIndex = 0; portIndex < 4; ++portIndex)
                        begin
                            o_op[portIndex]   <= 1; // READ
                            o_addr[portIndex] <= { {2{1'b0}}, r_pc + portIndex[10:0] };
                        end

                    r_state <= S_DECODE_OPCODE;
                end
            S_DECODE_OPCODE:
                begin
                    $display("Op: %d", i_data[0][6:0]);
                    case (i_data[0][6:0])
                        OP_ADD, OP_MULTIPLY:
                            begin
                                o_addr[1] <= i_data[1][12:0];
                                o_addr[2] <= i_data[2][12:0];

                                r_state <= S_EXECUTE_OPCODE;
                            end
                        OP_JUMP:
                            begin
                                integer portIndex;
                                for (portIndex = 0; portIndex < 4; ++portIndex)
                                    o_op[portIndex] <= 0; // NONE

                                // Transition to requested position
                                r_pc    <= i_data[1][10:0];
                                r_state <= S_FETCH_OPCODE;
                            end
                        OP_HALT:
                            begin
                                integer portIndex;
                                for (portIndex = 0; portIndex < 4; ++portIndex)
                                    o_op[portIndex] <= 0; // NONE

                                // Transition to the halted state
                                r_state <= S_HALTED;
                            end
                        default:
                            // Halt if we end up with a bad opcode
                            r_state <= S_HALTED;
                    endcase
                end
            S_EXECUTE_OPCODE:
                begin
                    // Set the write address based on the output position from the instruction
                    o_op[0]   <= 2; // WRITE
                    o_addr[0] <= i_data[3][12:0];

                    $display("Write Location: %h", i_data[3][12:0]);

                    // Perform the requested operation and write the result to our data output
                    case (i_data[0][6:0])
                        OP_ADD:
                            begin
                            o_data[0] <= (i_data[1] + i_data[2]);
                            $display("Write: %d + %d to %h", i_data[1], i_data[2], i_data[3][12:0]);
                            end
                        OP_MULTIPLY:
                            begin
                            o_data[0] <= (i_data[1] * i_data[2]);
                            $display("Write: %d * %d to %h", i_data[1], i_data[2], i_data[3][12:0]);
                            end
                        default:
                            // Write 0 if we end up with a bad opcode here
                            o_data[0] <= 0;
                    endcase

                    o_op[1] <= 0; // NONE
                    o_op[2] <= 0; // NONE
                    o_op[3] <= 0; // NONE

                    // Continue processing instructions
                    r_pc    <= r_pc + 4;
                    r_state <= S_FETCH_OPCODE;
                end
            S_HALTED:
                begin
                    // We're halted so make sure we don't do anything here
                    integer portIndex;
                    for (portIndex = 0; portIndex < 4; ++portIndex)
                        o_op[portIndex] <= 0; // NONE
                end
            default:
                begin
                    r_pc    <= 0;
                    r_state <= S_FETCH_OPCODE;
                end
        endcase
    end
end

endmodule
