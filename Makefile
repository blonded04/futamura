.PHONY: all

all:
	make -C runtime
	make -C byterun
	make -C spec
	make -C tests
	make -C interpreter

clean:
	make clean -C runtime
	make clean -C byterun
	make clean -C spec
	make clean -C tests
	make clean -C interpreter
