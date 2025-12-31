module riscv_core (
    input  wire        clk,
    input  wire        rst_n,

    // --- SPI Interface (For "Sideloading" Code and Data) ---
    // Instruction Memory Port B (Write Only)
    input  wire        spi_imem_we,
    input  wire [31:0] spi_imem_addr,
    input  wire [31:0] spi_imem_data,
    
    // Data Memory Port B (Read Only for now, could be RW)
    input  wire [31:0] spi_dmem_addr,
    output wire [31:0] spi_dmem_data,
    
    // Debug
    output wire [31:0] debug_pc
);

    // --- Internal Signals ---
    reg  [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
    wire [31:0] pc_target;
    wire [31:0] instr;
    
    // Decoder Outputs
    wire [6:0]  opcode;
    wire [4:0]  rd, rs1, rs2;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    
    // Data Signals
    wire [31:0] src_a, src_b;
    wire [31:0] reg_rdata2; // Raw output from RegFile (before immediate mux)
    wire [31:0] alu_result;
    wire [31:0] dmem_rdata;
    wire [31:0] result_wb;  // Final value to write back to register
    wire        zero_flag;
    
    // Control Signals
    wire        pc_src;
    wire        result_src;
    wire        mem_write;
    wire [3:0]  alu_control;
    wire        alu_src;
    wire        reg_write;
    
    // --- 1. PC Logic ---
    assign pc_plus_4 = pc + 4;
    
    // If Branch/Jump taken, PC = Target. Else PC = PC+4.
    assign pc_next = (pc_src) ? pc_target : pc_plus_4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'd0;
        end else begin
            pc <= pc_next;
        end
    end
    
    assign debug_pc = pc; // Export for debugging

    // --- 2. Instruction Memory (IMEM) ---
    // Port A: CPU Read. Port B: SPI Write.
    dual_port_ram_32 #(.WORD_COUNT(256)) u_imem (
        .clk(clk),
        
        // CPU Port
        .we_a(1'b0),          // CPU never writes to IMEM
        .addr_a(pc),
        .wd_a(32'd0),
        .rd_a(instr),
        
        // SPI Port
        .we_b(spi_imem_we),
        .addr_b(spi_imem_addr),
        .wd_b(spi_imem_data),
        .rd_b()               // We don't read back IMEM via SPI for now
    );

    // --- 3. Decoder ---
    riscv_decoder u_dec (
        .instr(instr),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7),
        .imm_i(imm_i),
        .imm_s(imm_s),
        .imm_b(imm_b),
        .imm_u(imm_u),
        .imm_j(imm_j)
    );

    // --- 4. Control Unit ---
    riscv_control u_ctrl (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .zero(zero_flag),
        .pc_src(pc_src),
        .result_src(result_src),
        .mem_write(mem_write),
        .alu_control(alu_control),
        .alu_src(alu_src),
        .reg_write(reg_write)
    );

    // --- 5. Register File ---
    riscv_regfile u_rf (
        .clk(clk),
        .we3(reg_write),
        .a1(rs1),
        .a2(rs2),
        .a3(rd),
        .wd3(result_wb), // Data to write back
        .rd1(src_a),
        .rd2(reg_rdata2)
    );

    // --- 6. Execute Phase (ALU Muxes) ---
    
    // Immediate Selection Mux (Simplified for now)
    // In a full core, we select Imm based on instruction type.
    // For now, I-Type/Load uses Imm_I. Store uses Imm_S. Branch uses Imm_B.
    reg [31:0] imm_ext;
    always @(*) begin
        case(opcode)
            7'b0100011: imm_ext = imm_s; // Store
            7'b1100011: imm_ext = imm_b; // Branch
            default:    imm_ext = imm_i; // ALU Immediate / Load
        endcase
    end

    // ALU Src B Mux: Register B or Immediate?
    assign src_b = (alu_src) ? imm_ext : reg_rdata2;

    // Branch Target Calculation
    assign pc_target = pc + imm_ext;

    // ALU Instance
    riscv_alu u_alu (
        .a(src_a),
        .b(src_b),
        .alu_ctrl(alu_control),
        .result(alu_result),
        .zero(zero_flag)
    );

    // --- 7. Data Memory (DMEM) ---
    // Port A: CPU Read/Write. Port B: SPI Read.
    dual_port_ram_32 #(.WORD_COUNT(256)) u_dmem (
        .clk(clk),
        
        // CPU Port
        .we_a(mem_write),
        .addr_a(alu_result), // Address comes from ALU (e.g., base + offset)
        .wd_a(reg_rdata2),   // Data to store comes from Reg B
        .rd_a(dmem_rdata),
        
        // SPI Port (Debugger)
        .we_b(1'b0),         // SPI only reads data for now
        .addr_b(spi_dmem_addr),
        .wd_b(32'd0),
        .rd_b(spi_dmem_data)
    );

    // --- 8. Writeback Mux ---
    // Does the register get the ALU math result? Or data loaded from RAM?
    assign result_wb = (result_src) ? dmem_rdata : alu_result;

endmodule
