# Various macro definitions
# fixnum arithmetics: make box for an integer
eax_fmt:	.string "eax: 0x%x\n"
ebx_fmt:	.string "ebx: 0x%x\n"
ecx_fmt:	.string "ecx: 0x%x\n"
edx_fmt:	.string "edx: 0x%x\n"
edi_fmt:	.string "edi: 0x%x\n"
esp_fmt:	.string "esp: 0x%x\n"
ebp_fmt:	.string "ebp: 0x%x\n"

	.macro PRINT_REG fmt reg
	pusha
	pushl \reg
	pushl $\fmt
	call Lprintf_unsafe
	addl $8, %esp
	popa
	.endm

	.macro NEXT_ITER
	jmp entry_point
	.endm
	.macro FIX_BOX dst
	sall 	$1, \dst
	xorl 	$1, \dst
	.endm

# fixnum arithmetics: unbox integer
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

	.macro	BYTE dst
	movb	(%edi), \dst
	inc	%edi
	.endm

	.macro	WORD dst
	movl	(%edi), \dst
	addl	$4, %edi
	.endm

	.macro SWITCH flag table
	movsx   \flag,%ebx
	movl    \table(,%ebx,0x4),%ebx
	jmp     *%ebx
	.endm

	.text

# Taking the pointer to the bytecode buffer
# as an argument

eval:
# Saving callee's frame pointer
	pushl	%ebp

# Moving bytecode pointer to %edi
# %edi now plays a role of instruction
# pointer
	movl	8(%esp), %edi
	movl 	%edi, instr_begin

# Moving stack address to %esi
# %esi now plays a role of stack pointer
	movl	$stack, %esi

	call entry_point
# Restoring callee's frame pointer
	popl	%ebp

# Returning
	ret

entry_point:
# Decode next insn
	movl %edi, %edx
	xorl	%eax, %eax
	BYTE	%al
	movb	%al,%ah
	andb    $15,%al
	andb    $240,%ah
	shrb 	$4,%ah

	subl instr_begin, %edx
#	PRINT_REG edi_fmt %edx
#	PRINT_REG eax_fmt %eax
#	PRINT_REG esp_fmt %esp
#	PRINT_REG ebp_fmt %ebp

# Outer switch
	movsx   %ah,%ebx
	movl    high(,%ebx,0x4),%ebx
	jmp    *%ebx

high: .int binop,trivial,ld,lda,st,cond_jump,0,builtin

binop:
	SWITCH %al binops
binops:	.int 0,b_add,b_sub,b_mul,b_div,b_mod,b_lt,b_le,b_gt,b_ge,b_eq,b_neq,b_and,b_or

trivial:
	SWITCH %al trivials
trivials: .int bc_const,bc_string,bc_sexp,bc_sti,bc_sta,bc_jmp,bc_end,0,bc_drop,bc_dup,0,bc_elem

st:
	SWITCH %al sts
sts: .int bc_st_g,bc_st_l,bc_st_a

lda:
	SWITCH %al ldas
ldas: .int bc_lda_g,bc_lda_l,bc_lda_a

ld:
	SWITCH %al lds
lds: .int bc_ld_g,bc_ld_l,bc_ld_a

cond_jump:
	SWITCH %al cond_jumps
cond_jumps: .int bc_cjmpz,bc_cjmpnz,bc_begin,0,0,0,bc_call,bc_tag,bc_pat_array,bc_fail,bc_line


builtin:
	SWITCH %al builtins
builtins: .int bc_read,bc_write,bc_length,0,bc_array

b_add:	POP2 	%eax %ebx
	FIX_UNB %eax
	FIX_UNB %ebx
	addl	%ebx, %eax
	FIX_BOX %eax
	PUSH	%eax
	NEXT_ITER

b_sub:	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB %ebx
	subl	%eax, %ebx
	FIX_BOX %ebx
	PUSH	%ebx
	NEXT_ITER

b_mul:	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB %ebx
	imul	%ebx
	FIX_BOX %eax
	PUSH	%eax
	NEXT_ITER

b_div:	POP2	%ebx %eax
	FIX_UNB %eax
	FIX_UNB %ebx
	cltd
	idiv	%ebx
	FIX_BOX %eax
	PUSH	%eax
	NEXT_ITER

b_mod:	POP2	%ebx %eax
	FIX_UNB %eax
	FIX_UNB %ebx
	cltd
	idiv	%ebx
	FIX_BOX %edx
	PUSH	%edx
	NEXT_ITER

b_eq: 	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB %ebx
	xorl	%edx, %edx
	cmpl	%eax, %ebx
	seteb	%dl
	FIX_BOX %edx
	PUSH 	%edx
	NEXT_ITER

b_neq: 	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB %ebx
	xorl	%edx, %edx
	cmpl	%eax, %ebx
	setneb	%dl
	FIX_BOX %edx
	PUSH 	%edx
	NEXT_ITER

b_lt: 	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB	%ebx
	xorl	%edx, %edx
	cmpl	%eax, %ebx
	setlb	%dl
	FIX_BOX %edx
	PUSH	%edx
	NEXT_ITER

b_le:	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB	%ebx
	xorl	%edx, %edx
	cmpl	%eax, %ebx
	setleb	%dl
	FIX_BOX %edx
	PUSH	%edx
	NEXT_ITER

b_gt: 	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB	%ebx
	xorl	%edx, %edx
	cmpl	%eax, %ebx
	setgb	%dl
	FIX_BOX %edx
	PUSH	%edx
	NEXT_ITER

b_ge:	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB	%ebx
	xorl	%edx, %edx
	cmpl	%eax, %ebx
	setgeb	%dl
	FIX_BOX %edx
	PUSH	%edx
	NEXT_ITER

b_and:	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB	%ebx
	andl	%eax, %ebx
	FIX_BOX %ebx
	PUSH	%ebx
	NEXT_ITER

b_or:	POP2	%eax %ebx
	FIX_UNB %eax
	FIX_UNB	%ebx
	orl		%eax, %ebx
	FIX_BOX %ebx
	PUSH	%ebx
	NEXT_ITER


/* some trivial binops */

bc_drop:
	POP %eax
	NEXT_ITER

bc_dup:
	POP 	%eax
	PUSH	%eax
	PUSH	%eax
	NEXT_ITER

bc_sti:
	WORD %ecx
	POP	%eax
	POP	%ecx
	movl %eax, (%ecx)
	PUSH %eax
	NEXT_ITER

bc_sta:
	POP	%eax # value
	POP	%ecx # index | address
	movl %ecx, %edx # index | address
	movl %ecx, %ebx
	andl $1, %ebx
	jz two_args
			 # ecx index now
	POP	%edx # address
two_args: 	# ecx address now
	pushl	%edx
	pushl 	%ecx
	pushl 	%eax
	call	Bsta
	PUSH	%eax
	addl	$12, %esp
	NEXT_ITER

bc_sexp:

    /* move hash to eax*/
    WORD	%eax
	addl	sexp_string_buffer, %eax
	pushl   %eax
	call	LtagHash
	addl	$4, %esp

	/* push hash and args*/

	WORD 	%ecx
	movl	%ecx, %edx
	pushl	%eax
	testl %edx, %edx
	jz sexp_push_loop_end
sexp_push_loop_begin:
	POP		%ebx
	pushl	%ebx
	decl	%edx
	jnz		sexp_push_loop_begin
sexp_push_loop_end:
    /* push (n + 1) */
	incl	%ecx
	FIX_BOX	%ecx
	pushl 	%ecx
	call	Bsexp
	/* get back number of args and pop them */
	popl	%ecx
	FIX_UNB	%ecx
	lea (%esp, %ecx, 4), %esp
	PUSH	%eax
	NEXT_ITER

bc_tag:
    WORD	%eax
	addl	sexp_string_buffer, %eax
	pushl   %eax
	call	LtagHash
	addl	$4, %esp
	WORD 	%ecx
	FIX_BOX	%ecx
	POP 	%edx
	pushl	%ecx
	pushl	%eax
	pushl 	%edx
	call 	Btag
	PUSH	%eax
	addl	$12, %esp
	NEXT_ITER

bc_pat_array:
	WORD 	%ecx
	FIX_BOX	%ecx
	POP 	%edx
	pushl	%ecx
	pushl 	%edx
	call 	Barray_patt
	PUSH	%eax
	addl	$8, %esp
	NEXT_ITER

bc_const:
	WORD %ecx
	FIX_BOX	%ecx
	PUSH 	%ecx
	NEXT_ITER

bc_line:
	WORD %ecx
	NEXT_ITER

bc_fail:
	pushl	$scanline
# Runtime call, it terminate all process with 255 code
	call	failure

bc_ld_g:
	WORD %ecx
	movl	global_data(, %ecx, 4), %eax
	PUSH	%eax
	NEXT_ITER

bc_ld_l:
	WORD %ecx
	negl	%ecx
	movl	-4(%ebp, %ecx, 4), %eax
	PUSH	%eax
	NEXT_ITER

bc_ld_a:
	WORD %ecx
	movl	8(%ebp, %ecx, 4), %eax
	PUSH	%eax
	NEXT_ITER

bc_lda_g:
	WORD %ecx
	lea global_data(, %ecx, 4), %eax
	PUSH %eax
	NEXT_ITER

bc_lda_l:
	WORD %ecx
	negl	%ecx
	lea	-4(%ebp, %ecx, 4), %eax
	PUSH	%eax
	NEXT_ITER

bc_lda_a:
	WORD %ecx
	lea	8(%ebp, %ecx, 4), %eax
	PUSH	%eax
	NEXT_ITER

bc_st_g:
	WORD %ecx
	movl 	-4(%esi), %eax
	movl	%eax, global_data(, %ecx, 4)
	NEXT_ITER

bc_st_l:
	WORD %ecx
	negl	%ecx
	movl 	-4(%esi), %eax
	movl	%eax, -4(%ebp, %ecx, 4)
	NEXT_ITER

bc_st_a:
	WORD %ecx
	movl 	-4(%esi), %eax
	movl	%eax, 8(%ebp, %ecx, 4)
	NEXT_ITER

bc_cjmpz:
	WORD %ecx
	POP	%eax
	FIX_UNB	%eax
	testl	%eax, %eax
	jnz	not_go1
	addl	instr_begin, %ecx
	movl	%ecx, %edi
not_go1:
	NEXT_ITER

bc_cjmpnz:
	WORD %ecx
	POP	%eax
	FIX_UNB	%eax
	addl	instr_begin, %ecx
	testl	%eax, %eax
	jz	not_go2
	movl	%ecx, %edi
not_go2:
	NEXT_ITER

bc_jmp:
	WORD %ecx
	addl	instr_begin, %ecx
	movl	%ecx, %edi
	NEXT_ITER

bc_array:
	WORD 	%ecx
	movl	%ecx, %edx
	testl	%edx, %edx
	jz 		array_push_loop_end
array_push_loop_begin:
	POP		%ebx
	pushl	%ebx
	decl	%edx
	jnz		array_push_loop_begin
array_push_loop_end:
	FIX_BOX	%ecx
	pushl 	%ecx
	call	Barray
	popl	%ecx
	FIX_UNB	%ecx
	lea (%esp, %ecx, 4), %esp
	PUSH	%eax
	NEXT_ITER

bc_length:
	POP		%ebx
	pushl	%ebx
	call	Llength
	popl	%ebx
	PUSH	%eax
	NEXT_ITER

bc_string:
    WORD	%eax
	addl	sexp_string_buffer, %eax
	pushl   %eax
	call	Bstring
	add		$4, %esp
	PUSH	%eax
	NEXT_ITER

bc_elem:
# store arguments {
	POP		%ebx
	pushl	%ebx
	POP		%ebx
	pushl	%ebx
# }
	call	Belem
# pop arguments {
	popl	%ebx
	popl	%ebx
# }
	PUSH 	%eax
	NEXT_ITER

bc_write:
	POP		%ebx
	pushl	%ebx
	call	Lwrite
	popl	%ebx
	FIX_BOX	%eax
	PUSH	%eax
	NEXT_ITER

bc_read:
	call	Lread
	PUSH	%eax
	NEXT_ITER

bc_call:
	WORD %edx /* label */
	WORD %ecx /* args number */

	pushl %eax
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %edi

	negl %ecx
	lea (%esi, %ecx, 4), %eax
	pushl %ebp
	movl %esp, %ebp
for:
	cmpl %eax, %esi
	je after
	POP %ebx
	pushl %ebx
	jmp for
after:

	addl	instr_begin, %edx
	movl	%edx, %edi

	call entry_point

	movl %ebp, %esp
	popl %ebp

	popl %edi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax

	NEXT_ITER

bc_begin:
	WORD %ecx /* argument number */
	WORD %edx /* locals_number */
	pushl %ebp
	movl %esp, %ebp
	lea (,%edx,4), %edx
	subl %edx, %esp
	NEXT_ITER

bc_end:
	leave
	retl /* Return from lama function */


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
