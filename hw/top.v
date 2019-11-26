module top
(
    input i_clk,
    input i_rst,

    output reg o_read_en,
    output reg [63:0] o_read_addr,

    output reg o_write_en,
    output reg [63:0] o_write_addr,

    input wire [63:0] i_data,
    output reg [63:0] o_data
);

reg [1:0]  r_state;
reg [63:0] r_data;

parameter read    = 2'b00;
parameter compute = 2'b01;
parameter write   = 2'b10;

always_ff @ (posedge i_clk or posedge i_rst) begin

    if (i_rst) begin
        o_read_en  <= 0;
        o_write_en <= 0;
        r_state    <= read;
    end
    else begin
        case (r_state)
            read:
                begin
                    o_write_en  <= 0;
                    o_read_en   <= 1;
                    o_read_addr <= 0;
                    r_state     <= compute;
                end
            compute:
                begin
                    o_read_en   <= 0;
                    r_data      <= (i_data << 1);
                    r_state     <= write;
                end
            write:
                begin
                    o_write_en   <= 1;
                    o_write_addr <= 0;
                    o_data       <= r_data;
                    r_state      <= read;
                end
            default:
                r_state <= read;
        endcase
    end

end

endmodule
