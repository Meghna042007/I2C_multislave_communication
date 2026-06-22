# I²C Multi-Slave Communication using Verilog

---

##  Project Overview

This project implements the **Inter-Integrated Circuit (I²C)** protocol completely in **Verilog HDL**, consisting of an **I²C Master**, **three independent I²C Slave devices**, and a **shared open-drain communication bus**.

The master communicates with multiple slaves through a common **SDA** and **SCL** bus. Every slave continuously monitors the bus and compares the received address with its own configured address. Only the slave whose address matches acknowledges the transaction and continues communication, while the remaining slaves return to the idle state.

The design supports both **write** and **read** transactions using **register addressing** and **Repeated START**, closely following the standard I²C communication protocol.

The entire design has been verified through simulation in **Xilinx Vivado**.

---

#  Features

-  I²C Master Implementation
-  I²C Slave Implementation
-  7-bit Slave Addressing
-  Register Addressing
-  Write Transactions
-  Read Transactions
-  Repeated START Support
-  ACK/NACK Generation
-  Shared SDA/SCL Bus
-  Open-Drain SDA Implementation
-  Multi-Slave Communication
-  Independent Register Storage
-  Comprehensive Testbench Verification

---

# Project Architecture

```
                         +---------------------+
                         |     I²C Master      |
                         +---------------------+
                                   |
                          Shared SDA / SCL Bus
                                   |
      -------------------------------------------------------------
      |                           |                              |
+----------------+        +----------------+         +----------------+
|    Slave 1     |        |    Slave 2     |         |    Slave 3     |
| Address : 4D   |        | Address : 35   |         | Address : 62   |
+----------------+        +----------------+         +----------------+
```

Each slave contains its own register memory and only participates in communication when its configured slave address matches the address transmitted by the master.

---

# Modules

## 1. I²C Master

Responsible for

- Generating SCL
- Generating START condition
- Generating STOP condition
- Sending Slave Address
- Sending Register Address
- Writing Data
- Reading Data
- Generating Repeated START
- Receiving ACK/NACK
- Sending NACK after Read

---

## 2. I²C Slave

Each slave

- Monitors SDA and SCL
- Detects START condition
- Receives Slave Address
- Performs Address Comparison
- Generates ACK
- Stores Incoming Data
- Supports Register Addressing
- Transmits Stored Data
- Detects NACK
- Returns to Idle after Transaction

---

## 3. Top Module

The Top Module instantiates

- One I²C Master
- Three Independent I²C Slaves

All slave devices communicate using a common

- SDA
- SCL

bus exactly as defined by the I²C protocol.

---

#  Slave Address Configuration

| Slave | 7-bit Address | Write Address | Read Address |
|-------|---------------|---------------|--------------|
| Slave 1 | `7'h4D` | `8'h9A` | `8'h9B` |
| Slave 2 | `7'h35` | `8'h6A` | `8'h6B` |
| Slave 3 | `7'h62` | `8'hC4` | `8'hC5` |

---

#  Register Organization

Each slave contains **three independent 8-bit registers.**

| Register | Address |
|----------|---------|
| Register 0 | `2'b00` |
| Register 1 | `2'b01` |
| Register 2 | `2'b10` |

---

#  Supported Transactions

## Write Transaction

```
START
   │
   ▼
Slave Address + Write
   │
   ▼
ACK
   │
   ▼
Register Address
   │
   ▼
ACK
   │
   ▼
Data Byte
   │
   ▼
ACK
   │
   ▼
STOP
```

---

## Read Transaction

```
START
   │
   ▼
Slave Address + Write
   │
   ▼
ACK
   │
   ▼
Register Address
   │
   ▼
ACK
   │
   ▼
Repeated START
   │
   ▼
Slave Address + Read
   │
   ▼
ACK
   │
   ▼
Slave Transmits Data
   │
   ▼
Master Sends NACK
   │
   ▼
STOP
```

---

#  Open-Drain Bus Implementation

The SDA line is implemented as an **open-drain bidirectional bus**.

The line is pulled HIGH using a pull-up resistor while both the master and slave devices only drive the line LOW whenever required.

```verilog
assign SDA = sda_en ? 1'b0 : 1'bz;
pullup(SDA);
```

This closely models practical I²C hardware behavior.

---

#  Address Matching

During every transaction

- All slave devices monitor the incoming slave address.
- Each slave compares the received address with its configured address.
- Only the matching slave acknowledges the transaction.
- The remaining slaves immediately return to the Idle state without participating further.

This allows multiple slave devices to share a common communication bus.

---

#  Testbench Verification

The testbench performs multiple write and read transactions across three independent slave devices.

## Write Transactions

| Transaction | Operation |
|-------------|-----------|
| Transaction 1 | Write **0xA6** to **Slave 2**, Register **1** |
| Transaction 2 | Write **0xC5** to **Slave 1**, Register **2** |
| Transaction 3 | Write **0xB3** to **Slave 3**, Register **0** |

---

## Read Transactions

| Transaction | Expected Data |
|-------------|---------------|
| Transaction 4 | Read **0xA6** from Slave 2 Register 1 |
| Transaction 5 | Read **0xC5** from Slave 1 Register 2 |
| Transaction 6 | Read **0xB3** from Slave 3 Register 0 |

---

#  Simulation Results

The simulation successfully verifies:

-  Correct START condition generation
-  Correct STOP condition generation
-  7-bit slave address transmission
-  Register address transmission
-  ACK generation by the selected slave
-  NACK generation by the master after read
-  Repeated START operation
-  Correct write transactions
-  Correct read transactions
-  Independent register storage
-  Multi-slave communication
-  Shared SDA/SCL bus operation
-  Open-drain SDA implementation

---

#  Waveform Explanation

The simulation waveform demonstrates the complete communication flow between the master and three slave devices.


The waveform confirms that

- All slave devices monitor every slave address transmitted on the bus.
- Only the addressed slave acknowledges the communication.
- Non-selected slaves immediately return to the idle state.
- Previously written data is successfully read back by the master.
- Each slave maintains its own independent register memory.

---

#  Design Highlights

- Finite State Machine (FSM) based design
- Modular architecture
- Parameterized slave addresses
- Shared open-drain communication bus
- Register-based memory organization
- Separate Master and Slave RTL modules
- Multi-slave support using a common bus
- Fully verified through simulation

---

#  Learning Outcomes

This project helped strengthen the understanding of

- Finite State Machine Design
- Verilog RTL Development
- Open-Drain Bus Architecture
- Bidirectional Signal Handling
- Timing Synchronization
- Register-Based Communication
- Multi-Slave Bus Communication
- I²C Protocol Implementation
- RTL Debugging and Verification

---

#  Notes

- SDA is implemented as an **open-drain bidirectional line** using tri-state logic.
- SCL is generated by the I²C Master.
- Each slave stores data independently.
- Multiple slave devices communicate over a shared bus.
- Repeated START is used during read transactions.
- The design has been successfully synthesized and verified through simulation.

---

#  Author

**Meghna Kar**  
B.Tech Electronics & Communication Engineering (ECE)

This project was developed as part of an RTL Design learning journey focused on digital communication protocols, finite state machine design, and Verilog HDL implementation.
