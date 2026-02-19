; 19 Feb 2026
; Михаил Каа

    DEVICE ZXSPECTRUM48
    ORG 0
    
start:
    di
    ld sp, 0xffff
    jp main

    ORG 100
main:
    ld   bc, 0xdf7f      
    ld   a, 0b00000001
    out  (c), a

    ld   hl, batty_scr
    ld   de, 0x4000
    call dzx0_standard

    ld   hl, batty_bin
    ld   de, 0x6800
    call dzx0_standard

    ld   hl, ram_part
    ld   de, 0x6700
    ld   bc, ram_part_end - ram_part
    ldir

    ld   bc, 65535
    call delay
    ld   bc, 65535
    call delay
    ld   bc, 65535
    call delay
    ld   bc, 65535
    call delay

    jp   0x6700

    jp   main

; Процедура задержки
; bc - время
delay:
    dec  bc
    ld   a, b
    or   c
    jr   nz, delay
    ret

    INCLUDE "./tools/zx0/z80/dzx0_standard.asm"
batty_scr:
    INCBIN "./Batty/screen.scr.zx0"   
batty_bin:
    INCBIN "./Batty/main.bin.zx0"
ram_part:
    INCBIN "./build/ram_part_6700.bin"
ram_part_end

end:
    ; Выводим размер бинарника.
    display "Cartridge BIOS code size: ", /d, end - start
    display "Cartridge BIOS code start: ", /d, start
    display "Cartridge BIOS code end: ", /d, end

    SAVEBIN "build/bios_0000.bin", start, 16384
