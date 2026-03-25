// =============================================================================
// FILE: spi_monitor.sv
// WHAT: SPI Monitor
// WHY:  The monitor is a PASSIVE observer — it watches the bus silently
//       and never drives any signals. Every time it sees a complete
//       transaction, it creates a seq_item and sends it to the scoreboard.
//
// KEY RULE: The monitor NEVER drives signals.
//
// HOW IT CONNECTS TO SCOREBOARD:
//   Monitor  ──(ap.write)──►  Analysis Port  ──►  Scoreboard
//
// NOTE: No import/include at top — handled by spi_pkg.sv
// =============================================================================

class spi_monitor extends uvm_monitor;

    `uvm_component_utils(spi_monitor)

    // Virtual interface — monitor only uses monitor_cb (read only)
    virtual spi_if vif;

    // -------------------------------------------------------------------------
    // Analysis Port — monitor's output channel to the scoreboard
    // When monitor calls ap.write(item), scoreboard receives it automatically
    // -------------------------------------------------------------------------
    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase — create analysis port and get interface
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual spi_if)::get(this, "", "spi_vif", vif))
            `uvm_fatal("NO_VIF", "spi_monitor: Failed to get spi_vif!")
    endfunction

    // -------------------------------------------------------------------------
    // run_phase — watch the bus forever
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        spi_seq_item item;

        forever begin
            // Step 1: Wait for transaction to START — CS_N goes LOW
            @(negedge vif.cs_n);

            // Create a fresh seq_item
            item = spi_seq_item::type_id::create("mon_item");

            // Step 2: Capture tx_data
            @(vif.monitor_cb);
            item.tx_data = vif.monitor_cb.tx_data;

            // Step 3: Wait for transaction to END — CS_N goes HIGH
            @(posedge vif.cs_n);
            @(vif.monitor_cb);

            // Step 4: Capture rx_data
            item.rx_data = vif.monitor_cb.rx_data;

            `uvm_info("SPI_MON",
                $sformatf("Observed transaction: %s", item.convert2string()),
                UVM_MEDIUM)

            // Step 5: Send to scoreboard
            ap.write(item);
        end
    endtask

endclass : spi_monitor
