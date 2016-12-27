ROPDB_TARGET = paint_ropdb/ropdb_$(PAINT_VERSION).txt

.PHONY: all directories build/constants clean

all: directories build/constants build/paint_code.bin paint_save/main

directories:
	@mkdir -p build

build/constants: paint_ropdb/ropdb.txt
	@python scripts/makeHeaders.py build/constants "FIRM_VERSION=$(FIRM_VERSION)" $^

build/paint_code.bin: paint_code/paint_code.bin
	@cp paint_code/paint_code.bin build/
paint_code/paint_code.bin: $(wildcard paint_code/source/*)
	@cd paint_code && make

paint_save/main:
	@cd paint_save && make

paint_ropdb/ropdb.txt: $(ROPDB_TARGET)
	@cp $(ROPDB_TARGET) paint_ropdb/ropdb.txt

clean:
	@rm -rf build
	@rm paint_ropdb/ropdb.txt
	@cd paint_save && make clean
	@cd paint_code && make clean
