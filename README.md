# AXI4 2×2 Crossbar

A synthesizable and FPGA-validated **2-Master × 2-Slave AXI4 Crossbar** written in SystemVerilog. The project features independent 5-channel routing, round-robin arbitration, backpressure handling, and hardware validation on the Digilent ZedBoard.

---

## 📌 Project Overview

This project implements an interconnect connecting 2 AXI4 Masters to 2 AXI4 Slaves. It supports independent channel execution, multiple in-flight transactions, backpressure using VALID/READY handshaking, and automatic DECERR generation for invalid addresses.


<img width="1872" height="1862" alt="Untitled Diagram-top_level_architecture" src="https://github.com/user-attachments/assets/824785c0-a0da-413b-9744-deff692dd0e8" />

---

## 🏗️ Top-Level Architecture

The crossbar decouples the five standard AXI4 channels:
* **Write Channels:** AW (Write Address), W (Write Data), B (Write Response)
* **Read Channels:** AR (Read Address), R (Read Data)

**Core Components:**
* **FIFOs:** Master-side buffering across all channels.
* **Address Decoders:** Route AW/AR requests based on target address maps.
* **Arbiters:** Round-robin selection for competing requests.
* **Controllers & Trackers:** Maintain AW-to-W ordering, ID tagging, and response routing.

---

## ✍️ Write Path & Routing

<img width="1402" height="1401" alt="Untitled Diagram-write_path" src="https://github.com/user-attachments/assets/ccce190d-60ac-4c67-b036-98035cd228d2" />


1. **AW Channel:** Master requests are buffered, decoded to identify target slaves, and arbitrated via round-robin policy before reaching the selected slave.
2. **AW-to-W Tracking:** Captures target slave selection and burst metadata to guide data routing.
3. **W Channel:** Uses tracked metadata to route write data beats to the correct slave without requiring addresses.
4. **B Channel:** Appends Master-ID tags to transactions; routes completion responses back to the originating master using BID tracking.

---

## 📖 Read Path & Routing

<img width="1402" height="1241" alt="Untitled Diagram-Read_path" src="https://github.com/user-attachments/assets/3b379518-cfac-455d-92a3-836d5696e623" />


1. **AR Channel:** Buffered read address requests are decoded and arbitrated via round-robin access toward the target slave.
2. **R Channel:** Reads are executed at the slave, and read data/responses are routed back using tagged ARIDs to return data accurately to the requesting master.

---

## 🧪 Verification & Test Cases

The RTL was verified using a modular **SystemVerilog class-based testbench** containing a Generator, Driver, Monitor, Scoreboard, and Reference Model.

### Key Test Cases Verified:
* **Cross-Routing:** `M0 → S0`, `M0 → S1`, `M1 → S0`, and `M1 → S1` access paths.
* **Arbitration:** Concurrent master requests to identical slaves (fairness check).
* **Backpressure & FIFOs:** Downstream stall behavior with full/empty FIFO boundaries.
* **Burst Transactions:** Multi-beat write and read transaction integrity.
* **Error Handling:** Out-of-bounds address requests generating `DECERR` responses.

---

## 🛠️ FPGA Hardware Implementation

* **Board:** Digilent ZedBoard (Xilinx Zynq-7000 XC7Z020)
* **Clock:** 100 MHz
* **Toolchain:** AMD/Xilinx Vivado (Synthesis, Implementation, ILA/VIO Validation)

---

## 👨‍💻 Author

**Md. Reajul Karim Hridoy**  
B.Sc. in Electrical & Electronic Engineering  
Rajshahi University of Engineering & Technology (RUET), Bangladesh
