; 19 Feb 2026
; Михаил Каа

    DEVICE ZXSPECTRUM48
    ORG 0x6700
    
start:
    ld   bc, 0xbf7f
    ld   a, 0b10000000   
    out  (c), a

    ld   sp, 0x6000

    ld   iy, 23610

wait_any_key:
    ld   bc, 0x00fe
    in   a, (c)
    and  0x1f
    cp   0x1f
    jr   z, wait_any_key

    jp   0x6800

end:
    ; Выводим размер бинарника.
    display "ram_part code size: ", /d, end - start
    display "ram_part code start: ", /d, start
    display "ram_part code end: ", /d, end

    SAVEBIN "./build/ram_part_6700.bin", start, end - start
