module riscv_regfile (
    input  wire        clk,
    input  wire        we3,      // Write Enable (Port 3)
    input  wire [4:0]  a1,       // Address Read Port 1 (rs1)
    input  wire [4:0]  a2,       // Address Read Port 2 (rs2)
    input  wire [4:0]  a3,       // Address Write Port 3 (rd)
    input  wire [31:0] wd3,      // Write Data (Port 3)
    
    output wire [31:0] rd1,      // Read Data 1
    output wire [31:0] rd2       // Read Data 2
);

    // 32 registers of 32-bit width
    reg [31:0] rf [31:0];

    // --- Read Logic (Combinational) ---
    // If address is 0, output 0. Otherwise read from array.
    assign rd1 = (a1 != 0) ? rf[a1] : 32'd0;
    assign rd2 = (a2 != 0) ? rf[a2] : 32'd0;

    // --- Write Logic (Synchronous) ---
    // Only write if Write Enable is high AND we aren't writing to x0
    always @(posedge clk) begin
        if (we3 && (a3 != 5'd0)) begin
            rf[a3] <= wd3;
        end
    end

endmodule
