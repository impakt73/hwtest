module uart_tx
#(
    parameter CLK_PER_BIT = 4
)
(
    input i_clk,
    input i_rst,

    output reg         o_tx,
    output reg         o_data_rdy,
    input  wire  [7:0] i_data,
    input  wire        i_data_valid
);

parameter S_IDLE         = 4'h0;
parameter S_TX_START_BIT = 4'h1;
parameter S_TX_STOP_BIT  = 4'h2;
parameter S_TX_BIT_0     = 4'h3;
parameter S_TX_BIT_1     = 4'h4;
parameter S_TX_BIT_2     = 4'h5;
parameter S_TX_BIT_3     = 4'h6;
parameter S_TX_BIT_4     = 4'h7;
parameter S_TX_BIT_5     = 4'h8;
parameter S_TX_BIT_6     = 4'h9;
parameter S_TX_BIT_7     = 4'hA;

parameter COUNTER_SIZE = $clog2(CLK_PER_BIT);

reg [3:0] r_state;
reg [7:0] r_data;
reg [COUNTER_SIZE-1:0] r_clk_counter;

always @ (posedge i_clk)
    if (i_rst)
        begin
            r_state       <= S_IDLE;
            r_data        <= 0;
            r_clk_counter <= 0;
            o_tx          <= 1;
            o_data_rdy    <= 1;
        end
    else
        begin
            // Handle Transmit Logic
            if (r_state == S_IDLE)
                begin
                    // The transmit line should always high when there's no activity
                    o_tx  <= 1;

                    if (o_data_rdy)
                        if (i_data_valid)
                            begin
                                r_data     <= i_data;
                                o_data_rdy <= 0;
                            end

                    if (r_clk_counter == COUNTER_SIZE'(CLK_PER_BIT - 1))
                        begin
                            r_clk_counter <= 0;

                            if (!o_data_rdy)
                                begin
                                    r_state <= S_TX_START_BIT;
                                    o_tx    <= 0;
                                end
                        end
                    else
                        begin
                            r_clk_counter <= (r_clk_counter + 1);
                        end
                end
            else
                begin
                    case (r_state)
                        S_TX_START_BIT:
                            begin
                                // The transmit line should be low during the start bit
                                o_tx <= 0;
                            end
                        S_TX_STOP_BIT:
                            begin
                                // The transmit line should be high during the stop bit
                                o_tx <= 1;

                                // Accept new data during the stop bit state since we've already transmitted
                                // our internal byte payload
                                if (i_data_valid)
                                    begin
                                        r_data     <= i_data;
                                        o_data_rdy <= 0;
                                    end
                            end
                        default:
                            begin
                                // Transmit the appropriate bit of data based on our state
                                o_tx <= r_data[3'(r_state - S_TX_BIT_0)];
                            end
                    endcase

                    if (r_clk_counter == COUNTER_SIZE'(CLK_PER_BIT - 1))
                        begin
                            r_clk_counter <= 0;

                            case (r_state)
                                S_TX_START_BIT:
                                    begin
                                        // We begin transmitting the data bits once we finish transmitting the start bit
                                        r_state <= S_TX_BIT_0;
                                        o_tx    <= r_data[0];
                                    end
                                S_TX_BIT_7:
                                    begin
                                        // After we transmit the last bit, we need to transmit the stop bit
                                        r_state    <= S_TX_STOP_BIT;
                                        o_tx       <= 1;
                                        o_data_rdy <= 1;
                                    end
                                S_TX_STOP_BIT:
                                    begin
                                        // If we have valid data during the stop bit stage, we can move straight into the start bit for it
                                        if (!o_data_rdy)
                                            begin
                                                r_state <= S_TX_START_BIT;
                                                o_tx    <= 0;
                                            end
                                        else
                                            begin
                                                // We transition back to idle once we finish transmitting the stop bit
                                                r_state    <= S_IDLE;
                                                o_tx       <= 1;
                                                o_data_rdy <= 1;
                                            end
                                    end
                                default:
                                    begin
                                        // Transition to the next state based on our current state
                                        r_state <= (r_state + 1);
                                        o_tx    <= r_data[3'((r_state + 1'h1) - S_TX_BIT_0)];
                                    end
                            endcase
                        end
                    else
                        begin
                            r_clk_counter <= (r_clk_counter + 1);
                        end
                end
        end

endmodule
