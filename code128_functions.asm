#-------------------------------------------------------------------------------
# author: Kacper Siemionek
# date : 2024-05-14
# description : Code128 functions for drawing lines in bmp file,
# 		reading given string and generating a barcode.
#-------------------------------------------------------------------------------
.include "img_info.asm"
.globl generate_barcode
#.globl check_length

	.data
code128:	.half	0x6cc, 0x66c, 0x666, 0x498, 0x48c, 0x44c,
			0x4c8, 0x4c4, 0x464, 0x648, 0x644, 0x624,
			0x59c, 0x4dc, 0x4ce, 0x5cc, 0x4ec, 0x4e6,
			0x672, 0x65c, 0x64e, 0x6e4, 0x674, 0x76e,
			0x74c, 0x72c, 0x726, 0x764, 0x734, 0x732,
			0x6d8, 0x6c6, 0x636, 0x518, 0x458, 0x446,
			0x588, 0x468, 0x462, 0x688, 0x628, 0x622,
			0x5b8, 0x58e, 0x46e, 0x5d8, 0x5c6, 0x476,
			0x776, 0x68e, 0x62e, 0x6e8, 0x6e2, 0x6ee,
			0x758, 0x746, 0x716, 0x768, 0x762, 0x71a,
			0x77a, 0x642, 0x78a, 0x530, 0x50c, 0x4b0,
			0x486, 0x42c, 0x426, 0x590, 0x584, 0x4d0,
			0x4c2, 0x434, 0x432, 0x612, 0x650, 0x7ba,
			0x614, 0x47a, 0x53c, 0x4bc, 0x49e, 0x5e4,
			0x4f4, 0x4f2, 0x7a4, 0x794, 0x792, 0x6de,
			0x6f6, 0x7b6, 0x578, 0x51e, 0x45e, 0x5e8,
			0x5e2, 0x7a8, 0x7a2, 0x5de, 0x5ee, 0x75e

	.text

# ============================================================================
# draw_line - draws a single line
# arguments:
#	a0 - address of ImgInfo image descriptor
#	a1 - x coordinate
#	a2 - line width
# 	a3 - line color
# return value: none

draw_line_start:
	addi sp, sp, -16
	sw t6, 12(sp)		# push t6
	sw t1, 8(sp)		# push t1
	sw t0, 4(sp)		# push t0
	sw ra, 0(sp)		# push ra

	lw a2, ImgInfo_height(a0)
	addi a2, a2, -1

draw_line:
	lw a2, ImgInfo_height(a0)
	addi a2, a2, -1
	beqz a3, draw_line_next	# if color bit == 0 skip drawing part


draw_pixels:
	lw t1, ImgInfo_lbytes(a0)
	mul t0, t1, a2  	# t0 = y * linebytes
	srai t1, a1, 3		# t1 = x / 8 (pixel offset in line)
	add t0, t0, t1  	# t0 is offset of the pixel

	lw t1, ImgInfo_imdat(a0) # address of image data
	add t0, t0, t1 		# t0 is address of the pixel

	andi t1, a1, 0x7  	# t1 = x % 8 (pixel offset within the byte)

	lbu t2,(t0)		# load 8 pixels

	sll  t2, t2, t1		# pixel bit on the msb of the lowest byte

	li t3, 0x80  		# pixel mask

	not  t3, t3
	and  t2, t2, t3
	srl  t2, t2, t1
	sb   t2, (t0)		# store 8 pixels

	beqz a2, draw_line_next # jump if height == 0
	addi a2, a2, -1
	j draw_pixels

draw_line_next:
	addi t6, t6, -1
	beqz t6, draw_line_exit
	addi a1, a1, 1
	j draw_line

draw_line_exit:
	lw ra, 0(sp)		# pop ra
	lw t0, 4(sp)		# pop t0
	lw t1, 8(sp)		# pop t1
	lw t6, 12(sp)
	addi sp, sp, 16
	jr ra

# ============================================================================
# generate_barcode - generates barcode in a bmp file
# arguments:
#	a0 - address of ImgInfo image descriptor
#	a1 - address of the string
# 	a2 - single line width
# return value: none

generate_barcode:
	addi sp, sp, -12
	sw a1, 8(sp)		# push a1 (string)
	sw ra, 4(sp)		# push ra
	sw s1, 0(sp)		# push s1
	mv s1, a0 		# preserve imgInfo for further use
	mv t6, a2 		# preserve line width for further use


check_length:
	lw t0, ImgInfo_width(a0)# image width
	li t1, 11		# start code, checksum and characters length
	li t2, 13		# stop code length
	li t3, 10		# quiet zone
	li t4, 0		# string length
	li a5, 0		# result

	mul t1, t1, a2
	mul t2, t2, a2
	mul t3, t3, a2

count_chars:
	lbu a2, (a1)
	beqz a2, count_stop
	
	addi a1, a1, 1
	addi t4, t4, 1
	j count_chars

count_stop:
	mul t4, t4, t1		# total length (pixels)
	sub t0, t0, t3		# - quiet zone
	sub t0, t0, t1		# - start code
	sub t0, t0, t4		# - characters
	sub t0, t0, t3		# - checksum
	sub t0, t0, t2		# - stop code
	
	blt t0, zero, draw_exit
	li a5, 1
	li a1, 10		# quiet zone
	mul a1, a1, t6
	li t0, 11		# counter
	li t1, 0x690		# start B code

draw_start:
	mv a3, t1		
	andi a3, a3, 0x400	# leave only 11th bit

	mv a0, s1
	jal draw_line_start

next_bit:
	addi a1, a1, 1
	addi t0, t0, -1
	slli t1, t1, 1
	bnez t0, draw_start	# check if we drew all 11 bits

	lw t4, 8(sp)		# string address

convert_char:
	lbu t1, (t4)		# load next character
	beqz t1, count_checksum # if character == /0 stop drawing characters

	addi t1, t1, -32 	# convert ascii value to code128
	slli t1, t1, 1		# code128 * 2 = shift
	la t2, code128		# code128 list pointer
	add t2, t2, t1		# address of our character code

	lh t1, (t2)		# load character code
	li t0, 11		# counter

draw_char:
	mv a3, t1
	andi a3, a3, 0x400	# leave only 11th bit

	mv a0, s1
	jal draw_line_start

next_char_bit:
	addi a1, a1, 1
	addi t0, t0, -1
	slli t1, t1, 1
	bnez t0, draw_char	# check if we drew all 11 bits
	addi t4, t4, 1		# next character address
	j convert_char

count_checksum:
	lw t4, 8(sp)		# string address
	li t0, 1		# position
	mv t5, zero		# checksum start value

next_char:
	lbu t1, (t4)		# load next character
	beqz t1, checksum_convert # load next character counting checksum
	addi t1, t1, -32	# convert ascii value to code128
	mul t1, t1, t0		# multiply character value by its position
	addi t0, t0, 1		# increment position
	add t5, t5, t1		# update checksum
	addi t4, t4, 1		# next character address
	j next_char

checksum_convert:
	li t0, 103		# modulo int
	addi t5, t5, 1		# checksum + 1
	rem t5, t5, t0		# modulo 103 of checksum
	slli t5, t5, 1		# checksum * 2 = shift
	la t2, code128		# code128 list pointer
	add t2, t2, t5		# address of the character with checksum value

	lh t5, (t2)		# load character code
	li t0, 11		# counter

draw_checksum:
	mv a3, t5
	andi a3, a3, 0x400	# leave only 11th bit

	mv a0, s1
	jal draw_line_start

next_checksum_bit:
	addi a1, a1, 1
	addi t0, t0, -1
	slli t5, t5, 1
	bnez t0, draw_checksum 	# check if we drew all 11 bits

	li a4, 0x1000		# stop code mask
	li t1, 0x18EB		# stop code
	li t0, 13		# counter

draw_stop:
	mv a3, t1
	and a3, a3, a4		# leave only 13th bit

	mv a0, s1
	jal draw_line_start

next_stop_bit:
	addi a1, a1, 1
	addi t0, t0, -1
	slli t1, t1, 1
	bnez t0, draw_stop 	# check if we drew all 13 bits

draw_exit:
	lw s1, 0(sp)		# pop s1
	lw ra, 4(sp)		# pop ra
	lw a1, 8(sp)		# string address
	addi sp, sp, 12
	jr ra
