# Various macro definitions
# fixnum arithmetics: make box for an integer
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


	.global eval
	.data
# Format string for debugging
fmt:	.string "%x\n"
instr_begin: .int 0

# Stack space
stack:	.zero 512

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
	xorl	%eax, %eax
	BYTE	%al
	movb	%al,%ah
	andb    $15,%al
	andb    $240,%ah
	shrb 	$4,%ah
# Outer switch
	movsx   %ah,%ebx
	movl    high(,%ebx,0x4),%ebx
	jmp    *%ebx

high: .int binop,trivial,ld,0,st,cond_jump,0,builtin

binop:
	SWITCH %al binops
binops:	.int 0,b_add,b_sub,b_mul,b_div,b_mod,b_lt,b_le,b_gt,b_ge,b_eq,b_neq,b_and,b_or

trivial:
	SWITCH %al trivials
trivials: .int bc_const,0,bc_sexp,bc_sti,bc_sta,bc_jmp,bc_end,0,bc_drop,bc_dup,0,bc_elem

st:
	SWITCH %al sts
sts: .int bc_st_g,bc_st_l,bc_st_a

ld:
	SWITCH %al lds
lds: .int bc_ld_g,bc_ld_l,bc_ld_a

cond_jump:
	SWITCH %al cond_jumps
# TODO: is bc_call ok here?
cond_jumps: .int bc_cjmpz,bc_cjmpnz,bc_begin,0,0,0,bc_call,bc_tag,bc_array,bc_fail,bc_line


builtin:
	SWITCH %al builtins
builtins: .int bc_read,bc_write,0,0,bc_array

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
	WORD %ecx
	POP 	%eax
	POP 	%ecx
	POP 	%edx
	pushl 	%edx
	pushl 	%ecx
	pushl 	%eax
	call 	Bsta
	PUSH	%eax
	addl	$12, %esp
	NEXT_ITER

bc_sexp:

    /* move hash to eax*/
    WORD	%eax
	addl	sexp_string_buffer, %eax
	pushl   %eax
	call	LtagHash
	FIX_BOX	%eax
	addl	$4, %esp

	/* push hash and args*/

	WORD 	%ecx
	movl	%ecx, %edx
	pushl	%eax
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
	movl	%ecx, %edx
sexp_pop_loop_begin:
	popl	%ebx
	decl	%edx
	jnz		sexp_pop_loop_begin
sexp_pop_loop_end:
	PUSH	%eax
	NEXT_ITER

bc_tag:
    WORD	%eax
	addl	sexp_string_buffer, %eax
	pushl   %eax
	call	LtagHash
	FIX_BOX	%eax
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
	/*  Maybe it should be 8, not 4 (resolve on merging vs Call)  */
	movl	4(%ebp, %ecx, 4), %eax
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
	/*  Maybe it should be 8, not 4 (resolve on merging vs Call)  */
	movl	%eax, 8(%ebp, %ecx, 4)
	NEXT_ITER

bc_cjmpz:
	WORD %ecx
	POP	%eax
	FIX_UNB	%eax
	addl	instr_begin, %ecx
	testl	%eax, %eax
	je	not_go1
	movl	%ecx, %edi
not_go1:
	NEXT_ITER

bc_cjmpnz:
	WORD %ecx
	POP	%eax
	FIX_UNB	%eax
	addl	instr_begin, %ecx
	testl	%eax, %eax
	jne	not_go2
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
	test	%edx, %edx
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
	movl	%ecx, %edx
	test	%edx, %edx
	jz 		array_pop_loop_end
array_pop_loop_begin:
	popl	%ebx
	decl	%edx
	jnz		array_pop_loop_begin
array_pop_loop_end:
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
	PUSH	%eax
	NEXT_ITER

bc_read:
	call	Lread
	PUSH	%eax
	NEXT_ITER

# TODO: need to differ builtins calls and user-defined function-calls
bc_call:
	WORD %ecx /* label */
	WORD %edx /* args number */
	pusha
	negl %edx
	addl	instr_begin, %ecx
	movl	%ecx, %edi
	lea	(%esi, %edx, 4), %eax
for:
	pushl	4(%eax)
	addl	$4, %eax
	cmp %eax, %esi
	jne for
	call entry_point
	popa
	NEXT_ITER

bc_begin:
	WORD %ecx /* argument number */
	WORD %edx /* locals_number */
	pushl %ebp
	movl %esp, %ebp
	subl %edx, %esp
	addl %edx, %esi
	NEXT_ITER

bc_end:
	leave
	ret /* Return from lama function */

	.data
	.global sexp_string_buffer
scanline: .asciz "something bad happened"
global_data: .skip 4 * 1000
sexp_string_buffer: .int
