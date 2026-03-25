// =============================================================================
// FILE: spi_env.sv
// WHAT: SPI Environment
// WHY:  The environment is the TOP-LEVEL UVM container.
//       It holds the agent and scoreboard and wires them together.
//
// HOW THE CONNECTION WORKS:
//   agent.ap  ──connect()──►  scoreboard.analysis_export
//   After connect_phase, every time monitor calls ap.write(item),
//   the item flows into scoreboard's write() automatically.
//
// NOTE: No import/include at top — handled by spi_pkg.sv
// =============================================================================

class spi_env extends uvm_env;

    `uvm_component_utils(spi_env)

    spi_agent      agent;
    spi_scoreboard scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // build_phase — create agent and scoreboard
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = spi_agent::type_id::create("agent",      this);
        scoreboard = spi_scoreboard::type_id::create("scoreboard", this);
    endfunction

    // -------------------------------------------------------------------------
    // connect_phase — wire monitor output → scoreboard input
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        agent.ap.connect(scoreboard.analysis_export);
    endfunction

endclass : spi_env
