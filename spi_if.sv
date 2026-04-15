// =============================================================================
// FILE: spi_if.sv
// WHAT: SPI Interface
// WHY:  Instead of passing 10 separate signals into every UVM class,
//       we bundle them all into ONE interface and pass that instead.
//       Think of it like a "cable connector" — one plug, many wires inside.
// =============================================================================

interface spi_if (input logic clk);  // clk comes in from tb_top

    // -------------------------------------------------------------------------
    // SPI Signals — these are the actual wires connecting DUT to testbench
    // -------------------------------------------------------------------------
    logic        rst_n;    // active-low reset
    logic        start;    // pulse HIGH to begin a transfer
    logic [7:0]  tx_data;  // byte to send to slave
    logic [7:0]  rx_data;  // byte received from slave
    logic        busy;     // HIGH while transfer is in progress
    logic        done;     // pulses HIGH when transfer is complete
    logic        sclk;     // SPI serial clock (output of master)
    logic        mosi;     // Master Out Slave In
    logic        miso;     // Master In Slave Out
    logic        cs_n;     // Chip Select — active LOW

    // -------------------------------------------------------------------------
    // CLOCKING BLOCK for DRIVER
    // A clocking block tells the simulator WHEN to drive/sample signals.
    // "posedge clk" = synchronize everything to rising clock edge.
    // output = driver writes these signals
    // input  = driver reads these signals
    // -------------------------------------------------------------------------
    clocking driver_cb @(posedge clk);
        default input #1 output #1;   // 1 time unit setup/hold
        output rst_n, start, tx_data; // driver DRIVES these
        input  busy, done, rx_data;   // driver READS these
    endclocking

    // -------------------------------------------------------------------------
    // CLOCKING BLOCK for MONITOR
    // Monitor only READS — it never drives anything on the bus.
    // -------------------------------------------------------------------------
    clocking monitor_cb @(posedge clk);
        default input #1;
        input rst_n, start, tx_data;  // observe what driver sent
        input busy, done, rx_data;    // observe DUT responses
        input sclk, mosi, miso, cs_n; // observe raw SPI bus signals
    endclocking

    // -------------------------------------------------------------------------
    // MODPORTS — defines which "view" each component gets
    // Driver  sees: driver_cb  (can drive + read)
    // Monitor sees: monitor_cb (can only read)
    // -------------------------------------------------------------------------
    modport DRIVER  (clocking driver_cb,  input clk);
    modport MONITOR (clocking monitor_cb, input clk);

endinterface : spi_if
