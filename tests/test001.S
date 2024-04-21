
	.data
	.global sexp_string_buffer
scanline: .asciz "something bad happened"
sexp_string_buffer: .int 0


	.global eval
instr_begin: .int 0

# Stack space
.align 4
stack:	.zero 4096
.align 4
global_data: .zero 4096

.global __start_custom_data
__start_custom_data: .int 0;
.global __stop_custom_data
__stop_custom_data: .int 0;

	.text

	.macro FIX_BOX dst
	sall 	$1, \dst
	xorl 	$1, \dst
	.endm

	.macro FIX_UNB dst
	xorl 	$1, \dst
	sarl 	$1, \dst
	.endm

	.macro	POP dst
	subl	$4, %esi
	movl	(%esi), \dst
	.endm

	.macro	POP2 dst1 dst2
	POP	\dst1
	POP	\dst2
	.endm

	.macro	PUSH dst
	movl	\dst, (%esi)
	addl	$4, %esi
	.endm
  
	.global main
	main:
  Label_0:
Label_9:
Label_a:
Label_f:
Label_14:
Label_15:
Label_16:
Label_1b:
Label_1c:
Label_21:
Label_26:
Label_2b:

	POP2 	%eax %ebx
	FIX_UNB %eax
	FIX_UNB %ebx
  
	cltd
	idiv	%ebx
        
	FIX_BOX %eax
	PUSH	%eax
        Label_2c:
Label_31:

	POP2 	%eax %ebx
	FIX_UNB %eax
	FIX_UNB %ebx
  
	cltd
	idiv	%ebx
        
	FIX_BOX %eax
	PUSH	%eax
        Label_32:
Label_37:
Label_38:
Label_3d:
Label_42:

	POP		%ebx
	pushl	%ebx
	call	Lwrite
	popl	%ebx
	FIX_BOX	%eax
	PUSH	%eax
        Label_43:
Label_44:

