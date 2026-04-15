# SPI Master Verification using UVM (VCS)

## 📌 Overview
This project implements and verifies an SPI (Serial Peripheral Interface) Master using SystemVerilog and UVM (Universal Verification Methodology).  
Simulation and verification are performed using Synopsys VCS in a Linux/MobaXterm environment.

## 🎯 Project Goals
- Design an SPI Master (RTL)
- Build a UVM-based verification environment
- Generate random transactions
- Verify functionality using a scoreboard
- Debug RTL and verification issues

## 🧱 Project Structure
.
rtl
├──├── spi_master.sv
├── spi_slave.sv
tb
├── spi_if.sv
├── spi_seq_item.sv
├── spi_sequence.sv
├── spi_sequencer.sv
├── spi_driver.sv
├── spi_monitor.sv
├── spi_agent.sv
├── spi_env.sv
├── spi_scoreboard.sv
├── spi_test.sv
├── spi_pkg.sv
├── tb_top.sv
├── run_vcs.sh
└── README.md

## ⚙️ Tools Used
- Synopsys VCS (U-2023.03-SP1)
- SystemVerilog
- UVM 1.2
- Linux / MobaXterm

## 🔁 SPI Protocol Summary
SPI is a full-duplex serial communication protocol using:
- SCLK – Serial clock
- MOSI – Master Out Slave In
- MISO – Master In Slave Out
- CS_N – Chip select (active low)

## 🔍 Verification Strategy
- Loopback configuration: MOSI → MISO
- Validation: TX Data == RX Data
- Random transactions are generated and verified.

## ▶️ How to Run
rm -rf simv simv.daidir csrc ucli.key *.log

vcs -full64 -sverilog \
  -ntb_opts uvm-1.2 \
  +incdir+. \
  spi_pkg.sv spi_master.sv spi_slave.sv tb_top.sv \
  -top tb_top \
  -debug_access+all \
  -o simv

./simv -no_save +UVM_TESTNAME=spi_basic_test +UVM_VERBOSITY=UVM_MEDIUM -l sim.log

## ✅ Results
SPI SCOREBOARD SUMMARY
PASS : 9
FAIL : 0

- All functional transactions passed  
- First transaction is used as a warm-up and is not checked  

## 🐞 Debugging Highlights
- Incorrect SCLK edge detection
- Bit-shift alignment error (RX = TX << 1)
- UVM include path issues
- DPI linking errors in VCS
- First transaction startup mismatch

## 💡 Key Learnings
- UVM architecture and flow  
- Debugging RTL timing issues  
- SPI protocol behavior  
- Integration of UVM with VCS  

## 🚀 Future Improvements
- Connect real SPI slave instead of loopback  
- Add functional coverage  
- Add multiple test cases  
- Add assertions (SVA)  

## 👨‍💻 Author
Student Project – SPI Master Verification using UVM

## 📜 License
Educational use only.
