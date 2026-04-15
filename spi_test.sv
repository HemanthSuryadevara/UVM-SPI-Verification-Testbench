// =============================================================================
// FILE: spi_test.sv
// WHAT: SPI Test
// WHY:  The test is the top-level UVM class. It:
//         1. Creates the environment (which creates everything else)
//         2. Starts the sequence running
//         3. Controls when simulation ends (raise/drop objection)
//
// HOW TO RUN:
//   xrun ... +UVM_TESTNAME=spi_basic_test
//   xrun ... +UVM_TESTNAME=spi_directed_test
//
// RAISE/DROP OBJECTION:
//   raise_objection = "don't end sim yet, I'm working"
//   drop_objection  = "I'm done, sim can end now"
//
// NOTE: No import/include at top — handled by spi_pkg.sv
// =============================================================================

// =============================================================================
// BASIC TEST — sends 10 random transactions
// =============================================================================
class spi_basic_test extends uvm_test;

    `uvm_component_utils(spi_basic_test)

    spi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        spi_base_sequence seq;

        phase.raise_objection(this);

        `uvm_info("SPI_TEST", "=== SPI Basic Test Starting ===", UVM_NONE)

        seq = spi_base_sequence::type_id::create("seq");
        seq.num_transactions = 10;
        seq.start(env.agent.sequencer);

        #100;

        `uvm_info("SPI_TEST", "=== SPI Basic Test Done ===", UVM_NONE)

        phase.drop_objection(this);
    endtask

endclass : spi_basic_test


// =============================================================================
// DIRECTED TEST — tests corner-case values
// =============================================================================
class spi_directed_test extends uvm_test;

    `uvm_component_utils(spi_directed_test)

    spi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        spi_directed_sequence seq;

        phase.raise_objection(this);

        `uvm_info("SPI_TEST", "=== SPI Directed Test Starting ===", UVM_NONE)

        seq = spi_directed_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        #100;

        `uvm_info("SPI_TEST", "=== SPI Directed Test Done ===", UVM_NONE)

        phase.drop_objection(this);
    endtask

endclass : spi_directed_test
