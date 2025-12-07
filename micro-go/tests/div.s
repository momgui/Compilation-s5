.text
  jal  main
  li   $v0, 10
  syscall
div1:
  addi $sp, $sp, -4
  sw   $ra, 0($sp)
  addi $sp, $sp, -4
  sw   $fp, 0($sp)
  move $fp, $sp
  lw   $t0, 12($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, 8($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  slt  $t0, $t1, $t0
  bnez $t0, _label_5
  addi $sp, $sp, -8
  lw   $t0, 12($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, 8($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sub  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, 8($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  jal  div1
  addi $sp, $sp, 8
  sw   $v0, -4($fp)
  sw   $v1, -8($fp)
  lw   $t0, -4($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 1
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  add  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -8($fp)
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
  addi $sp, $sp, 8
  b    _label_6
_label_5:
  li   $t0, 0
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
_label_6:
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
div2:
  addi $sp, $sp, -4
  sw   $ra, 0($sp)
  addi $sp, $sp, -4
  sw   $fp, 0($sp)
  move $fp, $sp
  addi $sp, $sp, -4
  li   $t0, 0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  b    _label_3
_label_4:
  lw   $t0, -4($fp)
  addi $t0, $t0, 1
  sw   $t0, -4($fp)
  lw   $t0, 12($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, 8($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sub  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, 12($fp)
_label_3:
  lw   $t0, 12($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, 8($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sge  $t0, $t1, $t0
  bnez $t0, _label_4
  lw   $t0, -4($fp)
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
  addi $sp, $sp, 4
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
div3:
  addi $sp, $sp, -4
  sw   $ra, 0($sp)
  addi $sp, $sp, -4
  sw   $fp, 0($sp)
  move $fp, $sp
  addi $sp, $sp, -4
  li   $a0, 8
  li   $v0, 9
  syscall
  move $t0, $v0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  li   $t0, 0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -4($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 0($t0)
  b    _label_1
_label_2:
  lw   $t0, -4($fp)
  lw   $t1, 0($t0)
  addi $t1, $t1, 1
  sw   $t1, 0($t0)
  lw   $t0, 12($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, 8($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sub  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, 12($fp)
_label_1:
  lw   $t0, 12($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, 8($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sge  $t0, $t1, $t0
  bnez $t0, _label_2
  lw   $t0, 12($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -4($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 4($t0)
  lw   $t0, -4($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $v0, 0($sp)
  addi $sp, $sp, 4
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
  addi $sp, $sp, 4
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
  addi $sp, $sp, -4
  li   $t0, 45
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 6
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  jal  div1
  addi $sp, $sp, 8
  move $a0, $t0
  li   $v0, 1
  syscall
  la   $t0, _label_0
  move $a0, $t0
  li   $v0, 4
  syscall
  li   $t0, 45
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 6
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  jal  div2
  addi $sp, $sp, 8
  move $a0, $t0
  li   $v0, 1
  syscall
  la   $t0, _label_0
  move $a0, $t0
  li   $v0, 4
  syscall
  li   $t0, 45
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 6
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  jal  div3
  addi $sp, $sp, 8
  move $t0, $v0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  lw   $t0, -4($fp)
  lw   $t0, 0($t0)
  move $a0, $t0
  li   $v0, 1
  syscall
  lw   $t0, -4($fp)
  lw   $t0, 4($t0)
  move $a0, $t0
  li   $v0, 1
  syscall
  la   $t0, _label_0
  move $a0, $t0
  li   $v0, 4
  syscall
  lw   $t0, -4($fp)
  move $a0, $t0
  li   $v0, 1
  syscall
  la   $t0, _label_0
  move $a0, $t0
  li   $v0, 4
  syscall
  addi $sp, $sp, 4
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
.data
_label_0:
  .asciiz "
"
