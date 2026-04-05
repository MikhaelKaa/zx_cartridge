// Файл: zx_cartridge.v
// Модуль картриджа ZX Spectrum
// 17.02.2026 Miсhael Kaa
// Шина адреса CPU A0...A12 подключается напрямую к микросхеме CR_ROM
`timescale 1ns / 1ps
module zx_cartridge #(
    // значение по умолчанию для оригинального картриджа
    parameter SELF_LOCK_VAL = 15
)(
    // Сброс
    input   reset_n,
    // Управляющие сигналы CPU
    input   iorq_n,
    input   rd_n,
    input   wr_n,
    input   mreq_n,
    // Часть шины адреса CPU
    input   A7,
    input   A13,
    input   A14,
    input   A15,
    inout   [7:0] D,

    // Блокировка ПЗУ ZX
    output  ZX_ROM_blk,
    // Разрешение ПЗУ картриджа (активный низкий)
    output  CR_ROM_oe_n,
    // Старшая часть адреса ПЗУ картриджа (A13...A18)
    output  [5:0] CR_ROM_A,
    output  [3:0] CR_ROM_CS
);
    // Счётчик банков ПЗУ картриджа по 8 кБ
    reg [5:0] CR_ROM_bank_cnt = 6'b0;
    // Регистр самоблокировки – отключает всю логику и ПЗУ картриджа
    reg self_lock = 1'b0;
    // Сигнал переключения страницы: чтение или запись в порт 0x7F
    wire rom_page_up = iorq_n | A7;
    // CPU работает с адресами 0000...1FFF (нижние 8 кб ПЗУ)
    wire lower_rom = ({A13, A14, A15} == 3'b000) ? 1'b1 : 1'b0;

    always @(negedge rom_page_up or negedge reset_n) begin
        if(!reset_n) begin
            CR_ROM_bank_cnt <= 6'b0;
            self_lock       <= 1'b0;
        end else begin
            // инкремент счётчика банков
            CR_ROM_bank_cnt <= CR_ROM_bank_cnt + 1'b1;
            // проверка достижения значения самоблокировки
            if(CR_ROM_bank_cnt == SELF_LOCK_VAL) begin
                self_lock <= 1'b1;
            end
        end
    end

    assign CR_ROM_oe_n = ~lower_rom | rd_n | mreq_n | self_lock ;
    assign ZX_ROM_blk   = ~CR_ROM_oe_n;
    assign CR_ROM_CS[0] = CR_ROM_oe_n;
    assign CR_ROM_CS[1] = 1'b1;
    assign CR_ROM_CS[2] = 1'b1;
    assign CR_ROM_CS[3] = 1'b1;

    assign CR_ROM_A = CR_ROM_bank_cnt;
	 assign D = 8'bz;

endmodule