.data
led_data:	.word	0x00001f00 	#0
display_state: .word	0x00001f08	#4
display_data:  	.word	0x00001f0c	#8
sw_state:	.word	0x00001f10	#c
sw_data:	.word	0x00001f14	#10
keyboard_state:.word	0x00001f1c	#14
keyboard_data: .word	0x00001f20	#18
display_mask:	.word	0x00000fff	#1c
limit:		.word	0x000186a0	#20
start:	.word	0x00002000		#24
red:	.word	0x00000f00		#28
green:	.word	0x000000f0		#2c
blue:	.word	0x0000000f		#30
col:	.word	0x000000a0		#34
row:	.word	0x00000078		#38
coll:	.word	0x0000009f		#3c
rowl:	.word	0x00000077		#40
mask:	.word	0x00000fff		#44
NEW_LIMIT:.word	0x00000100		#48

.text
# main program
lw	x1, 0x20(x0)
lw	x2, 0x4(x0)
lw	x3, 0x8(x0)
addi	x4, x0, 0x000
addi	x5, x0, 0x000
loop: beq x4, x1, up
addi	x4, x4, 0x001
jal x31, loop
up: addi x5, x5, 0x001
addi x4, x0, 0x001
detect: lw x6, 0(x2)
beq	x6, x0, detect
sw	x0, 0(x2)
sw	x5, 0(x3)
jal x31, loop

# paint program

# save the registers
add	x14, x0, x1
add	x15, x0, x2
add	x16, x0, x3
add	x17, x0, x4
add	x18, x0, x5
add	x19, x0, x6
add	x1, x0, x0
add	x2, x0, x0
add	x3, x0, x0
add	x4, x0, x0
add	x5, x0, x0
add	x6, x0, x0
add	x31, x0, x0

# program
lw	x5, 0x24(x0)
lw	x6, 0x4(x0)
lw	x7, 0x18(x0)
lw	x21, 0x44(x0)
lw	x22, 0x28(x0)
lw	x23, 0x2c(x0)
lw	x24, 0x30(x0)
lw	x25, 0x34(x0)
lw	x26, 0x38(x0)
lw	x27, 0x3c(x0)
lw	x28, 0x40(x0)
add	x8, x0, x0	# x
add	x9, x0, x0	# y
add	x29, x0, x0
lw	x31, 0x24(x0)	# start
lw	x30, 0(x31)
sw	x0, 0(x31)
loop_0:	lw x10, 0(x6)
beq	x10, x0, loop_0
lw	x11, 0(x7)
sw	x0, 0(x6)
addi	x12, x0, 0x000
# W A S D J K L O P Q Sp
# 0 1 2 3 4 5 6 7 8 9 10
beq	x11, x12, w
addi	x12, x12, 0x001
beq	x11, x12, a
addi	x12, x12, 0x001
beq 	x11, x12, s
addi	x12, x12, 0x001
beq 	x11, x12, d
addi	x12, x12, 0x001
beq 	x11, x12, j
addi 	x12, x12, 0x001
beq 	x11, x12, k
addi 	x12, x12, 0x001
beq 	x11, x12, l
addi 	x12, x12, 0x001
beq 	x11, x12, o
addi 	x12, x12, 0x001
beq 	x11, x12, p
addi 	x12, x12, 0x001
beq 	x11, x12, q
addi	x12, x12, 0x001
beq	x11, x12, Sp
jal 	x20, loop_0
w:
beq	x9, x0, loop_0
sw	x30, 0(x31)
addi 	x9, x9, -1
sub	x31, x31, x25
lw	x30, 0(x31)
sw	x0, 0(x31)
jal	x20, loop_0
a:
beq	x8, x0, loop_0
sw	x30, 0(x31)
addi 	x8, x8, -1
addi	x31, x31, -1
lw	x30, 0(x31)
sw	x0, 0(x31)
jal	x20, loop_0
s:
beq	x9, x28, loop_0
sw	x30, 0(x31)
addi 	x9, x9, 1
add	x31, x31, x25
lw	x30, 0(x31)
sw	x0, 0(x31)
jal	x20, loop_0
d:
beq	x8, x27, loop_0
sw	x30, 0(x31)
addi 	x8, x8, 1
addi	x31, x31, 1
lw	x30, 0(x31)
sw	x0, 0(x31)
jal	x20, loop_0
j:
add	x30, x0, x22
jal	x20, loop_0
k:
add	x30, x0, x23
jal	x20, loop_0
l:
add	x30, x0, x24
jal	x20, loop_0
o:
slli	x29, x29, 1
addi	x29, x29, 1
jal	x20, loop_0
p:
slli	x29, x29, 1
jal	x20, loop_0
Sp:
and	x29, x29, x21
add	x30, x0, x29,
add	x29, x0, x0
jal	x20, loop_0
q:
# restore
add	x1, x0, x14
add	x2, x0, x15
add	x3, x0, x16
add	x4, x0, x17
add	x5, x0, x18
add	x6, x0, x19
add	x7, x0, x0
add	x8, x0, x0
add	x9, x0, x0
add	x10, x0, x0
add	x11, x0, x0
add	x12, x0, x0
add	x20, x0, x0
add	x21, x0, x0
add	x22, x0, x0
add	x23, x0, x0
add	x24, x0, x0
add	x25, x0, x0
add	x26, x0, x0
add	x27, x0, x0
add	x28, x0, x0
add	x29, x0, x0
add	x30, x0, x0
add	x31, x0, x0
ret
 
addi 	x0, x0, 0
addi 	x0, x0, 0
addi 	x0, x0, 0
addi 	x0, x0, 0
addi 	x0, x0, 0
 
# fibonacci program

# save the registers
add	x14, x0, x1
add	x15, x0, x2
add	x16, x0, x3
add	x17, x0, x4
add	x18, x0, x5
add	x19, x0, x6 
add	x1, x0, x0
add	x2, x0, x0
add	x3, x0, x0
add	x4, x0, x0
add	x5, x0, x0
add	x6, x0, x0
add	x31, x0, x0

# progran
lw	x1, 0xc(x0)		#swx state
lw	x2, 0x10(x0)		#swx data
lw	x3, 0x8(x0)		#display data
loop_1: lw x4, 0(x1)
beq	x4, x0, loop_1
lw	x5, 0(x2)
sw	x0, 0(x1)
beq	x5, x0, qt
addi	x8, x0, 0x001
beq	x5, x8, set
addi	x8, x8, 0x001
beq	x5, x8, set
addi	x6, x0, 0x001		#第一项是1
addi	x7, x0, 0x002		#第二项是2
addi	x5, x5, -2
loop_2: add x8, x6, x7
addi	x5, x5, -1
add	x6, x7, x0
add	x7, x8, x0
beq	x5, x0, set
jal	x20, loop_2
set:
sw	x8, 0(x3)
#jal	loop_1
lw	x1, 0x20(x0)		#limit
#lw	x1, 0x0(x1)
addi 	x3, x0, 0
lw	x4, 0x48(x0)
#lw	x4, 0x0(x4)
addi	x2, x0, 0
ADD:
addi	x2, x2, 1
blt	x2, x1, ADD
addi	x2, x0, 0
addi	x3, x3, 1
blt	x3, x4, ADD 

# restore
qt:
add	x1, x0, x14
add	x2, x0, x15
add	x3, x0, x16
add	x4, x0, x17
add	x5, x0, x18
add	x6, x0, x19
add	x7, x0, x0
add	x8, x0, x0
ret

addi 	x0, x0, 0
addi 	x0, x0, 0
addi 	x0, x0, 0
addi 	x0, x0, 0
addi 	x0, x0, 0
