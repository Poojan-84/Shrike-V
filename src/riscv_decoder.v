module riscv_decoder (
    input  wire [31:0] instr,   // Raw 32-bit instruction from memory
    
    // Extracted Fields
    output wire [6:0]  opcode,
    output wire [4:0]  rd,      // Destination Register
    output wire [4:0]  rs1,     // Source Register 1
    output wire [4:0]  rs2,     // Source Register 2
    output wire [2:0]  funct3,  // Function variant (e.g. ADD vs SUB)
    output wire [6:0]  funct7,  // Function variant (high bits)

    // Decoded Immediates (Sign Extended to 32-bits)
    output wire [31:0] imm_i,   // For I-Type (ADDI, LW, JALR)
    output wire [31:0] imm_s,   // For S-Type (SW)
    output wire [31:0] imm_b,   // For B-Type (BEQ, BNE)
    output wire [31:0] imm_u,   // For U-Type (LUI, AUIPC)
    output wire [31:0] imm_j    // For J-Type (JAL)
);

    // 1. Basic Field Extraction (These are always in the same place)
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // 2. Immediate Generation (Unscrambling & Sign Extension)
    // In Verilog, {{n{bit}}, value} repeats 'bit' n times (Sign Extension)

    // I-Type: imm[11:0] is at instr[31:20]
    assign imm_i = {{20{instr[31]}}, instr[31:20]};

    // S-Type: imm[11:5] at [31:25], imm[4:0] at [11:7]
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};

    // B-Type: Scrambled! imm[12] at [31], imm[10:5] at [30:25], imm[4:1] at [11:8], imm[11] at [7]
    // Note: Bit 0 is always 0 for branches (multiples of 2)
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

    // U-Type: imm[31:12] at [31:12]. Lower 12 bits are zero.
    assign imm_u = {instr[31:12], 12'b0};

    // J-Type: Scrambled! imm[20] at [31], imm[10:1] at [30:21], imm[11] at [20], imm[19:12] at [19:12]
    assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

endmodule
