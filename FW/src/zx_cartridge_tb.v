`timescale 1ns / 1ps

module tb_zx_cartridge();
    // Управляющие сигналы
    reg reset_n;
    reg iorq_n;
    reg rd_n;
    reg wr_n;
    reg mreq_n;
    
    // Полная адресная шина (16 бит)
    reg [15:0] address;
    
    // Подключение отдельных бит к DUT
    wire A7   = address[7];
    wire A13  = address[13];
    wire A14  = address[14];
    wire A15  = address[15];
    
    // Шина данных (8 бит) – двунаправленная
    wire [7:0] D;
    reg  [7:0] D_drive;      // данные для записи от тестбенча
    wire [7:0] D_sample;     // данные, читаемые из DUT
    assign D = (wr_n == 0) ? D_drive : 8'bz;
    assign D_sample = D;
    
    // Выходы DUT
    wire ZX_ROM_blk;
    wire CR_ROM_oe_n;
    wire [5:0] CR_ROM_A;
    wire [3:0] CR_ROM_CS;    // теперь 4 бита
    
    // Вспомогательная переменная для чтения портов
    reg [7:0] dummy;
    
    // Тестируемый модуль (новая версия)
    zx_cartridge uut (
        .reset_n(reset_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .mreq_n(mreq_n),
        .A7(A7),
        .A13(A13),
        .A14(A14),
        .A15(A15),
        .D(D),
        .ZX_ROM_blk(ZX_ROM_blk),
        .CR_ROM_oe_n(CR_ROM_oe_n),
        .CR_ROM_A(CR_ROM_A),
        .CR_ROM_CS(CR_ROM_CS)
    );
    
    // Задачи для моделирования циклов Z80
    
    // Запись в порт ввода-вывода
    task write_port(input [15:0] addr, input [7:0] data);
        begin
            address = addr;
            D_drive = data;
            #10;
            iorq_n = 0;
            wr_n   = 0;
            #20;
            iorq_n = 1;
            wr_n   = 1;
            #10;
            D_drive = 8'bz;
        end
    endtask
    
    // Чтение из порта ввода-вывода (возвращает прочитанные данные)
    task read_port(input [15:0] addr, output [7:0] data);
        begin
            address = addr;
            #10;
            iorq_n = 0;
            rd_n   = 0;
            #20;
            data = D_sample;
            iorq_n = 1;
            rd_n   = 1;
            #10;
        end
    endtask
    
    // Чтение из памяти с проверкой CR_ROM_A и CR_ROM_CS (новые сигналы)
    task read_mem_check(input [15:0] addr, input [5:0] exp_A, input [3:0] exp_CS);
        begin
            address = addr;
            #10;
            mreq_n = 0;
            rd_n   = 0;
            #10;  // ждём стабилизации
            check_equal(exp_A, CR_ROM_A, "CR_ROM_A during read");
            check_equal(exp_CS, CR_ROM_CS, "CR_ROM_CS during read");
            #10;
            mreq_n = 1;
            rd_n   = 1;
            #10;
        end
    endtask
    
    // Чтение из памяти с проверкой CR_ROM_oe_n и ZX_ROM_blk
    task read_mem_check_oe(input [15:0] addr, input exp_oe, input exp_blk);
        begin
            address = addr;
            #10;
            mreq_n = 0;
            rd_n   = 0;
            #10;
            check_equal(exp_oe, CR_ROM_oe_n, "CR_ROM_oe_n during read");
            check_equal(exp_blk, ZX_ROM_blk, "ZX_ROM_blk during read");
            #10;
            mreq_n = 1;
            rd_n   = 1;
            #10;
        end
    endtask
    
    // Простое чтение из памяти (без проверки, для установки адреса)
    task read_mem(input [15:0] addr);
        begin
            address = addr;
            #10;
            mreq_n = 0;
            rd_n   = 0;
            #20;
            mreq_n = 1;
            rd_n   = 1;
            #10;
        end
    endtask
    
    // Проверка равенства (поддерживает 4‑битные и 6‑битные аргументы)
    task check_equal(input [31:0] expected, input [31:0] actual, input [80*8:0] msg);
        if (expected !== actual) begin
            $display("ERROR: %s. Expected %h, got %h", msg, expected, actual);
        end else begin
            $display("OK: %s", msg);
        end
    endtask
    
    initial begin
        $dumpfile("zx_cartridge.vcd");
        $dumpvars(0, tb_zx_cartridge);
        
        // Исходное состояние: сброс активен, все сигналы неактивны
        reset_n = 0;
        iorq_n  = 1;
        rd_n    = 1;
        wr_n    = 1;
        mreq_n  = 1;
        address = 16'h0000;
        D_drive = 8'bz;
        #100;
        reset_n = 1;
        #10;
        
        // ------------------------------------------------------------
        // Test 1: Запись и чтение регистров через порты
        // ------------------------------------------------------------
        $display("=== Test 1: Write and read registers via I/O ports ===");
        
        // Запись в bank: адрес 0xC000 (A15=1, A14=1, A13=0, A7=0)
        write_port(16'hC000, 8'hA5);    // запись reg_bank = 0xA5
        read_port(16'hC000, dummy);
        check_equal(8'hA5, dummy, "Read bank returns written value");
        
        // Запись в control: адрес 0xA000 (A15=1, A14=0, A13=1, A7=0)
        write_port(16'hA000, 8'h80);    // запись reg_ctl с битом 7 = 1 (отключение)
        read_port(16'hA000, dummy);
        check_equal(8'h80, dummy, "Read control returns written value");
        
        // Сбрасываем бит disable (reg_ctl[7]=0) для дальнейших тестов
        write_port(16'hA000, 8'h00);
        read_port(16'hA000, dummy);
        check_equal(8'h00, dummy, "Control = 0 after disable cleared");
        
        // ------------------------------------------------------------
        // Test 2: Формирование страницы и выбор микросхемы
        // ------------------------------------------------------------
        $display("=== Test 2: Page and chip select formation ===");
        
        // Записываем bank = 0xA5 -> chip_sel = 2'b10 = 2, page_offs = 6'b100101 = 37
        write_port(16'hC000, 8'hA5);
        
        // Верхнее окно (A13=1): адрес 0x2000
        // Ожидаем CR_ROM_A = 37, активный CS2 (бит 2 = 0) -> 4'b1011 (младший бит = CS0)
        read_mem_check(16'h2000, 6'd37, 4'b1011); // CS2 активен (0), остальные 1
        
        // Нижнее окно (A13=0): адрес 0x1000
        // Ожидаем CR_ROM_A = 0, активный CS0 -> 4'b1110
        read_mem_check(16'h1000, 6'd0,  4'b1110);
        
        // ------------------------------------------------------------
        // Test 3: Проверка всех вариантов chip_sel
        // ------------------------------------------------------------
        $display("=== Test 3: Chip select generation for all chip_sel values ===");
        
        // chip_sel = 0
        write_port(16'hC000, 8'h00);    // 0b00000000
        read_mem_check(16'h2000, 6'd0, 4'b1110); // CS0 активен (0) -> 1110
        read_mem_check(16'h1000, 6'd0, 4'b1110); // нижнее окно тоже CS0
        
        // chip_sel = 1
        write_port(16'hC000, 8'h40);    // 0b01000000 -> chip_sel=1, offs=0
        read_mem_check(16'h2000, 6'd0, 4'b1101); // CS1 активен -> 1101
        read_mem_check(16'h1000, 6'd0, 4'b1110); // нижнее окно CS0
        
        // chip_sel = 2
        write_port(16'hC000, 8'h80);    // 0b10000000 -> chip_sel=2, offs=0
        read_mem_check(16'h2000, 6'd0, 4'b1011); // CS2 активен -> 1011
        read_mem_check(16'h1000, 6'd0, 4'b1110);
        
        // chip_sel = 3
        write_port(16'hC000, 8'hC0);    // 0b11000000 -> chip_sel=3, offs=0
        read_mem_check(16'h2000, 6'd0, 4'b0111); // CS3 активен -> 0111
        read_mem_check(16'h1000, 6'd0, 4'b1110);
        
        // ------------------------------------------------------------
        // Test 4: Сигнал rom_access и CR_ROM_oe_n / ZX_ROM_blk
        // ------------------------------------------------------------
        $display("=== Test 4: rom_access control ===");
        
        // Включим картридж (reg_ctl[7]=0) – уже 0
        // Чтение из области ROM (адрес 0x1000)
        read_mem_check_oe(16'h1000, 1'b0, 1'b1); // CR_ROM_oe_n = 0, ZX_ROM_blk = 1
        
        // Чтение из области не ROM (адрес 0x4000, A15=0, A14=1)
        read_mem_check_oe(16'h4000, 1'b1, 1'b0); // оба неактивны
        
        // Отключим картридж (установим бит 7)
        write_port(16'hA000, 8'h80);
        read_mem_check_oe(16'h1000, 1'b1, 1'b0); // неактивны, т.к. картридж отключён
        
        // Снова включим
        write_port(16'hA000, 8'h00);
        
        // ------------------------------------------------------------
        // Test 5: Сброс
        // ------------------------------------------------------------
        $display("=== Test 5: Reset ===");
        reset_n = 0;
        #20;
        reset_n = 1;
        #10;
        
        // Проверим, что регистры сброшены в 0
        read_port(16'hC000, dummy);
        check_equal(8'h00, dummy, "bank reads 0 after reset");
        read_port(16'hA000, dummy);
        check_equal(8'h00, dummy, "control reads 0 after reset");
        
        // Проверим поведение после сброса: нижнее окно CS0, страница 0
        read_mem_check(16'h1000, 6'd0, 4'b1110); // нижнее окно: CS0 активен
        read_mem_check(16'h2000, 6'd0, 4'b1110); // верхнее окно тоже должно быть CS0 (т.к. bank=0)
        
        $display("=== All tests completed ===");
        $finish;
    end
    
endmodule