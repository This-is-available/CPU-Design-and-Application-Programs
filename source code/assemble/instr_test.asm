.data	
	    .dword 0x0
	    .dword 0x0
	    .dword 0x0
	    .word 0x0		
store_unit1:.word  0x111
store_unit2:.word  0x000
store_unit3:.word  0x444
	    .word  0x3
	    .word  0x5
.text
	lw 	t0, 0x1c(x0)	#load t0 with the data in store_unit1, t0=0x111**
	addi 	t1, t0, 0x222	#t1 = t0 + 0x222 = 0x333**
	sw 	t1, 0x20(x0)	#store_unit2 = t1 = 0x333*
	add	t2, t1, t0 	#t2 = t1 + t0 = 0x4444**
L1:	sub 	t2, t2, t0	#t2 = t2 - t0 = 0x333 = t1**
	beq	t2, t1, L1	#if t2 = t1, sub again
	
	lw	t3, 0x24(x0)	#t3 = 0x444
L2:	add	t2, t2, t0	#t2 = t2 + t0 = 0x333
	blt	t2, t3, L2	#if t2 < t3, add again
	jal	x1, L4
	nop
	nop
	nop
	nop
	nop
	
L3:	jal	x0, L5
	
L4:	auipc	t0, 0xffff0	#注意是pc + {imm, 12'b0}, 不是t0
	jalr	x0, 0(x1)
	
	
	
	
	
L5:	sw	t2, 0x0(x0)	#led
	lw 	t6, 0x4(x0)	#btn
	
POLL1:	lw	t4, 0x10(x0)	#switches
	beq	t4, x0, POLL1
	lw	t5, 0x14(x0)
	
POLL2:	lw	s0, 0x8(x0)
	beq	s0, x0, POLL2
	sw	t2, 0xc(x0)
	
	lw	s1, 0x28(x0)	#s1 = 3 
	lw	s2, 0x2c(x0)	#s2 = 5
	sll	t2, t2, s1
	srl	t2, t2, s1
	xor	s3, s1, s2	#s3 = s1^ s2 = 6
	or	s4, s1, s2	#s4 = s1 | s2 = 7
	and	s5, s1, s2	#s5 = s1 & s2 = 1
	sub	s6, x0, s1	#s6 = 0 - s1 = 0xfffffffd = 11...1101
	sra	s6, s6, s5	#s6 = s6 >> 1 = 0xfffffffe = 11....1110
	lb	s8, 0x20(x0)	#s8 = 0x00000033
	slli	s6, s6, 0x2	#s6 = 0xfffffff8 = 11....1000
	srai	s6, s6, 0x1	#s6 = 0xfffffffc = 11....1100
	srli	s6, s6, 0x1	#s6 = 0x7ffffffe = 01....1110
	lui	s7, 0xddddd	#s7 = 0xddddd000
L6:	sub	s2, s2, s5	#s2 = s2 - 1
	bge	s2, s1, L6	#s2: 5 -> 4 -> 3 = s1
L7:	addi	s5, s5, 0x3	#s5 = s5 + 3
	bne	s5, s4, L7	#s5: 1 -> 4 -> 7 = s4
	
END:	jal	x0, END

	
	
	
	

	
		

