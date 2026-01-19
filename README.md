# Shrike-V: 32-bit Single-Cycle RISC-V Processor

Shrike-V is a high-performance, open-source implementation of the **RISC-V RV32I Base Integer Instruction Set**. Designed with a focus on modularity and educational clarity, this processor follows a single-cycle execution model where every instruction—from arithmetic to memory access—is completed in one clock pulse.

##  Core Architecture (The `src` Breakdown)

The processor is divided into distinct functional units, mirroring the standard RISC-V datapath. Each module in the `src` directory handles a critical part of the CPU's lifecycle:

### 1. Instruction Fetch & Decode
* **`InstructionMem.v`**: The primary storage for machine code. It outputs a 32-bit instruction based on the current PC.
* **`Decoder.v`**: The control center. It parses the 7-bit opcode, `funct3`, and `funct7` fields to determine the execution path.
* **`ImmGen.v`**: A dedicated unit to handle immediate values. It unscrambles and sign-extends bits for I-type (immediates), S-type (stores), and B-type (branches) instructions.

### 2. Execution & Arithmetic
* **`ALU.v`**: The computational engine. It performs addition, subtraction, logical shifts (SLL, SRL, SRA), and comparisons (SLT, SLTU).
* **`RegFile.v`**: Implements the 32 general-purpose registers (`x0` through `x31`). It supports dual asynchronous reads and a single synchronous write, with `x0` hardwired to zero.

### 3. Memory & System Control
* **`DataMem.v`**: Handles data persistence. It is accessed exclusively by Load and Store instructions, interfacing with the ALU for address calculation.
* **`ControlUnit.v`**: Generates the enable signals (RegWrite, MemWrite, ALUSrc) that coordinate data movement across the chip.

---

##  Instruction Execution Flow

The Shrike-V datapath follows a strictly linear, single-cycle flow:



1.  **Fetch**: The Program Counter (PC) pulls a 32-bit instruction from `InstructionMem`.
2.  **Decode**: The `Decoder` breaks down the instruction and the `RegFile` fetches the source operands.
3.  **Execute**: The `ALU` calculates the result or memory address based on signals from the `ControlUnit`.
4.  **Memory Access**: Data is read from or written to `DataMem` if the opcode is a Load or Store.
5.  **Writeback**: The final result is muxed and written back to the `RegFile` at the rising edge of the clock.

---

##  Hardware-Software Integration

To facilitate testing on FPGA hardware (like the Shrike Lite board), the project includes a **MicroPython-based Bridge**. This allows an external controller to:
* **Reset** the CPU state.
* **Inject** 32-bit instructions directly into the instruction memory.
* **Verify** execution by monitoring memory-mapped registers.

### Sample Test Instruction:
```assembly
# Machine Code: 0x00A00513 
addi x10, x0, 10  # Load decimal 10 into register x10
