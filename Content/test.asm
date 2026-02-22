; Простейший тест переключения банков для карика
; Банк 0 всегда в 0000-1FFF, переключаемый в 2000-3FFF
; Цикл: переключить банк, прочитать байт из 2000h, повторить

    DEVICE ZXSPECTRUM48

    ORG     0
start:
    di
    jp      main

    ; векторы RST (просто возврат)
    ORG     0x08
    ret
    ORG     0x10
    ret
    ORG     0x18
    ret
    ORG     0x20
    ret
    ORG     0x28
    ret
    ORG     0x30
    ret
    ORG     0x38
    ret

    ORG     0x100
main:
    ld      bc, 0xdf7f      ; порт выбора банка
    ld      d, 0            ; начальный банк
loop:
    ld      a, d
    out     (c), a          ; переключить банк
    nop                     ; небольшая пауза
    nop
    ld      hl, 0x2000
    ld      a, (hl)         ; прочитать первый байт банка
    inc     d               ; следующий банк
    jr      loop

end:
    ; Выводим размер бинарника.
    display "test code size: ", /d, end - start
    display "test code start: ", /d, start
    display "test code end: ", /d, end

    SAVEBIN "build/test_0000.bin", start, 16384