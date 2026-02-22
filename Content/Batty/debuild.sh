#!/bin/bash

# скрипт извлечения ресурсов из TAP файла с помощью tzxlist

TAP_FILE="batty.tap"

echo "Извлекаем блоки из $TAP_FILE..."

tzxlist -d 2 "$TAP_FILE"
tzxlist -d 3 "$TAP_FILE"

# Переименовываем в понятные имена
mv 00000002.dat screen.scr      # картинка
mv 00000003.dat main.bin        # код игры
rm *.dsc
rm *.hdr

rm *.zx0
./../tools/zx0/build/zx0 screen.scr
./../tools/zx0/build/zx0 main.bin

# main.bin -> 0x6800 (26624) точка входа в main

ls -la