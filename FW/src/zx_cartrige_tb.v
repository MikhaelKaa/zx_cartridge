`timescale 1ns / 1ps

module tb_zx_cartrige();
    reg reset_n;
    reg iorq_n;
    reg rd_n;
    reg mreq_n;
    reg A7, A13, A14, A15;
    
    wire ZX_ROM_blk;
    wire CR_ROM_oe_n;
    wire [5:0] CR_ROM_A;
    
    // DUT с уменьшенным параметром для быстрой проверки
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
    
    initial begin
        $dumpfile("tb_zx_cartrige.vcd");
        $dumpvars(0, tb_zx_cartrige);
        
        // Исходное состояние: сброс активен
        reset_n = 0;
        iorq_n  = 1;
        rd_n    = 1;
        mreq_n  = 1;
        A7      = 0;
        A13     = 0;
        A14     = 0;
        A15     = 0;
        #100;
        reset_n = 1;
        #10;
        
        // ------------------------------------------------------------
        // Test 1: Инкремент происходит только при A7=0 и спаде iorq_n
        // ------------------------------------------------------------
        $display("=== Test 1: Increment condition (A7=0 and iorq_n falling) ===");
        
        if (CR_ROM_A !== 0) $display("ERROR: Initial CR_ROM_A = %d, expected 0", CR_ROM_A);
        
        // Попытка инкремента с A7=1 – не должен инкрементироваться
        A7 = 1;
        iorq_n = 0; // rom_page_up = 0|1|0 = 1 – нет изменения
        #10;
        iorq_n = 1;
        #10;
        if (CR_ROM_A !== 0) $display("ERROR: Increment occurred while A7=1, CR_ROM_A = %d", CR_ROM_A);
        
        // Теперь A7=0, создаём отрицательный фронт iorq_n
        A7 = 0;
        iorq_n = 1;
        #10;
        iorq_n = 0; // rom_page_up: 1->0 -> negedge
        #10;
        if (CR_ROM_A !== 1) $display("ERROR: No increment when A7=0 and iorq_n falling, CR_ROM_A = %d", CR_ROM_A);
        
        iorq_n = 1;
        #10;
        
        // ------------------------------------------------------------
        // Test 2: Достижение SELF_LOCK_VAL блокирует активацию CR_ROM_oe_n
        // ------------------------------------------------------------
        $display("=== Test 2: Self-lock prevents CR_ROM_oe_n activation ===");
        
        // Инкрементируем до 2
        iorq_n = 0; #10; iorq_n = 1; #10; // CR_ROM_A=2
        iorq_n = 0; #10; iorq_n = 1; #10; // CR_ROM_A=3 (lock)
        if (CR_ROM_A !== 3) $display("ERROR: Failed to reach lock, CR_ROM_A = %d", CR_ROM_A);
        
        // self_lock активен. Проверим, что CR_ROM_oe_n всегда 1 при попытке активации
        // Необходимые условия: lower_rom=1 (A13=A14=A15=0), rd_n=0, mreq_n=0
        A13 = 0; A14 = 0; A15 = 0;
        rd_n = 0;
        mreq_n = 0;
        #10;
        if (CR_ROM_oe_n !== 0) $display("ERROR: CR_ROM_oe_n = %b, expected 1 (self_lock active)", CR_ROM_oe_n);
        if (ZX_ROM_blk !== 1) $display("ERROR: ZX_ROM_blk = %b, expected 0", ZX_ROM_blk);
        
        rd_n = 1; mreq_n = 1;
        #10;
        
        // ------------------------------------------------------------
        // Test 3: CR_ROM_oe_n активируется при обращении в нижние 8кб
        // Условия: lower_rom=1, rd_n=0, mreq_n=0, self_lock=0
        // ------------------------------------------------------------
        $display("=== Test 3: CR_ROM_oe_n activation in lower ROM area ===");
        
        // Сброс для снятия self_lock
        reset_n = 0;
        #10;
        reset_n = 1;
        #10;
        if (CR_ROM_A !== 0) $display("ERROR: After reset CR_ROM_A = %d, expected 0", CR_ROM_A);
        
        // Устанавливаем условия для активации
        A13 = 0; A14 = 0; A15 = 0; // lower_rom = 1
        rd_n = 0;
        mreq_n = 0;
        #10;
        
        // Ожидаем CR_ROM_oe_n = 0 (активен)
        if (CR_ROM_oe_n !== 0) $display("ERROR: CR_ROM_oe_n = %b, expected 0 during lower ROM access (rd_n=0, mreq_n=0)", CR_ROM_oe_n);
        if (ZX_ROM_blk !== 1) $display("ERROR: ZX_ROM_blk = %b, expected 1", ZX_ROM_blk);
        
        // Проверка, что при выходе из нижней области (lower_rom=0) выход отключается
        A13 = 1; // теперь lower_rom = 0 (A13=1, остальные 0)
        #10;
        if (CR_ROM_oe_n !== 1) $display("ERROR: CR_ROM_oe_n = %b, expected 1 when not in lower ROM", CR_ROM_oe_n);
        
        // Проверка, что при rd_n=1 выход отключается
        A13 = 0; // обратно в lower_rom=1
        rd_n = 1;
        #10;
        if (CR_ROM_oe_n !== 1) $display("ERROR: CR_ROM_oe_n = %b, expected 1 when rd_n=1", CR_ROM_oe_n);
        
        // Проверка, что при mreq_n=1 выход отключается
        rd_n = 0; mreq_n = 1;
        #10;
        if (CR_ROM_oe_n !== 1) $display("ERROR: CR_ROM_oe_n = %b, expected 1 when mreq_n=1", CR_ROM_oe_n);
        
        rd_n = 1; mreq_n = 1;
        #10;
        
        $display("=== All tests completed ===");
        $finish;
    end
    
endmodule