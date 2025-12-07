.text
  jal  main
  li   $v0, 10
  syscall
swap:
  addi $sp, $sp, -4
  sw   $ra, 0($sp)
  addi $sp, $sp, -4
  sw   $fp, 0($sp)
  move $fp, $sp
  lw   $t0, 8($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, 12($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $v1, 0($sp)
  addi $sp, $sp, 4
  lw   $v0, 0($sp)
  addi $sp, $sp, 4
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
main:
  addi $sp, $sp, -4
  sw   $ra, 0($sp)
  addi $sp, $sp, -4
  sw   $fp, 0($sp)
  move $fp, $sp
  addi $sp, $sp, -20
  li   $t0, 1
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 2
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -8($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  lw   $t0, -4($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -8($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  jal  swap
  addi $sp, $sp, 8
  sw   $v0, -4($fp)
  sw   $v1, -8($fp)
  lw   $t0, -4($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 2
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sne  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -8($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 1
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sne  $t0, $t1, $t0
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  or   $t0, $t1, $t0
  bnez $t0, _label_0
  b    _label_1
_label_0:
  la   $t0, _label_2
  move $a0, $t0
  li   $v0, 4
  syscall
_label_1:
  li   $a0, 8
  li   $v0, 9
  syscall
  move $t0, $v0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -12($fp)
  li   $t0, 10
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -12($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 0($t0)
  li   $a0, 8
  li   $v0, 9
  syscall
  move $t0, $v0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -16($fp)
  li   $t0, 20
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -16($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 0($t0)
  lw   $t0, -16($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -12($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 4($t0)
  lw   $t0, -12($fp)
  lw   $t0, 4($t0)
  lw   $t0, 0($t0)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 20
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sne  $t0, $t1, $t0
  bnez $t0, _label_3
  b    _label_4
_label_3:
  la   $t0, _label_5
  move $a0, $t0
  li   $v0, 4
  syscall
_label_4:
  lw   $t0, -12($fp)
  lw   $t0, 4($t0)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 0
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  seq  $t0, $t1, $t0
  bnez $t0, _label_6
  b    _label_7
_label_6:
  la   $t0, _label_8
  move $a0, $t0
  li   $v0, 4
  syscall
_label_7:
  li   $t0, 0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -12($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 4($t0)
  lw   $t0, -12($fp)
  lw   $t0, 4($t0)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 0
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sne  $t0, $t1, $t0
  bnez $t0, _label_9
  b    _label_10
_label_9:
  la   $t0, _label_11
  move $a0, $t0
  li   $v0, 4
  syscall
_label_10:
  li   $t0, 0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -20($fp)
  b    _label_12
_label_13:
  lw   $t0, -20($fp)
  addi $t0, $t0, 1
  sw   $t0, -20($fp)
_label_12:
  lw   $t0, -20($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 5
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  slt  $t0, $t1, $t0
  bnez $t0, _label_13
  lw   $t0, -20($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 5
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sne  $t0, $t1, $t0
  bnez $t0, _label_14
  b    _label_15
_label_14:
  la   $t0, _label_16
  move $a0, $t0
  li   $v0, 4
  syscall
_label_15:
  li   $t0, 0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -20($fp)
  b    _label_17
_label_18:
  lw   $t0, -20($fp)
  addi $t0, $t0, 1
  sw   $t0, -20($fp)
_label_17:
  lw   $t0, -20($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 5
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  slt  $t0, $t1, $t0
  bnez $t0, _label_18
  li   $t0, 1
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 2
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  add  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 3
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  mul  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 9
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sne  $t0, $t1, $t0
  bnez $t0, _label_19
  b    _label_20
_label_19:
  la   $t0, _label_21
  move $a0, $t0
  li   $v0, 4
  syscall
_label_20:
  li   $t0, 1
  seq  $t0, $t0, $zero
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 0
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  or   $t0, $t1, $t0
  bnez $t0, _label_22
  b    _label_23
_label_22:
  la   $t0, _label_24
  move $a0, $t0
  li   $v0, 4
  syscall
_label_23:
  addi $sp, $sp, 20
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
.data
_label_5:
  .asciiz "Struct link failed"
_label_8:
  .asciiz "Should not be nil"
_label_16:
  .asciiz "For loop failed"
_label_2:
  .asciiz "Swap failed"
_label_24:
  .asciiz "Logic failed"
_label_11:
  .asciiz "Should be nil"
_label_21:
  .asciiz "Math failed"
