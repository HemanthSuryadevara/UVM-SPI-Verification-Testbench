// =============================================================================
// FILE: spi_pkg.sv
// WHAT: SPI Package
// WHY:  A package bundles all SPI UVM classes into one importable unit.
//       Instead of including 7 separate files in every file that needs them,
//       you just write:  import spi_pkg::*;
//
// ORDER MATTERS inside a package!
//   Each file may depend on the ones above it, so include in this order:
//   seq_item → sequencer → driver → monitor → scoreboard → agent → env → test
// =============================================================================

package spi_pkg;

    // Always import UVM first
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Include files in dependency order
    `include "spi_seq_item.sv"    // no dependencies
    `include "spi_sequencer.sv"   // needs seq_item
    `include "spi_driver.sv"      // needs seq_item
    `include "spi_monitor.sv"     // needs seq_item
    `include "spi_scoreboard.sv"  // needs seq_item
    `include "spi_agent.sv"       // needs sequencer + driver + monitor
    `include "spi_env.sv"         // needs agent + scoreboard
    `include "spi_sequence.sv"    // needs seq_item
    `include "spi_test.sv"        // needs env + sequence

endpackage : spi_pkg

// =============================================================================
// HOW TO USE THIS PACKAGE in another file:
//
//   import uvm_pkg::*;
//   import spi_pkg::*;
//
//   // Now you can use spi_driver, spi_env, spi_basic_test etc. directly
// =============================================================================
