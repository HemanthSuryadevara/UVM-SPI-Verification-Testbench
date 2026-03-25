// =============================================================================
// FILE: spi_driver.sv
// WHAT: SPI Driver
// WHY:  The driver is the "signal wiggler."
//       It receives seq_items from the sequencer and DRIVES them onto
//       the actual DUT signals through the virtual interface.
//
// ANALOGY: If the seq_item is a "work order form",
//          the driver is the technician who reads the form and
//          actually flips the switches on the hardware.
//
// HOW IT FITS IN UVM:
//   Sequencer  ──(seq_item)──►  Driver  ──(signals)──►  DUT
//
// NOTE: No import/include at top — handled by spi_pkg.sv
// =============================================================================

class spi_driver extends uvm_driver #(spi_seq_item);

    `uvm_component_utils(spi_driver)

    // -------------------------------------------------------------------------
    // Virtual Interface Handle
    // "virtual spi_if" = a handle (pointer) to the actual interface
    // that lives in tb_top. We get it from config_db in build_phase.
    // -------------------------------------------------------------------------
    virtual spi_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase
    // Runs BEFORE simulation starts. Used to get the interface.
    // config_db::get = "look up 'spi_vif' in the database and store it in vif"
    // tb_top puts it there with config_db::set
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual spi_if)::get(
                this,       // who is asking
                "",         // path (empty = search upward)
                "spi_vif",  // key name — must match what tb_top used
                vif))       // where to store the result
        begin
            `uvm_fatal("NO_VIF",
                "spi_driver: Failed to get spi_vif from config_db! Did tb_top call set()?")
        end
    endfunction

    // -------------------------------------------------------------------------
    // run_phase
    // This is where actual simulation work happens.
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        spi_seq_item item;

        // Initialize all output signals to safe defaults
        vif.driver_cb.rst_n   <= 1'b0;
        vif.driver_cb.start   <= 1'b0;
        vif.driver_cb.tx_data <= 8'h00;

        // Hold reset for 5 clock cycles
        repeat(5) @(vif.driver_cb);

        // Release reset
        vif.driver_cb.rst_n <= 1'b1;

        // Wait 2 more cycles for DUT to settle
        repeat(2) @(vif.driver_cb);

        // Main loop — runs for entire simulation
        forever begin
            // BLOCKS until sequencer has something for us
            seq_item_port.get_next_item(item);

            // Drive the transaction onto the DUT
            drive_one_transaction(item);

            // Tell sequencer: done, send next item
            seq_item_port.item_done();
        end
    endtask

    // -------------------------------------------------------------------------
    // drive_one_transaction — actual pin-wiggling for one SPI transfer
    // -------------------------------------------------------------------------
    task drive_one_transaction(spi_seq_item item);
        `uvm_info("SPI_DRV",
            $sformatf(">>> Starting transaction: %s", item.convert2string()),
            UVM_MEDIUM)

        // Step 1: Wait until DUT is not busy
        wait(vif.busy === 1'b0);

        // Step 2: Set up the data
        vif.driver_cb.tx_data <= item.tx_data;
        @(vif.driver_cb);

        // Step 3: Pulse start HIGH for 1 clock cycle
        vif.driver_cb.start <= 1'b1;
        @(vif.driver_cb);
        vif.driver_cb.start <= 1'b0;

        // Step 4: Wait for done pulse
        @(posedge vif.done);

        // Step 5: Read back received data
        @(vif.driver_cb);
        item.rx_data = vif.driver_cb.rx_data;

        `uvm_info("SPI_DRV",
            $sformatf("<<< Transaction done: RX=0x%02h", item.rx_data),
            UVM_MEDIUM)
    endtask

endclass : spi_driver
