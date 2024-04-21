```
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
  movl $stack, %esi
  call Label_0
  xorl %eax, %eax
  ret
  Label_0:
 movl $2, %ecx
 movl $0, %edx
pushl %ebp
	movl %esp, %ebp
	lea (,%edx,4), %edx
	subl %edx, %esp
Label_9:

	call	Lread
	PUSH	%eax
Label_a:
 movl $1, %ecx
Label_f:
	movl 	-4(%esi), %eax
	movl $0, %ecx
	movl	%eax, global_data(, %ecx, 4)
Label_14:

	POP %eax
Label_15:

	call	Lread
	PUSH	%eax
Label_16:
	movl 	-4(%esi), %eax
	movl $1, %ecx
	movl	%eax, global_data(, %ecx, 4)
Label_1b:

	POP %eax
Label_1c:
 movl $2, %ecx
Label_21:
	movl $0, %ecx
	movl	global_data(, %ecx, 4), %eax
PUSH %eax
Label_26:
	movl $1, %ecx
	movl	global_data(, %ecx, 4), %eax
PUSH %eax
Label_2b:

    POP2 	%eax %ebx
    FIX_UNB %eax
    FIX_UNB %ebx
    
	addl	%eax, %ebx
	movl	%ebx, %eax
        
  FIX_BOX %eax
  PUSH	%eax
        Label_2c:
	movl $0, %ecx
	movl	global_data(, %ecx, 4), %eax
PUSH %eax
Label_31:
	movl $1, %ecx
	movl	global_data(, %ecx, 4), %eax
PUSH %eax
Label_36:

    POP2 	%eax %ebx
    FIX_UNB %eax
    FIX_UNB %ebx
    
	subl	%eax, %ebx
	movl	%ebx, %eax
        
  FIX_BOX %eax
  PUSH	%eax
        Label_37:

    POP2 	%eax %ebx
    FIX_UNB %eax
    FIX_UNB %ebx
    
	addl	%eax, %ebx
	movl	%ebx, %eax
        
  FIX_BOX %eax
  PUSH	%eax
        Label_38:
	movl $0, %ecx
	movl	global_data(, %ecx, 4), %eax
PUSH %eax
Label_3d:
	movl $1, %ecx
	movl	global_data(, %ecx, 4), %eax
PUSH %eax
Label_42:

    POP2 	%eax %ebx
    FIX_UNB %eax
    FIX_UNB %ebx
    
	subl	%eax, %ebx
	movl	%ebx, %eax
        
  FIX_BOX %eax
  PUSH	%eax
        Label_43:
	movl $0, %ecx
	movl	global_data(, %ecx, 4), %eax
PUSH %eax
Label_48:
	movl $1, %ecx
	movl	global_data(, %ecx, 4), %eax
PUSH %eax
Label_4d:

    POP2 	%eax %ebx
    FIX_UNB %eax
    FIX_UNB %ebx
    
	addl	%eax, %ebx
	movl	%ebx, %eax
        
  FIX_BOX %eax
  PUSH	%eax
        Label_4e:

    POP2 	%eax %ebx
    FIX_UNB %eax
    FIX_UNB %ebx
    
	subl	%eax, %ebx
	movl	%ebx, %eax
        
  FIX_BOX %eax
  PUSH	%eax
        Label_4f:

    POP2 	%eax %ebx
    FIX_UNB %eax
    FIX_UNB %ebx
    
	addl	%eax, %ebx
	movl	%ebx, %eax
        
  FIX_BOX %eax
  PUSH	%eax
        Label_50:
	movl 	-4(%esi), %eax
	movl $2, %ecx
	movl	%eax, global_data(, %ecx, 4)
Label_55:

	POP %eax
Label_56:
 movl $3, %ecx
Label_5b:
	movl $2, %ecx
	movl	global_data(, %ecx, 4), %eax
PUSH %eax
Label_60:

	POP		%ebx
	pushl	%ebx
	call	Lwrite
	popl	%ebx
	FIX_BOX	%eax
	PUSH	%eax
        Label_61:

	leave
	retl
Label_62:
```

