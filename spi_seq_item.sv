// =============================================================================
// FILE: spi_seq_item.sv
// WHAT: SPI Transaction (Sequence Item)
// WHY:  A seq_item is one "packet" of data — it represents ONE complete
//       SPI transaction. Think of it like a filled-in form:
//         "Send tx_data=0xA5 with CPOL=0, CPHA=0"
//
// HOW IT FITS:
//   Sequence CREATES seq_items  →  Sequencer QUEUES them
//   →  Driver RECEIVES them and drives DUT signals
//   →  Monitor CAPTURES results back into rx_data
//
// NOTE: No import/include at top — this file is included inside spi_pkg.sv
//       which already handles all UVM imports.
// =============================================================================

class spi_seq_item extends uvm_sequence_item;

    // -------------------------------------------------------------------------
    // UVM Factory Registration
    // This macro registers the class so UVM can create it with
    // type_id::create() — required in every UVM class
    // -------------------------------------------------------------------------
    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(tx_data, UVM_ALL_ON)  // auto-enables print/copy/compare
        `uvm_field_int(rx_data, UVM_ALL_ON)
        `uvm_field_int(cpol,    UVM_ALL_ON)
        `uvm_field_int(cpha,    UVM_ALL_ON)
    `uvm_object_utils_end

    // -------------------------------------------------------------------------
    // Fields
    // "rand" = UVM randomization engine can randomize this field
    // No "rand" = fixed value, set manually
    // -------------------------------------------------------------------------
    rand logic [7:0] tx_data;  // byte to send — randomized each transaction
         logic [7:0] rx_data;  // byte received back — filled in by driver
    rand logic       cpol;     // SPI clock polarity: 0=idle low, 1=idle high
    rand logic       cpha;     // SPI clock phase:    0=sample on 1st edge

    // -------------------------------------------------------------------------
    // Constraints
    // Rules that guide randomization. Without these, cpol/cpha would be
    // random — we lock them to mode 0 (most common) for simplicity.
    // -------------------------------------------------------------------------
    constraint spi_mode0_c {
        cpol == 1'b0;  // always use mode 0
        cpha == 1'b0;
    }

    // -------------------------------------------------------------------------
    // Constructor — always required in UVM objects
    // -------------------------------------------------------------------------
    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction

    // -------------------------------------------------------------------------
    // convert2string — UVM calls this when printing the item
    // -------------------------------------------------------------------------
    function string convert2string();
        return $sformatf(
            "TX=0x%02h  RX=0x%02h  CPOL=%0b  CPHA=%0b",
            tx_data, rx_data, cpol, cpha
        );
    endfunction

endclass : spi_seq_item
