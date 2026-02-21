SJASMPLUS=sjasmplus

build: clean
	mkdir -p build
	@${SJASMPLUS} ./ram_part.asm --syntax=F
	@${SJASMPLUS} ./main.asm --syntax=F
# 	@${SJASMPLUS} ./test.asm --syntax=F

clean:
# 	@rm -f -r ./assets/*.zx0
	@rm -f -r build


# 	./tools/zx0/build/zx0 ./assets/Spec.scr
# 	./tools/zx0/build/zx0 ./assets/Arsen.scr
# 	./tools/zx0/build/zx0 ./assets/Jura.scr
# 	tape2wav ./build/GBX2601.tap ./build/GBX2601.wav
# run:
# 	fuse --machine 128 -g 3x --tape ./build/GBX2601.tap
# assets: 
