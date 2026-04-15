module spi_master #(
    parameter DATA_WIDTH  = 8,
    parameter CLK_DIV     = 4,
    parameter CPOL        = 0,
    parameter CPHA        = 0
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  start,
    input  logic [DATA_WIDTH-1:0] tx_data,
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  busy,
    output logic                  done,
    output logic                  sclk,
    output logic                  mosi,
    input  logic                  miso,
    output logic                  cs_n
);

    logic [$clog2(CLK_DIV)-1:0] clk_cnt;
    logic                       sclk_int;
    logic                       sclk_prev;
    logic                       sclk_rise;
    logic                       sclk_fall;

    logic [$clog2(DATA_WIDTH+1)-1:0] tx_bit_cnt;
    logic [$clog2(DATA_WIDTH+1)-1:0] rx_bit_cnt;

    logic [DATA_WIDTH-1:0] tx_shift;
    logic [DATA_WIDTH-1:0] rx_shift;

    typedef enum logic [1:0] {
        IDLE     = 2'b00,
        CS_SETUP = 2'b01,
        TRANSFER = 2'b10,
        CS_HOLD  = 2'b11
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt  <= '0;
            sclk_int <= 1'b0;
        end else if (state == TRANSFER) begin
            if (clk_cnt == CLK_DIV - 1) begin
                clk_cnt  <= '0;
                sclk_int <= ~sclk_int;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end else begin
            clk_cnt  <= '0;
            sclk_int <= 1'b0;
        end
    end

    assign sclk = (state == TRANSFER) ? (sclk_int ^ CPOL) : CPOL;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk_prev <= CPOL;
        else
            sclk_prev <= sclk;
    end

    assign sclk_rise = (state == TRANSFER) && (sclk_prev == 1'b0) && (sclk == 1'b1);
    assign sclk_fall = (state == TRANSFER) && (sclk_prev == 1'b1) && (sclk == 1'b0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start)
                    next_state = CS_SETUP;
            end

            CS_SETUP: begin
                next_state = TRANSFER;
            end

            TRANSFER: begin
                if ((CPHA == 0 && sclk_rise && (rx_bit_cnt == DATA_WIDTH-1)) ||
                    (CPHA == 1 && sclk_fall && (rx_bit_cnt == DATA_WIDTH-1)))
                    next_state = CS_HOLD;
            end

            CS_HOLD: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift   <= '0;
            tx_bit_cnt <= '0;
        end else begin
            case (state)
                IDLE: begin
                    tx_shift   <= tx_data;
                    tx_bit_cnt <= '0;
                end

                TRANSFER: begin
                    if ((CPHA == 0 && sclk_fall) || (CPHA == 1 && sclk_rise)) begin
                        if (tx_bit_cnt < DATA_WIDTH) begin
                            tx_shift   <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                            tx_bit_cnt <= tx_bit_cnt + 1'b1;
                        end
                    end
                end

                default: begin
                end
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift   <= '0;
            rx_data    <= '0;
            rx_bit_cnt <= '0;
        end else begin
            case (state)
                IDLE: begin
                    rx_shift   <= '0;
                    rx_bit_cnt <= '0;
                end

                TRANSFER: begin
                    if ((CPHA == 0 && sclk_rise) || (CPHA == 1 && sclk_fall)) begin
                        if (rx_bit_cnt < DATA_WIDTH) begin
                            rx_shift   <= {rx_shift[DATA_WIDTH-2:0], miso};
                            rx_bit_cnt <= rx_bit_cnt + 1'b1;
                        end
                    end
                end

                CS_HOLD: begin
                    rx_data <= rx_shift;
                end

                default: begin
                end
            endcase
        end
    end

    assign mosi = tx_shift[DATA_WIDTH-1];
    assign cs_n = (state == IDLE || state == CS_HOLD) ? 1'b1 : 1'b0;
    assign busy = (state != IDLE);
    assign done = (state == CS_HOLD);

endmodule
