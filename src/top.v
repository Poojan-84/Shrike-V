module top (
    input  wire clk,
    input  wire rst_n, // Physical button reset (optional)
    
    // SPI Signals
    input  wire spi_ss_n,
    input  wire spi_sck,
    input  wire spi_mosi,
    output wire spi_miso,
    output wire spi_miso_en,
    
    // Debug LED
    output wire led
);

    // --- 1. SPI Target Instance ---
    wire [7:0] rx_data;
    wire       rx_valid;
    wire [7:0] tx_data;
    
    // We send the lower 8 bits of PC back over SPI for debugging
    wire [31:0] debug_pc;
    assign tx_data = debug_pc[7:0]; 

    spi_target #(.WIDTH(8)) u_spi (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_enable(1'b1),
        .i_ss_n(spi_ss_n),
        .i_sck(spi_sck),
        .i_mosi(spi_mosi),
        .o_miso(spi_miso),
        .o_miso_oe(spi_miso_en),
        .o_rx_data(rx_data),
        .o_rx_data_valid(rx_valid),
        .i_tx_data(tx_data),
        .o_tx_data_hold()
    );

    // --- 2. Protocol State Machine ---
    reg [2:0]  state;
    reg [7:0]  cmd;
    reg [31:0] buffer;      // Accumulates bytes
    reg [31:0] addr_ptr;    // Where are we writing in memory?
    reg        cpu_reset_sw;// Software-controlled reset
    
    // Interface to CPU
    reg        imem_we;
    reg [31:0] imem_wdata;

    localparam S_CMD    = 3'd0;
    localparam S_BYTE_3 = 3'd1;
    localparam S_BYTE_2 = 3'd2;
    localparam S_BYTE_1 = 3'd3;
    localparam S_BYTE_0 = 3'd4; // Final byte

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_CMD;
            cpu_reset_sw <= 1'b1; // Default to Reset ON (CPU Stopped)
            addr_ptr <= 32'd0;
            imem_we <= 1'b0;
        end else begin
            // Default pulse to 0
            imem_we <= 1'b0; 

            if (rx_valid) begin
                case (state)
                    S_CMD: begin
                        cmd <= rx_data;
                        // Single-byte commands
                        if (rx_data == 8'h10) cpu_reset_sw <= 1'b1; // Stop
                        if (rx_data == 8'h11) cpu_reset_sw <= 1'b0; // Run
                        
                        // Multi-byte commands (Set Addr / Write Data) move to next state
                        if (rx_data == 8'h20 || rx_data == 8'h30) state <= S_BYTE_3;
                    end

                    S_BYTE_3: begin buffer[31:24] <= rx_data; state <= S_BYTE_2; end
                    S_BYTE_2: begin buffer[23:16] <= rx_data; state <= S_BYTE_1; end
                    S_BYTE_1: begin buffer[15:8]  <= rx_data; state <= S_BYTE_0; end
                    
                    S_BYTE_0: begin 
                        buffer[7:0] <= rx_data; 
                        state <= S_CMD; // Transaction done
                        
                        // Execute Command
                        if (cmd == 8'h20) begin
                            // Set Address
                            addr_ptr <= {buffer[31:8], rx_data};
                        end
                        if (cmd == 8'h30) begin
                            // Write IMEM
                            imem_wdata <= {buffer[31:8], rx_data};
                            imem_we <= 1'b1; // Trigger Write Pulse
                            addr_ptr <= addr_ptr + 4; // Auto-increment address
                        end
                    end
                endcase
            end
        end
    end

    // --- 3. RISC-V Core Instance ---
    riscv_core u_core (
        .clk(clk),
        .rst_n(rst_n && !cpu_reset_sw), // CPU is reset if Pin is Low OR Software is High
        
        // SPI Sideload Interface
        .spi_imem_we(imem_we),
        .spi_imem_addr(addr_ptr),
        .spi_imem_data(imem_wdata),
        
        .spi_dmem_addr(32'd0), // Not using data readback yet
        .spi_dmem_data(),
        
        .debug_pc(debug_pc)
    );
    
    // Heartbeat / PC Activity LED
    // Toggle LED when PC bit 2 changes (divides clock visually)
    assign led = debug_pc[2];

endmodule
