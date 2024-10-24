#-------------------------------------------------------------------------------
# author: Kacper Siemionek
# date : 2024-05-14
# description : RISC-V program generating a barcode of given string
#-------------------------------------------------------------------------------

.include "img_info.asm"

	.data
imgInfo: .space	28	# image descriptor

	.align 2		# word boundary alignment
dummy:		.space 2
bmpHeader:	.space	BMPHeader_Size
		.space  1024	# enough for 256 lookup table entries

	.align 2
imgData: 	.space	MAX_IMG_SIZE

ifname:		.asciz "code128_template.bmp"
ofname: 	.asciz "test.bmp"
string1:	.asciz "ARKOx86"
string2:	.asciz "Kacper Siemionek 331430"
string3:	.asciz "WEiTI"
		.text

main:
	la a0, imgInfo
	la t0, ifname
	sw t0, ImgInfo_fname(a0)
	la t0, bmpHeader
	sw t0, ImgInfo_hdrdat(a0)
	la t0, imgData
	sw t0, ImgInfo_imdat(a0)
	jal	read_bmp
	bnez a0, main_failure

	la a0, imgInfo
	la a1, string1		# options: string1, string2, string3

	# line width: 1 - 30 characters, 2 - 13 characters,
	# 3 - 7 characters, 4 - 4 characters.
	# using code128_template.bmp (377 pixels width)

	li a2, 1		
	jal generate_barcode
	beqz a4, main_failure

	la a0, imgInfo
	la t0, ofname
	sw t0, ImgInfo_fname(a0)
	jal save_bmp

main_failure:
	li a7, 10
	ecall
