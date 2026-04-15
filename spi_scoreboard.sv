// =============================================================================
// FILE: spi_scoreboard.sv
// WHAT: SPI Scoreboard
// WHY:  The scoreboard is the "answer checker."
//       It receives completed transactions from the monitor and verifies
//       that the DUT behaved correctly.
//
// HOW IT RECEIVES DATA:
//   Monitor calls ap.write(item) → flows here → calls write() automatically
//   You never call write() yourself — UVM calls it for you!
//
// WHAT WE CHECK (loopback test):
//   MOSI is wired to MISO in tb_top → tx_data must equal rx_data
//
// NOTE: No import/include at top — handled by spi_pkg.sv
// =============================================================================

class spi_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) analysis_export;

    int pass_count = 0;
    int fail_count = 0;
    int txn_count  = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
    endfunction

    function void write(spi_seq_item item);
        txn_count++;

        // Ignore first warm-up transaction
        if (txn_count == 1) begin
            `uvm_info("SPI_SBD",
                $sformatf("Skipping warm-up transaction: TX=0x%02h RX=0x%02h",
                    item.tx_data, item.rx_data),
                UVM_LOW)
            return;
        end

        `uvm_info("SPI_SBD",
            $sformatf("Checking: %s", item.convert2string()),
            UVM_MEDIUM)

        if (item.tx_data === item.rx_data) begin
            `uvm_info("SPI_SBD",
                $sformatf("PASS ✓  TX=0x%02h matched RX=0x%02h",
                    item.tx_data, item.rx_data),
                UVM_LOW)
            pass_count++;
        end
        else begin
            `uvm_error("SPI_SBD",
                $sformatf("FAIL ✗  TX=0x%02h did NOT match RX=0x%02h",
                    item.tx_data, item.rx_data))
            fail_count++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SPI_SBD",
            $sformatf("\n=============================\n  SPI SCOREBOARD SUMMARY\n  PASS : %0d\n  FAIL : %0d\n=============================",
                pass_count, fail_count),
            UVM_NONE)

        if (fail_count > 0)
            `uvm_error("SPI_SBD", "*** SPI TEST FAILED — see errors above ***")
        else
            `uvm_info("SPI_SBD", "*** ALL SPI CHECKS PASSED! ***", UVM_NONE)
    endfunction

endclass : spi_scoreboard