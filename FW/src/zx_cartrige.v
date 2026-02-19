`timescale 1ns / 1ps
// ZX SPECTRUM cartrige module
// 17.02.2026 Mikhael Kaa
// CPU adr bus A0...A12 connect directly to CR_ROM chip
module zx_cartrige #(
    // default example parameter
    parameter SELF_LOCK_VAL = 15
)(
    // Reset
    input   reset_n,
    // CPU ctrl signals
    input   iorq_n,
    input   rd_n,
    input   mreq_n,
    // Part of CPU adr bus
    input   A7,
    input   A13,
    input   A14,
    input   A15,
    
    // ZX ROM block 
    output  ZX_ROM_blk,
    // Cartrige ROM enable
    output  CR_ROM_oe_n,
    // Up part cartrige ROM adr bus (A13...A18)
    output  [5:0] CR_ROM_A,
	 output  [3:0] CR_ROM_CS
	 
);
    // CR_ROM 8kb bank counter
    reg [5:0] CR_ROM_bank_cnt = 6'b0;  
    // Self lock register, disable all logic and CR_ROM
    reg self_lock = 1'b0;
    // rd or wr port 0x7f increment CR_ROM bank
    wire rom_page_up = iorq_n | A7 | self_lock;
    // CPU work with 0000...1fff adr
    wire lower_rom = ({A13, A14, A15} == 3'b000) ? 1'b1 : 1'b0;

    always @(negedge rom_page_up or negedge reset_n) begin
        if(!reset_n) begin
            CR_ROM_bank_cnt <= 6'b0;
            self_lock       <= 1'b0;
        end else begin
            // increment bank counter
            CR_ROM_bank_cnt <= CR_ROM_bank_cnt + 1'b1;
            // check self lock
            if(CR_ROM_bank_cnt == SELF_LOCK_VAL) begin
                self_lock <= 1'b1;
            end
        end
    end

    assign CR_ROM_oe_n = ~lower_rom | rd_n | mreq_n | self_lock ;
    assign ZX_ROM_blk = ~CR_ROM_oe_n;
	 assign CR_ROM_CS[0] = CR_ROM_oe_n;
	 assign CR_ROM_CS[1] = 1'b1;
	 assign CR_ROM_CS[2] = 1'b1;
	 assign CR_ROM_CS[3] = 1'b1;
	 
    assign CR_ROM_A = CR_ROM_bank_cnt;

endmodule
