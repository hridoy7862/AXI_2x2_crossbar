# AXI4 2×2 Crossbar

A synthesizable and FPGA-validated **2-Master × 2-Slave AXI4 Crossbar** implemented in SystemVerilog.  
The design provides independent AXI channel handling, address-based routing, round-robin arbitration, response routing, buffering, backpressure handling, and error-response generation.

---

## 📌 Project Overview

This project implements a **2×2 AXI4 Crossbar** that connects:

- **2 AXI Masters**
- **2 AXI Slaves**

The crossbar independently handles all five AXI4 channels:

- **AW** — Write Address
- **W** — Write Data
- **B** — Write Response
- **AR** — Read Address
- **R** — Read Data

The design performs address-based routing between masters and slaves while allowing multiple masters to access different slaves concurrently.

The design was developed in **SystemVerilog**, verified using a **class-based SystemVerilog verification environment**, and synthesized and validated on a **Digilent ZedBoard FPGA**.

---

# 🏗️ Top-Level Architecture

The following diagram shows the complete architecture of the AXI4 Crossbar.
<img width="1872" height="1862" alt="Untitled Diagram-top_level_architecture" src="https://github.com/user-attachments/assets/f8a8e374-dec1-4dd4-b70a-8ff14458662b" />



### Main architectural components

- Master-side AW, W and AR FIFOs
- Address decoders
- Round-robin arbiters
- Write-channel controllers
- Read-channel controllers
- AW-to-W order tracking
- Write-data routing
- B-response FIFOs
- R-response FIFOs
- Response routing
- Master-ID tagging and stripping
- Dummy slave paths for error responses

---

# 🔑 Key Features

### AXI4 Connectivity

- 2 AXI Master interfaces
- 2 AXI Slave interfaces
- Independent handling of all five AXI channels
- Separate read and write paths

### Address-Based Routing

The crossbar decodes the address of each AW/AR transaction and determines the target slave.

```text
Master
   │
   ▼
Address Decoder
   │
   ├──► Slave 0
   │
   └──► Slave 1
