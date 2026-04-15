
// =============================================================================
// SPI SLAVE - Simple slave to test against
// =============================================================================
module spi_slave #(
    parameter DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    // SPI bus
    input  logic                  sclk,
    input  logic                  mosi,
    output logic                  miso,
    input  logic                  cs_n,
    // Received data output
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  rx_valid,
    // Data to send back
    input  logic [DATA_WIDTH-1:0] tx_data
);

    logic [DATA_WIDTH-1:0] rx_shift;
    logic [DATA_WIDTH-1:0] tx_shift;
    logic [$clog2(DATA_WIDTH):0] bit_cnt;
    logic cs_n_d;   // Delayed CS_N for edge detection

    // Detect CS_N falling edge (start of transfer)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) cs_n_d <= 1'b1;
        else        cs_n_d <= cs_n;
    end

    // Shift in MOSI on SCLK rising, shift out MISO on SCLK falling
    always_ff @(posedge sclk) begin
        if (!cs_n)
            rx_shift <= {rx_shift[DATA_WIDTH-2:0], mosi};
    end

    always_ff @(negedge sclk or negedge cs_n) begin
        if (!cs_n && cs_n_d)          // CS just asserted - load TX data
            tx_shift <= tx_data;
        else if (!cs_n)
            tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
    end

    // Bit counter and rx_valid
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt  <= '0;
            rx_valid <= 1'b0;
            rx_data  <= '0;
        end else begin
            rx_valid <= 1'b0;
            if (!cs_n && cs_n_d) begin   // CS falling edge
                bit_cnt <= '0;
            end else if (cs_n && !cs_n_d) begin   // CS rising edge - transfer done
                rx_data  <= rx_shift;
                rx_valid <= 1'b1;
            end
        end
    end

    assign miso = tx_shift[DATA_WIDTH-1];

endmodule : spi_slave