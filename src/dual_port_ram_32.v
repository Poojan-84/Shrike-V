module dual_port_ram_32 #(
    parameter WORD_COUNT = 256 // 256 words = 1KB (Small, fits easily)
)(
    input  wire        clk,
    
    // PORT A: CPU Interface
    input  wire        we_a,     // CPU Write Enable
    input  wire [31:0] addr_a,   // CPU Address (Byte Address!)
    input  wire [31:0] wd_a,     // CPU Write Data
    output reg  [31:0] rd_a,     // CPU Read Data
    
    // PORT B: SPI Interface (Loader/Debugger)
    input  wire        we_b,     // SPI Write Enable
    input  wire [31:0] addr_b,   // SPI Address (Byte Address!)
    input  wire [31:0] wd_b,     // SPI Write Data
    output reg  [31:0] rd_b      // SPI Read Data
);

    // The Memory Array (32-bit wide words)
    reg [31:0] mem [0:WORD_COUNT-1];

    // --- PORT A (CPU) ---
    // RISC-V addresses are Byte-Aligned (0, 4, 8, C...), but our memory is Word-Aligned (0, 1, 2, 3...).
    // So we must divide the input address by 4 (drop the bottom 2 bits).
    wire [31:0] word_addr_a = addr_a >> 2;

    always @(posedge clk) begin
        if (we_a) begin
            mem[word_addr_a] <= wd_a;
        end
        rd_a <= mem[word_addr_a];
    end

    // --- PORT B (SPI) ---
    wire [31:0] word_addr_b = addr_b >> 2;

    always @(posedge clk) begin
        if (we_b) begin
            mem[word_addr_b] <= wd_b;
        end
        rd_b <= mem[word_addr_b];
    end
    
    // Optional: Initialize with zeros to avoid "X" states in simulation
    integer i;
    initial begin
        for (i = 0; i < WORD_COUNT; i = i + 1)
            mem[i] = 32'd0;
    end

endmodule
