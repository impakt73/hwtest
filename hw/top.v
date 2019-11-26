module top
(
    input i_clk,
    input i_rst,

    input [63:0] i_data,
    output [63:0] o_data
);

reg [63:0] r_data;

assign o_data = r_data;

always_ff @ (posedge i_clk or posedge i_rst) begin

    if (i_rst) begin
        r_data <= 0;
    end
    else begin
        r_data <= (i_data << 1);
    end

end

endmodule
