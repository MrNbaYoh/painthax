all: run

clean:
	@rm -f main

run: paint_save.s paint_constants.s paint_macros.s paint_rop_stage0.s paint_rop_stage1.s
	@armips paint_rop_stage2.s
	@armips paint_rop_stage1.s
	@armips paint_rop_stage0.s
	@armips paint_save.s
