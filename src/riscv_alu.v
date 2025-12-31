module riscv_alu (
    input  wire [31:0] a,          // Source A (usually RS1)
    input  wire [31:0] b,          // Source B (RS2 or Immediate)
    input  wire [3:0]  alu_ctrl,   // Operation Selector
    
    output reg  [31:0] result,     // Math Result
    output wire        zero        // Zero Flag (1 if Result == 0)
);

    // ALU Control Encoding (We define these ourselves for the Control Unit later)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010; // Shift Left Logical
    localparam ALU_SLT  = 4'b0011; // Set Less Than (Signed)
    localparam ALU_SLTU = 4'b0100; // Set Less Than (Unsigned)
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110; // Shift Right Logical
    localparam ALU_SRA  = 4'b0111; // Shift Right Arithmetic
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;

    // The Zero flag is easy: Is the result zero?
    assign zero = (result == 32'd0);

    always @(*) begin
        case (alu_ctrl)
            ALU_ADD:  result = a + b;
            ALU_SUB:  result = a - b;
            ALU_SLL:  result = a << b[4:0];  // Only lower 5 bits matter for shift
            ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR:  result = a ^ b;
            ALU_SRL:  result = a >> b[4:0];
            ALU_SRA:  result = $signed(a) >>> b[4:0]; // Arithmetic shift preserves sign bit
            ALU_OR:   result = a | b;
            ALU_AND:  result = a & b;
            default:  result = 32'd0;
        endcase
    end

endmodule
