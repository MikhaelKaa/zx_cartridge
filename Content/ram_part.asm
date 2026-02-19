; 19 Feb 2026
; Михаил Каа

    DEVICE ZXSPECTRUM48
    ORG 0x6700
    
start:
    ld   bc, 0xbf7f
    ld   a, 0b10000000   
    out  (c), a

    jp   0x6800

end:
    ; Выводим размер бинарника.
    display "ram_part code size: ", /d, end - start
    display "ram_part code start: ", /d, start
    display "ram_part code end: ", /d, end

    SAVEBIN "./build/ram_part_6700.bin", start, end - start
