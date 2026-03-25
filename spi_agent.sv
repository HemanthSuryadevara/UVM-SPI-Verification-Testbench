// =============================================================================
// FILE: spi_agent.sv
// WHAT: SPI Agent
// WHY:  The agent is a CONTAINER that bundles three components:
//         - sequencer  (queue manager)
//         - driver     (signal wiggler)
//         - monitor    (bus watcher)
//
// ACTIVE vs PASSIVE:
//   UVM_ACTIVE  = has sequencer + driver + monitor  (drives the DUT)
//   UVM_PASSIVE = has monitor ONLY                  (just observes)
//
// NOTE: No import/include at top — handled by spi_pkg.sv
// =============================================================================

class spi_agent extends uvm_agent;

    `uvm_component_utils(spi_agent)

    // Sub-component handles
    spi_sequencer sequencer;
    spi_driver    driver;
    spi_monitor   monitor;

    // Analysis port exposed at agent level — connects to scoreboard in env
    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase — create sub-components
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = spi_sequencer::type_id::create("sequencer", this);
            driver    = spi_driver::type_id::create("driver",       this);
        end

        // Monitor always created — even passive agents observe
        monitor = spi_monitor::type_id::create("monitor", this);
    endfunction

    // -------------------------------------------------------------------------
    // connect_phase — wire sub-components together
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);

        // Wire driver → sequencer
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);

        // Expose monitor's analysis port at agent level
        ap = monitor.ap;
    endfunction

endclass : spi_agent
