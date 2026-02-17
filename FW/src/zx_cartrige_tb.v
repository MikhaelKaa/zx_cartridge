`timescale 1ns / 1ps

module tb_zx_cartrige();
    // Управляющие сигналы
    reg reset_n;
    reg iorq_n;
    reg rd_n;
    reg mreq_n;
    
    // Полная адресная шина (16 бит)
    reg [15:0] address;
    
    // Подключение отдельных бит к DUT
    wire A7   = address[7];
    wire A13  = address[13];
    wire A14  = address[14];
    wire A15  = address[15];
    
    // Выходы DUT
    wire ZX_ROM_blk;
    wire CR_ROM_oe_n;
    wire [5:0] CR_ROM_A;
    
    // Тестируемый модуль (с уменьшенным параметром для быстрой проверки)
    zx_cartrige #(
        .SELF_LOCK_VAL(3)
    ) uut (
        .reset_n(reset_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .mreq_n(mreq_n),
        .A7(A7),
        .A13(A13),
        .A14(A14),
        .A15(A15),
        .ZX_ROM_blk(ZX_ROM_blk),
        .CR_ROM_oe_n(CR_ROM_oe_n),
        .CR_ROM_A(CR_ROM_A)
    );
    
    // Задачи для моделирования циклов Z80
    // Запись в порт (активируется iorq_n, для инкремента важен его спад)
    task write_port(input [15:0] addr);
        begin
            address = addr;
            #10;
            iorq_n = 0;             // начало цикла IN/OUT
            #10;
            iorq_n = 1;             // завершение цикла – отрицательный фронт
            #10;
        end
    endtask
    
    // Чтение из памяти
    task read_mem(input [15:0] addr);
        begin
            address = addr;
            #10;
            mreq_n = 0;             // запрос памяти
            rd_n   = 0;             // чтение
            #20;                    // удерживаем для проверки
            mreq_n = 1;
            rd_n   = 1;
            #10;
        end
    endtask
    
    // Проверка с выводом сообщения
    task check_equal(input [31:0] expected, input [31:0] actual, input [80*8:0] msg);
        if (expected !== actual) begin
            $display("ERROR: %s. Expected %d, got %d", msg, expected, actual);
        end
    endtask
    
    initial begin
        $dumpfile("zx_cartrige.vcd");
        $dumpvars(0, tb_zx_cartrige);
        
        // Исходное состояние: сброс активен, все сигналы неактивны
        reset_n = 0;
        iorq_n  = 1;
        rd_n    = 1;
        mreq_n  = 1;
        address = 16'h0000;
        #100;
        reset_n = 1;
        #10;
        
        // ------------------------------------------------------------
        // Test 1: Инкремент происходит только при A7=0 и спаде iorq_n
        // ------------------------------------------------------------
        $display("=== Test 1: Increment condition (A7=0 and iorq_n falling) ===");
        check_equal(0, CR_ROM_A, "Initial CR_ROM_A");
        
        // Попытка с A7=1 – не должен инкрементироваться
        write_port(16'h0080);       // A7=1 (адрес 0x80)
        #10;
        check_equal(0, CR_ROM_A, "After write to port 0x80 (A7=1)");
        
        // Корректный инкремент с A7=0
        write_port(16'h007F);       // A7=0
        #10;
        check_equal(1, CR_ROM_A, "After first write to 0x7F");
        
        write_port(16'h007F);       // второй раз
        #10;
        check_equal(2, CR_ROM_A, "After second write to 0x7F");
        
        // ------------------------------------------------------------
        // Test 2: Достижение SELF_LOCK_VAL (3) блокирует дальнейшие инкременты
        // ------------------------------------------------------------
        $display("=== Test 2: Self-lock at value 3 ===");
        write_port(16'h007F);       // третий раз -> lock
        #10;
        check_equal(3, CR_ROM_A, "After third write (should lock)");
        
        // Попытка инкремента после блокировки
        write_port(16'h007F);
        #10;
        check_equal(3, CR_ROM_A, "Write after lock - no increment");
        
        // ------------------------------------------------------------
        // Test 3: При self_lock=1 CR_ROM_oe_n не активируется даже в нижней ROM
        // ------------------------------------------------------------
        $display("=== Test 3: CR_ROM_oe_n inactive while locked ===");
        read_mem(16'h0100);         // адрес в нижней области (0x100)
        #10;
        check_equal(1, CR_ROM_oe_n, "CR_ROM_oe_n during locked read");
        check_equal(0, ZX_ROM_blk, "ZX_ROM_blk during locked read");
        
        // ------------------------------------------------------------
        // Test 4: Сброс обнуляет счётчик и снимает блокировку
        // ------------------------------------------------------------
        $display("=== Test 4: Reset ===");
        reset_n = 0;
        #20;
        reset_n = 1;
        #10;
        check_equal(0, CR_ROM_A, "After reset");
        check_equal(1, CR_ROM_oe_n, "CR_ROM_oe_n after reset");
        
        // ------------------------------------------------------------
        // Test 5: Активация CR_ROM_oe_n при чтении нижних 8KB (self_lock=0)
        // ------------------------------------------------------------
        $display("=== Test 5: CR_ROM_oe_n activation in lower ROM (0x0000-0x1FFF) ===");
        
        // Чтение внутри нижней области
        read_mem(16'h0100);
        #10;
        check_equal(1, CR_ROM_oe_n, "CR_ROM_oe_n at 0x100");
        check_equal(0, ZX_ROM_blk, "ZX_ROM_blk at 0x100");
        
        read_mem(16'h1FFF);         // граница нижней области
        #10;
        check_equal(1, CR_ROM_oe_n, "CR_ROM_oe_n at 0x1FFF");
        
        // Чтение вне нижней области
        read_mem(16'h2000);         // A13=1
        #10;
        check_equal(1, CR_ROM_oe_n, "CR_ROM_oe_n at 0x2000 (outside)");
        
        read_mem(16'h4001);         // A14=1
        #10;
        check_equal(1, CR_ROM_oe_n, "CR_ROM_oe_n at 0x4001 (outside)");
        
        // ------------------------------------------------------------
        // Test 6: Проверка влияния mreq_n и rd_n
        // ------------------------------------------------------------
        $display("=== Test 6: Control signals mreq_n and rd_n ===");
        address = 16'h0100;
        #10;
        
        // mreq_n=0, rd_n=1 – чтение не активно
        mreq_n = 0; rd_n = 1;
        #10;
        check_equal(1, CR_ROM_oe_n, "CR_ROM_oe_n with rd_n=1");
        
        // mreq_n=1, rd_n=0 – нет запроса памяти
        mreq_n = 1; rd_n = 0;
        #10;
        check_equal(1, CR_ROM_oe_n, "CR_ROM_oe_n with mreq_n=1");
        
        // Оба активны – должно включиться
        mreq_n = 0; rd_n = 0;
        #10;
        check_equal(0, CR_ROM_oe_n, "CR_ROM_oe_n with both active");
        
        // Возврат в исходное
        mreq_n = 1; rd_n = 1;
        #10;
        
        $display("=== All tests completed ===");
        $finish;
    end
    
endmodule