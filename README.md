# Shrike-V: 32-bit RISC-V (RV32I) Processor Implementation

Shrike-V is a modular, single-cycle RISC-V CPU implementation designed for FPGAs. It follows the **RV32I (Base Integer)** instruction set architecture, featuring a clean separation between the datapath and the control path. This project includes both the Verilog RTL for the processor and a MicroPython-based hardware bridge for program injection.

## 🚀 Key Features
* **Architecture:** 32-bit Harvard Architecture (Separate Instruction and Data Memory).
* **ISA:** Supports RV32I Base Integer Instruction Set (Arithmetic, Logical, Branching, and Load/Store).
* **Register File:** 32 general-purpose registers (x0-x31), with x0 hardwired to zero.
* **Bootloader:** Custom 5-byte SPI protocol for loading machine code into FPGA memory via an external host (ESP32).
* **Modularity:** Distinct modules for ALU, Decoder, ImmGen, and Register File for easy scaling.

---

## 🏗️ Architecture Overview

The Shrike-V core is organized into several functional blocks that handle the Fetch-Decode-Execute cycle:

| Module | Function |
| :--- | :--- |
| **PC.v** | Program Counter; manages the address of the current instruction. |
| **InstructionMem.v** | Read-only memory (ROM) that stores the 32-bit machine code. |
| **Decoder.v** | The "Brain"; parses opcodes and generates control signals for the ALU and Memory. |
| **RegFile.v** | 32-word register file with dual-read and single-write ports. |
| **ALU.v** | Performs 32-bit arithmetic (ADD, SUB) and logical (AND, OR, XOR, SLL) operations. |
| **ImmGen.v** | Extracts and sign-extends immediate values from I, S, B, U, and J-type instructions. |
| **DataMem.v** | RAM for data storage, accessed only via Load (`lw`) and Store (`sw`) instructions. |



---

## 🔄 Execution Flow

1.  **Fetch:** The `PC` provides the address to `InstructionMem`, which returns a 32-bit instruction.
2.  **Decode:** The `Decoder` identifies the instruction type and tells the `RegFile` which registers to read.
3.  **Execute:** The `ALU` receives operands from the `RegFile` or the `ImmGen` and performs the calculation.
4.  **Memory:** If the instruction is a Load or Store, the `ALU` output acts as a memory address for `DataMem`.
5.  **Writeback:** The final result (from the ALU or Memory) is written back to the destination register.

---

## 🛠️ Hardware-Software Bridge (Firmware)

Because FPGAs are volatile, Shrike-V uses an **ESP32 master** to "inject" code into the core via SPI. The provided MicroPython firmware implements a 5-byte protocol:

* **Byte 0:** 8-bit Target Memory Address.
* **Bytes 1-4:** 32-bit Instruction (Little-endian).

### Usage Example:
```python
# Create the tester interface
tester = SERVTester(spi_id=0, baudrate=1000000, cs_pin=5)

# Load a simple 'addi' program
program = [
    0x00A00513, # addi x10, x0, 10
    0x0000006F  # jal x0, 0 (Infinite Loop)
]
tester.load_program(program)
