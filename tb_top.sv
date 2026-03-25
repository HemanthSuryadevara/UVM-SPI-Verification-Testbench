// =============================================================================
// FILE: tb_top.sv
// WHAT: Testbench Top Module
// WHY:  This is the ONLY module in the entire testbench.
//       (Everything else is a class — driver, monitor, env, test, etc.)
//
//       tb_top is responsible for:
//         1. Generating the clock
//         2. Instantiating the interface (spi_if)
//         3. Instantiating the DUT (spi_master) and wiring it to interface
//         4. Putting the interface into config_db (so driver/monitor can get it)
//         5. Calling run_test() to start UVM
//
// WHY IS THIS A MODULE AND NOT A CLASS?
//   Modules exist in simulation time and can have signals, clocks, and DUT.
//   Classes are pure software — they can't generate clocks or hold wires.
//   You always need at least ONE module at the top to hold the hardware.
// =============================================================================

// Pull in UVM — must be done before any UVM class is used
`include "uvm_macros.svh"
import uvm_pkg::*;

// Include the interface (must be compiled before the module)
`include "spi_if.sv"

// Include the test — which pulls in env → agent → driver/monitor/scoreboard
`include "spi_test.sv"

// Include the DUT
`include "../rtl/spi_master.sv"

module tb_top;

    // =========================================================================
    // CLOCK GENERATION
    // Period = 10ns → Frequency = 100MHz
    // =========================================================================
    logic clk;
    initial  clk = 1'b0;
    always #5 clk = ~clk;  // toggle every 5ns = 10ns period


    // =========================================================================
    // INTERFACE INSTANTIATION
    // Create one instance of spi_if and connect the clock
    // =========================================================================
    spi_if spi_bus (.clk(clk));
    //     ^^^^^^^
    //     This is the instance name. config_db stores a handle to THIS instance.


    // =========================================================================
    // DUT INSTANTIATION
    // Wire the DUT's ports to the interface's signals
    // =========================================================================
    spi_master #(
        .DATA_WIDTH (8),   // 8-bit transfers
        .CLK_DIV    (4),   // SCLK = 100MHz / (2*4) = 12.5MHz
        .CPOL       (0),   // SPI Mode 0
        .CPHA       (0)
    ) dut (
        // System signals
        .clk      (clk),
        .rst_n    (spi_bus.rst_n),

        // Control interface
        .start    (spi_bus.start),
        .tx_data  (spi_bus.tx_data),
        .rx_data  (spi_bus.rx_data),
        .busy     (spi_bus.busy),
        .done     (spi_bus.done),

        // SPI bus signals
        .sclk     (spi_bus.sclk),
        .mosi     (spi_bus.mosi),
        .miso     (spi_bus.miso),
        .cs_n     (spi_bus.cs_n)
    );

    // =========================================================================
    // LOOPBACK CONNECTION
    // Wire MOSI directly to MISO. Whatever master sends, it receives back.
    // This lets scoreboard verify: tx_data == rx_data
    // In a real project you'd connect an actual SPI slave here instead.
    // =========================================================================
    assign spi_bus.miso = spi_bus.mosi;


    // =========================================================================
    // UVM SETUP — runs before simulation starts
    // =========================================================================
    initial begin

        // ---------------------------------------------------------------------
        // config_db::set — put the interface into the UVM database
        //
        // Arguments:
        //   null            = context (null = top level, accessible everywhere)
        //   "uvm_test_top*" = scope  (which components can access this)
        //   "spi_vif"       = key    (must EXACTLY match what driver/monitor use)
        //   spi_bus         = value  (the actual interface instance)
        //
        // Driver gets it with:
        //   uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif)
        // ---------------------------------------------------------------------
        uvm_config_db #(virtual spi_if)::set(
            null,
            "uvm_test_top*",
            "spi_vif",
            spi_bus
        );

        // ---------------------------------------------------------------------
        // run_test() — hands control over to UVM
        // UVM reads +UVM_TESTNAME from command line to decide which test to run
        // If no +UVM_TESTNAME given, uses the string passed here as default
        // ---------------------------------------------------------------------
        run_test("spi_basic_test");
    end


    // =========================================================================
    // TIMEOUT WATCHDOG
    // If simulation runs longer than 1ms, something is stuck — kill it.
    // Prevents infinite loops from hanging your computer.
    // =========================================================================
    initial begin
        #1_000_000; // 1ms in ns
        `uvm_fatal("TIMEOUT",
            "Simulation hit 1ms timeout! Check for infinite loop or stuck signal.")
    end

endmodule : tb_top
