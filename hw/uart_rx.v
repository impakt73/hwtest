module uart_rx
#(
    parameter CLK_PER_BIT = 4
)
(
    input i_clk,
    input i_rst,

    output reg  [7:0] o_data,
    output reg        o_data_valid,
    input  wire       i_data_rdy,
    input  wire       i_rx
);

parameter S_IDLE         = 4'h0;
parameter S_RX_START_BIT = 4'h1;
parameter S_RX_STOP_BIT  = 4'h2;
parameter S_RX_BIT_0     = 4'h3;
parameter S_RX_BIT_1     = 4'h4;
parameter S_RX_BIT_2     = 4'h5;
parameter S_RX_BIT_3     = 4'h6;
parameter S_RX_BIT_4     = 4'h7;
parameter S_RX_BIT_5     = 4'h8;
parameter S_RX_BIT_6     = 4'h9;
parameter S_RX_BIT_7     = 4'hA;

parameter COUNTER_SIZE = $clog2(CLK_PER_BIT);
parameter HALF_CLK_PER_BIT = (CLK_PER_BIT / 2);

reg [3:0] r_state;
reg [7:0] r_data;
reg [COUNTER_SIZE-1:0] r_clk_counter;
reg r_rx_error;

always @ (posedge i_clk)
    if (i_rst)
        begin
            r_state       <= S_IDLE;
            r_data        <= 0;
            r_clk_counter <= 0;
            r_rx_error    <= 0;
            o_data        <= 0;
            o_data_valid  <= 0;
        end
    else
        begin
            // Handle Receive Logic
            if (r_state == S_IDLE)
                begin
                    // If the RX line goes low, then we assume it's the start bit
                    if (i_rx == 0)
                        begin
                            if (i_data_rdy)
                                begin
                                    r_state      <= S_RX_START_BIT;
                                    o_data_valid <= 0;
                                end
                        end
                end
            else
                begin
                    if (r_clk_counter == COUNTER_SIZE'(HALF_CLK_PER_BIT))
                        begin
                            // We sample the input signal when the counter is half full so we can get as close to the
                            // middle of the signal as possible.
                            case (r_state)
                                S_RX_START_BIT:
                                    begin
                                        if (i_rx != 0)
                                            begin
                                                // Set the error bit if the start bit isn't zero when it's supposed to be
                                                r_rx_error <= 1;
                                            end
                                    end
                                S_RX_STOP_BIT:
                                    begin
                                        if (i_rx != 1)
                                            begin
                                                // Set the error bit if the stop bit isn't one when it's supposed to be
                                                r_rx_error <= 1;
                                            end
                                        else
                                            begin
                                                // Expose our data once we've confirmed the stop bit
                                                o_data       <= r_data;
                                                o_data_valid <= 1;
                                                r_data       <= 0;
                                            end
                                    end
                                default:
                                    begin
                                        // Copy the current input value to the correct bit position based on the state
                                        r_data[3'(r_state - S_RX_BIT_0)] <= i_rx;
                                    end
                            endcase

                            // Increment the counter after evaluating the signal
                            r_clk_counter <= (r_clk_counter + 1);
                        end
                    else if (r_clk_counter == COUNTER_SIZE'(CLK_PER_BIT - 1))
                        begin
                            // We've finished a step of the receive logic so we need to reset the counter
                            r_clk_counter <= 0;

                            // Return to the idle state if we encounter an error
                            if (r_rx_error)
                                begin
                                    r_state    <= S_IDLE;
                                    r_rx_error <= 0;
                                    r_data     <= 0;
                                end
                            else
                                begin
                                    case (r_state)
                                        S_RX_START_BIT:
                                            begin
                                                r_state <= S_RX_BIT_0;
                                            end
                                        S_RX_BIT_7:
                                            begin
                                                r_state <= S_RX_STOP_BIT;
                                            end
                                        S_RX_STOP_BIT:
                                            begin
                                                if ((i_rx == 1) || (i_data_rdy == 0))
                                                    // The input line has returned to the idle state or we're not ready to receive
                                                    // more data so we should transition back to idle
                                                    r_state <= S_IDLE;
                                                else
                                                    // The input line has gone low which indicates that it's about to send more data
                                                    // Transition to the start bit phase and mark our data as invalid since we'll be
                                                    // receiving new data soon
                                                    r_state      <= S_RX_START_BIT;
                                                    o_data_valid <= 0;
                                            end
                                        default:
                                            begin
                                                // Transition to the next state based on our current state
                                                r_state <= (r_state + 1);
                                            end
                                    endcase
                                end
                        end
                    else
                        begin
                            r_clk_counter <= (r_clk_counter + 1);
                        end
                end
        end

endmodule
