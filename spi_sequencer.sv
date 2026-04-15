// =============================================================================
// FILE: spi_sequencer.sv
// WHAT: SPI Sequencer
// WHY:  The sequencer is a "queue manager" that sits between the
//       sequence (which creates transactions) and the driver
//       (which consumes transactions).
//
// ANALOGY: The sequencer is like a conveyor belt between a chef
//          (sequence) who prepares dishes and a waiter (driver)
//          who delivers them to the table (DUT).
//
// DO I NEED TO WRITE ANY LOGIC HERE?
//   NO! uvm_sequencer already handles all queuing internally.
//   You just extend it and register it with the factory.
//
// NOTE: No import/include at top — handled by spi_pkg.sv
// =============================================================================

class spi_sequencer extends uvm_sequencer #(spi_seq_item);
    //                                      ^^^^^^^^^^^^
    //             tells UVM what type of items this sequencer handles

    `uvm_component_utils(spi_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Nothing else needed!
    // uvm_sequencer gives us everything for free.

endclass : spi_sequencer
