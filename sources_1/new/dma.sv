`timescale 1ns / 100ps

module dma(
    input wire Clk, Reset,
    // CPU writing/reading to DMA
    input wire  logic [15:0] cpu_addr,
    input wire  logic  [7:0] cpu_wdata,
    output      logic  [7:0] cpu_rdata,
    input wire  logic cpu_we, cpu_re,
    // DMA transfer bus
    output      logic [15:0] dma_waddr,
    output      logic [15:0] dma_raddr,
    output      logic  [7:0] dma_wdata,
    input  wire logic  [7:0] dma_rdata,
    output      logic dma_re, dma_we,
    // 0 = none, 1 = transfer
    output      logic dma_mode
);
    // 0xFF46
    logic [7:0] DMA_in, DMA;
    logic DMA_en;

    // CPU read/write
    always_comb begin
        DMA_in = 8'hZZ; DMA_en = 1'b0;
        
        cpu_rdata = 8'hZZ;
        
        if (cpu_we) begin
            case (cpu_addr)
                16'hFF46: begin
                    DMA_in = cpu_wdata;
                    DMA_en = 1'b1;
                end
            endcase
        end else if (cpu_re) begin
            case (cpu_addr)
                16'hFF46: cpu_rdata = DMA;
            endcase
        end
    end

    // 0xFF46
    register #(8, 8'h00) DMAreg(.q(DMA),
                                .d(DMA_in),
                                .load(DMA_en),
                                .clock(Clk),
                                .reset(Reset)
                                );
    
    // OAM DMA state machine
    enum logic {Idle_OAM, Fetch_OAM} OAM_DMA_MODE;
    logic [7:0] OAM_DMA_count;

    // assign OAM DMA
    always_ff @ (posedge Clk) begin
        if (Reset) begin
            OAM_DMA_MODE <= Idle_OAM;
            OAM_DMA_count <= 8'h00;
        end else begin
            unique case (OAM_DMA_MODE)
                Idle_OAM: begin
                    if (DMA_en) begin // writes start DMA transfer
                        OAM_DMA_count <= 8'h00;
                        OAM_DMA_MODE <= Fetch_OAM;
                    end
                end
                Fetch_OAM: begin
                    if (OAM_DMA_count < 8'h9F) begin // increment during fetch
                        OAM_DMA_count <= OAM_DMA_count + 8'h01;
                    end else begin // reset when count=159=0x9F
                        OAM_DMA_count <= 8'h00;
                        OAM_DMA_MODE <= Idle_OAM;
                    end
                end
            endcase
        end
    end

    // assign DMA bus
    always_comb begin
        dma_waddr = 16'hZZZZ; dma_raddr = 16'hZZZZ;
        dma_wdata = dma_rdata; // any reads go to writes
        dma_we = 1'b0; dma_re = 1'b0;

        dma_mode = (OAM_DMA_MODE == Fetch_OAM);

        unique case (OAM_DMA_MODE)
            Idle_OAM: begin end // do nothing
            Fetch_OAM: begin
                dma_waddr = {8'hFE, OAM_DMA_count}; // write to OAM
                dma_raddr = {  DMA, OAM_DMA_count}; // read from address specified in DMA reg
                dma_we = 1'b1;
                dma_re = 1'b1;
            end
        endcase
    end

endmodule
