module icp
(
    input i_clk,
    input i_rst,

    output reg o_read_en,
    output reg [31:0] o_read_addr,
    input  [31:0] i_data_in,

    output reg o_write_en,
    output reg [31:0] o_write_addr,
    output reg [31:0] o_data_out,

    output reg o_halted
);

reg [31:0] r_pc;
reg [3:0]  r_state;
reg [31:0] r_regs[3:0];

parameter S_FETCH_OPCODE     = 4'h0;
parameter S_DECODE_OPCODE    = 4'h1;
parameter S_FETCH_OPERAND_0  = 4'h2;
parameter S_FETCH_OPERAND_1  = 4'h3;
parameter S_FETCH_OPERAND_2  = 4'h4;
parameter S_EXECUTE_OPCODE   = 4'h5;
parameter S_FETCH_POSITION_0 = 4'h6;
parameter S_FETCH_POSITION_1 = 4'h7;
parameter S_WRITE_RESULT     = 4'h8;
parameter S_HALTED           = 4'h9;

parameter OP_ADD      = 7'd1;
parameter OP_MULTIPLY = 7'd2;
parameter OP_HALT     = 7'd99;
parameter OP_JUMP     = 7'd100;

assign o_halted = (r_state == S_HALTED);

always @ (posedge i_clk) begin

    if (i_rst) begin
        r_pc       <= 0;
        o_read_en  <= 0;
        o_write_en <= 0;
        r_state    <= S_FETCH_OPCODE;
    end
    else begin
        $display("State: %d", r_state);
        case (r_state)
            S_FETCH_OPCODE:
                begin
                    // Request the opcode from memory
                    o_read_addr <= r_pc;
                    o_read_en   <= 1;
                    o_write_en  <= 0;
                    r_state     <= S_DECODE_OPCODE;
                end
            S_DECODE_OPCODE:
                begin
                    // Store the opcode in our first register
                    r_regs[0] <= i_data_in;

                    // Begin reading the operands
                    o_read_addr <= r_pc + 4;
                    r_state     <= S_FETCH_OPERAND_0;
                end
            S_FETCH_OPERAND_0:
                begin
                    // Store the operand data in registers
                    r_regs[1] <= i_data_in;

                    // Read the next operand
                    o_read_addr <= r_pc + 8;
                    r_state     <= S_FETCH_OPERAND_1;
                end
            S_FETCH_OPERAND_1:
                begin
                    // Store the operand data in registers
                    r_regs[2] <= i_data_in;

                    // Read the next operand
                    o_read_addr <= r_pc + 12;
                    r_state     <= S_FETCH_OPERAND_2;
                end
            S_FETCH_OPERAND_2:
                begin
                    // Store the operand data in registers
                    r_regs[3] <= i_data_in;

                    // Transition to the execution state
                    o_read_en   <= 0;
                    r_state <= S_EXECUTE_OPCODE;
                end
            S_EXECUTE_OPCODE:
                begin
                    case (r_regs[0][6:0])
                        OP_ADD, OP_MULTIPLY:
                            begin
                                // Fetch the required positions before we perform the operation
                                o_read_en   <= 1;
                                o_read_addr <= (r_regs[1] * 4);
                                r_state     <= S_FETCH_POSITION_0;
                            end
                        OP_JUMP:
                            begin
                                // Transition to requested position
                                r_pc    <= (r_regs[1] * 4);
                                r_state <= S_FETCH_OPCODE;
                            end
								OP_HALT:
                            begin
                                // Transition to the halted state
                                r_state <= S_HALTED;
                            end
                        default:
                            // Halt if we end up with a bad opcode
                            r_state <= S_HALTED;
                    endcase
                end
            S_FETCH_POSITION_0:
                begin
                    // Overwrite the position address with the data from memory
                    r_regs[1] <= i_data_in;

                    // Read the next position
                    o_read_addr <= (r_regs[2] * 4);
                    r_state <= S_FETCH_POSITION_1;
                end
            S_FETCH_POSITION_1:
                begin
                    // Overwrite the position address with the data from memory
                    r_regs[2] <= i_data_in;

                    // Get ready to write the result operation result
                    o_read_en <= 0;
                    r_state   <= S_WRITE_RESULT;
                end
            S_WRITE_RESULT:
                begin
                    // Set the write address based on the output position from the instruction
                    o_write_addr <= (r_regs[3] * 4);
                    o_write_en   <= 1;

                    // Perform the requested operation and write the result to our data output
                    case (r_regs[0][6:0])
                        OP_ADD:
                            o_data_out <= (r_regs[1] + r_regs[2]);
                        OP_MULTIPLY:
                            o_data_out <= (r_regs[1] * r_regs[2]);
                        default:
                            // Write 0 if we end up with a bad opcode here
                            o_data_out <= 0;
                    endcase

                    // Continue processing instructions
                    r_pc    <= r_pc + 16;
                    r_state <= S_FETCH_OPCODE;
                end
            S_HALTED:
                begin
                    // We're halted so make sure we don't do anything here
                    o_write_en <= 0;
                    o_read_en  <= 0;
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
