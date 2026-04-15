#!/bin/bash

rm -rf simv simv.daidir csrc ucli.key *.log

vcs -full64 -sverilog \
  -ntb_opts uvm-1.2 \
  +incdir+. \
  spi_pkg.sv spi_master.sv spi_slave.sv tb_top.sv \
  -top tb_top \
  -debug_access+all \
  -o simv

./simv -no_save +UVM_TESTNAME=spi_basic_test +UVM_VERBOSITY=UVM_MEDIUM -l sim.log
