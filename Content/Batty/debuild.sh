#!/bin/bash

# скрипт извлечения ресурсов из TAP файла с помощью tzxlist

TAP_FILE="batty.tap"

echo "Извлекаем блоки из $TAP_FILE..."

# Извлекаем каждый блок в отдельный файл
tzxlist -d 0 "$TAP_FILE"
tzxlist -d 1 "$TAP_FILE"
tzxlist -d 2 "$TAP_FILE"
tzxlist -d 3 "$TAP_FILE"

# Переименовываем в понятные имена
mv 00000000.dat loader0.bin     # загрузчик
mv 00000001.dat loader1.bin     # загрузчик
mv 00000002.dat screen.scr      # картинка
mv 00000003.dat main.bin        # код игры
rm *.dsc
rm *.hdr

# Показываем результат
ls -la