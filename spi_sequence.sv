// =============================================================================
// FILE: spi_sequence.sv
// WHAT: SPI Sequence
// WHY:  The sequence is where your TEST STIMULUS lives.
//       It creates seq_items, randomizes them, and sends them to
//       the driver via the sequencer.
//
// HOW TO SEND AN ITEM (3 steps always):
//   1. start_item(item)   — "I have an item ready to send"
//   2. item.randomize()   — fill it with random (or specific) values
//   3. finish_item(item)  — "send it!" — BLOCKS until driver is done
//
// NOTE: No import/include at top — handled by spi_pkg.sv
// =============================================================================

// =============================================================================
// BASE SEQUENCE — sends N random transactions
// =============================================================================
class spi_base_sequence extends uvm_sequence #(spi_seq_item);

    `uvm_object_utils(spi_base_sequence)

    int unsigned num_transactions = 10;

    function new(string name = "spi_base_sequence");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;

        `uvm_info("SPI_SEQ",
            $sformatf("Starting: will send %0d transactions", num_transactions),
            UVM_LOW)

        repeat(num_transactions) begin

            // Step 1: Create item
            item = spi_seq_item::type_id::create("item");

            // Step 2: Reserve slot in sequencer
            start_item(item);

            // Step 3: Randomize — fills tx_data randomly, cpol/cpha stay 0
            if (!item.randomize())
                `uvm_fatal("RAND_FAIL", "Randomization failed!")

            // Step 4: Send to driver — BLOCKS until driver calls item_done()
            finish_item(item);

            `uvm_info("SPI_SEQ",
                $sformatf("Sent item: %s", item.convert2string()),
                UVM_MEDIUM)
        end

        `uvm_info("SPI_SEQ", "All transactions sent!", UVM_LOW)
    endtask

endclass : spi_base_sequence


// =============================================================================
// DIRECTED SEQUENCE — sends specific corner-case values
// =============================================================================
class spi_directed_sequence extends uvm_sequence #(spi_seq_item);

    `uvm_object_utils(spi_directed_sequence)

    function new(string name = "spi_directed_sequence");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;

        logic [7:0] test_values[] = '{
            8'h00,   // all zeros
            8'hFF,   // all ones
            8'hA5,   // alternating 1010_0101
            8'h5A,   // alternating 0101_1010
            8'h01,   // only LSB
            8'h80    // only MSB
        };

        foreach (test_values[i]) begin
            item = spi_seq_item::type_id::create("item");
            start_item(item);

            // Manually set values — no randomize
            item.tx_data = test_values[i];
            item.cpol    = 1'b0;
            item.cpha    = 1'b0;

            finish_item(item);

            `uvm_info("SPI_DIR_SEQ",
                $sformatf("Sent directed: TX=0x%02h", item.tx_data),
                UVM_MEDIUM)
        end
    endtask

endclass : spi_directed_sequence
