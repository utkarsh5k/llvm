; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-- | FileCheck %s

; CodeGenPrepare is expected to form overflow intrinsics to improve DAG/isel.

define i1 @usubo_ult_i64(i64 %x, i64 %y, i64* %p) nounwind {
; CHECK-LABEL: usubo_ult_i64:
; CHECK:       # %bb.0:
; CHECK-NEXT:    subq %rsi, %rdi
; CHECK-NEXT:    movq %rdi, (%rdx)
; CHECK-NEXT:    setb %al
; CHECK-NEXT:    retq
  %s = sub i64 %x, %y
  store i64 %s, i64* %p
  %ov = icmp ult i64 %x, %y
  ret i1 %ov
}

; Verify insertion point for single-BB. Toggle predicate.

define i1 @usubo_ugt_i32(i32 %x, i32 %y, i32* %p) nounwind {
; CHECK-LABEL: usubo_ugt_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    cmpl %edi, %esi
; CHECK-NEXT:    seta %al
; CHECK-NEXT:    subl %esi, %edi
; CHECK-NEXT:    movl %edi, (%rdx)
; CHECK-NEXT:    retq
  %ov = icmp ugt i32 %y, %x
  %s = sub i32 %x, %y
  store i32 %s, i32* %p
  ret i1 %ov
}

; Constant operand should match.

define i1 @usubo_ugt_constant_op0_i8(i8 %x, i8* %p) nounwind {
; CHECK-LABEL: usubo_ugt_constant_op0_i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    movb $42, %cl
; CHECK-NEXT:    subb %dil, %cl
; CHECK-NEXT:    cmpb $42, %dil
; CHECK-NEXT:    seta %al
; CHECK-NEXT:    movb %cl, (%rsi)
; CHECK-NEXT:    retq
  %s = sub i8 42, %x
  %ov = icmp ugt i8 %x, 42
  store i8 %s, i8* %p
  ret i1 %ov
}

; Compare with constant operand 0 is canonicalized by commuting, but verify match for non-canonical form.

define i1 @usubo_ult_constant_op0_i16(i16 %x, i16* %p) nounwind {
; CHECK-LABEL: usubo_ult_constant_op0_i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    movl $43, %ecx
; CHECK-NEXT:    subl %edi, %ecx
; CHECK-NEXT:    cmpw $43, %di
; CHECK-NEXT:    seta %al
; CHECK-NEXT:    movw %cx, (%rsi)
; CHECK-NEXT:    retq
  %s = sub i16 43, %x
  %ov = icmp ult i16 43, %x
  store i16 %s, i16* %p
  ret i1 %ov
}

; Subtract with constant operand 1 is canonicalized to add.

define i1 @usubo_ult_constant_op1_i16(i16 %x, i16* %p) nounwind {
; CHECK-LABEL: usubo_ult_constant_op1_i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    movl %edi, %ecx
; CHECK-NEXT:    addl $-44, %ecx
; CHECK-NEXT:    cmpw $44, %di
; CHECK-NEXT:    setb %al
; CHECK-NEXT:    movw %cx, (%rsi)
; CHECK-NEXT:    retq
  %s = add i16 %x, -44
  %ov = icmp ult i16 %x, 44
  store i16 %s, i16* %p
  ret i1 %ov
}

define i1 @usubo_ugt_constant_op1_i8(i8 %x, i8* %p) nounwind {
; CHECK-LABEL: usubo_ugt_constant_op1_i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    cmpb $45, %dil
; CHECK-NEXT:    setb %al
; CHECK-NEXT:    addb $-45, %dil
; CHECK-NEXT:    movb %dil, (%rsi)
; CHECK-NEXT:    retq
  %ov = icmp ugt i8 45, %x
  %s = add i8 %x, -45
  store i8 %s, i8* %p
  ret i1 %ov
}

; Special-case: subtract 1 changes the compare predicate and constant.

define i1 @usubo_eq_constant1_op1_i32(i32 %x, i32* %p) nounwind {
; CHECK-LABEL: usubo_eq_constant1_op1_i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    # kill: def $edi killed $edi def $rdi
; CHECK-NEXT:    leal -1(%rdi), %ecx
; CHECK-NEXT:    testl %edi, %edi
; CHECK-NEXT:    sete %al
; CHECK-NEXT:    movl %ecx, (%rsi)
; CHECK-NEXT:    retq
  %s = add i32 %x, -1
  %ov = icmp eq i32 %x, 0
  store i32 %s, i32* %p
  ret i1 %ov
}

; Verify insertion point for multi-BB.

declare void @call(i1)

define i1 @usubo_ult_sub_dominates_i64(i64 %x, i64 %y, i64* %p, i1 %cond) nounwind {
; CHECK-LABEL: usubo_ult_sub_dominates_i64:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    testb $1, %cl
; CHECK-NEXT:    je .LBB7_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movq %rdi, %rax
; CHECK-NEXT:    subq %rsi, %rax
; CHECK-NEXT:    movq %rax, (%rdx)
; CHECK-NEXT:    testb $1, %cl
; CHECK-NEXT:    je .LBB7_2
; CHECK-NEXT:  # %bb.3: # %end
; CHECK-NEXT:    cmpq %rsi, %rdi
; CHECK-NEXT:    setb %al
; CHECK-NEXT:    retq
; CHECK-NEXT:  .LBB7_2: # %f
; CHECK-NEXT:    movl %ecx, %eax
; CHECK-NEXT:    retq
entry:
  br i1 %cond, label %t, label %f

t:
  %s = sub i64 %x, %y
  store i64 %s, i64* %p
  br i1 %cond, label %end, label %f

f:
  ret i1 %cond

end:
  %ov = icmp ult i64 %x, %y
  ret i1 %ov
}

define i1 @usubo_ult_cmp_dominates_i64(i64 %x, i64 %y, i64* %p, i1 %cond) nounwind {
; CHECK-LABEL: usubo_ult_cmp_dominates_i64:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    pushq %rbp
; CHECK-NEXT:    pushq %r15
; CHECK-NEXT:    pushq %r14
; CHECK-NEXT:    pushq %rbx
; CHECK-NEXT:    pushq %rax
; CHECK-NEXT:    movl %ecx, %ebp
; CHECK-NEXT:    testb $1, %bpl
; CHECK-NEXT:    je .LBB8_2
; CHECK-NEXT:  # %bb.1: # %t
; CHECK-NEXT:    movq %rdx, %r14
; CHECK-NEXT:    movq %rsi, %r15
; CHECK-NEXT:    movq %rdi, %rbx
; CHECK-NEXT:    xorl %edi, %edi
; CHECK-NEXT:    cmpq %rsi, %rbx
; CHECK-NEXT:    setb %dil
; CHECK-NEXT:    callq call
; CHECK-NEXT:    subq %r15, %rbx
; CHECK-NEXT:    jae .LBB8_2
; CHECK-NEXT:  # %bb.4: # %end
; CHECK-NEXT:    setb %al
; CHECK-NEXT:    movq %rbx, (%r14)
; CHECK-NEXT:    jmp .LBB8_3
; CHECK-NEXT:  .LBB8_2: # %f
; CHECK-NEXT:    movl %ebp, %eax
; CHECK-NEXT:  .LBB8_3: # %f
; CHECK-NEXT:    addq $8, %rsp
; CHECK-NEXT:    popq %rbx
; CHECK-NEXT:    popq %r14
; CHECK-NEXT:    popq %r15
; CHECK-NEXT:    popq %rbp
; CHECK-NEXT:    retq
entry:
  br i1 %cond, label %t, label %f

t:
  %ov = icmp ult i64 %x, %y
  call void @call(i1 %ov)
  br i1 %ov, label %end, label %f

f:
  ret i1 %cond

end:
  %s = sub i64 %x, %y
  store i64 %s, i64* %p
  ret i1 %ov
}

