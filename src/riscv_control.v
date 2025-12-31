module riscv_control (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    input  wire       zero,      // From ALU
    
    output wire       pc_src,    // 0: PC+4, 1: Branch Target
    output wire       result_src,// 0: ALU Result, 1: Memory Read Data
    output wire       mem_write, // Write to Data Memory
    output wire [3:0] alu_control,
    output wire       alu_src,   // 0: Register B, 1: Immediate
    output wire       imm_src,   // (Not used directly in logic, implied by type)
    output wire       reg_write  // Write to Register File
);

    // Opcode Definitions
    localparam OP_R_TYPE = 7'b0110011; // ADD, SUB, etc.
    localparam OP_I_TYPE = 7'b0010011; // ADDI, ANDI, etc.
    localparam OP_LOAD   = 7'b0000011; // LW
    localparam OP_STORE  = 7'b0100011; // SW
    localparam OP_BRANCH = 7'b1100011; // BEQ

    // Main Control Decoder
    // Assign control signals based on Opcode
    
    assign reg_write  = (opcode == OP_R_TYPE) || (opcode == OP_I_TYPE) || (opcode == OP_LOAD);
    assign alu_src    = (opcode == OP_I_TYPE) || (opcode == OP_LOAD)   || (opcode == OP_STORE);
    assign mem_write  = (opcode == OP_STORE);
    assign result_src = (opcode == OP_LOAD); // If 1, data comes from RAM. If 0, from ALU.

    // Branch Logic: PC Source is 1 (Jump) if this is a Branch Op AND the Zero flag matches expectations
    // For simplicity, we only implement BEQ (Branch if Equal) for now.
    // If Op is BRANCH and Zero is 1 (Equal), then we take the branch.
    assign pc_src = (opcode == OP_BRANCH) && (zero == 1'b1);

    // ALU Control Decoder
    reg [3:0] alu_ctrl_temp;
    assign alu_control = alu_ctrl_temp;

    always @(*) begin
        case(opcode)
            OP_LOAD, OP_STORE: alu_ctrl_temp = 4'b0000; // Force ADD (Address calculation)
            OP_BRANCH:         alu_ctrl_temp = 4'b0001; // Force SUB (Comparison)
            
            OP_R_TYPE: begin // R-Type (ADD, SUB, AND, OR, SLT...)
                case(funct3)
                    3'b000: alu_ctrl_temp = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB if f7[5]=1, else ADD
                    3'b001: alu_ctrl_temp = 4'b0010; // SLL
                    3'b010: alu_ctrl_temp = 4'b0011; // SLT
                    3'b100: alu_ctrl_temp = 4'b0101; // XOR
                    3'b101: alu_ctrl_temp = (funct7[5]) ? 4'b0111 : 4'b0110; // SRA if f7[5]=1, else SRL
                    3'b110: alu_ctrl_temp = 4'b1000; // OR
                    3'b111: alu_ctrl_temp = 4'b1001; // AND
                    default: alu_ctrl_temp = 4'b0000;
                endcase
            end
            
            OP_I_TYPE: begin // I-Type (ADDI, XORI, etc.)
                case(funct3)
                    3'b000: alu_ctrl_temp = 4'b0000; // ADDI
                    3'b010: alu_ctrl_temp = 4'b0011; // SLTI
                    3'b100: alu_ctrl_temp = 4'b0101; // XORI
                    3'b110: alu_ctrl_temp = 4'b1000; // ORI
                    3'b111: alu_ctrl_temp = 4'b1001; // ANDI
                    // Note: SLLI/SRLI/SRAI need funct7 checks too, simplified here
                    default: alu_ctrl_temp = 4'b0000;
                endcase
            end
            default: alu_ctrl_temp = 4'b0000;
        endcase
    end

endmodule
